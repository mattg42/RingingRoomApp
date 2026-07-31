import Foundation

/// The wire-format boundary for server-originated socket messages.
///
/// Keeping payload validation here makes malformed events testable without a
/// live Socket.IO server and keeps the transport adapter responsible only for
/// registration and delivery.
enum ServerSocketEvent: Sendable {
    enum DecodeError: LocalizedError {
        case unknownEvent(String)
        case missingValue(event: String, key: String)
        case invalidValue(event: String, key: String)
        case invalidAudio(String)

        var errorDescription: String? {
            switch self {
            case .unknownEvent(let event):
                return "Unknown server socket event: \(event)"
            case .missingValue(let event, let key):
                return "Event \(event) is missing \(key)."
            case .invalidValue(let event, let key):
                return "Event \(event) contains an invalid \(key)."
            case .invalidAudio(let value):
                return "Unable to convert \(value) to an audio type."
            }
        }
    }

    case userEntered(Ringer)
    case userLeft(Ringer)
    case globalState([BellStroke])
    case userList([Ringer])
    case bellRung(number: Int, globalState: [BellStroke])
    case assigned(userID: Int, bell: Int)
    case audioChanged(BellType)
    case hostModeChanged(Bool)
    case sizeChanged(Int)
    case message(Message)
    case call(String)
    case badToken
    case rowGeneration(RowGen)
    case sensitivity(Double)
    case wholePullAndOff(Bool)
    case stopAtRounds(Bool)
    case pealSpeed(Int)
    case callComposition(Bool)
    case fixedStrikingInterval(Bool)
    case wheatleyIsRinging(Bool)

    static let supportedEventNames = [
        "s_user_entered",
        "s_user_left",
        "s_global_state",
        "s_set_userlist",
        "s_bell_rung",
        "s_assign_user",
        "s_audio_change",
        "s_host_mode",
        "s_size_change",
        "s_msg_sent",
        "s_call",
        "s_bad_token",
        "s_wheatley_row_gen",
        "s_wheatley_setting",
        "s_wheatley_is_ringing"
    ]

    static func decode(eventName: String, payload: [String: Any]) throws -> [Self] {
        switch eventName {
        case "s_user_entered":
            return [.userEntered(try ringer(from: payload, eventName: eventName))]
        case "s_user_left":
            return [.userLeft(try ringer(from: payload, eventName: eventName))]
        case "s_global_state":
            return [.globalState(try bellStates(from: payload, eventName: eventName, key: "global_bell_state"))]
        case "s_set_userlist":
            let payloads = try value([[String: Any]].self, key: "user_list", eventName: eventName, from: payload)
            let users = try payloads.map { try ringer(from: $0, eventName: eventName) }
            return [.userList(users)]
        case "s_bell_rung":
            return [
                .bellRung(
                    number: try value(Int.self, key: "who_rang", eventName: eventName, from: payload),
                    globalState: try bellStates(from: payload, eventName: eventName, key: "global_bell_state")
                )
            ]
        case "s_assign_user":
            return [
                .assigned(
                    userID: (try? value(Int.self, key: "user", eventName: eventName, from: payload)) ?? 0,
                    bell: try value(Int.self, key: "bell", eventName: eventName, from: payload)
                )
            ]
        case "s_audio_change":
            let value = try value(String.self, key: "new_audio", eventName: eventName, from: payload)
            guard let bellType = BellType(rawValue: value) else {
                throw DecodeError.invalidAudio(value)
            }
            return [.audioChanged(bellType)]
        case "s_host_mode":
            return [.hostModeChanged(try value(Bool.self, key: "new_mode", eventName: eventName, from: payload))]
        case "s_size_change":
            return [.sizeChanged(try value(Int.self, key: "size", eventName: eventName, from: payload))]
        case "s_msg_sent":
            return [
                .message(
                    Message(
                        sender: try value(String.self, key: "user", eventName: eventName, from: payload),
                        message: try value(String.self, key: "msg", eventName: eventName, from: payload)
                    )
                )
            ]
        case "s_call":
            return [.call(try value(String.self, key: "call", eventName: eventName, from: payload))]
        case "s_bad_token":
            return [.badToken]
        case "s_wheatley_row_gen":
            do {
                return [.rowGeneration(try RowGen(dictionary: payload))]
            } catch {
                throw DecodeError.invalidValue(event: eventName, key: "row_generation")
            }
        case "s_wheatley_setting":
            return try payload.keys.sorted().map { key in
                switch key {
                case "sensitivity":
                    if let double = payload[key] as? Double {
                        return .sensitivity(double)
                    }
                    if let integer = payload[key] as? Int {
                        return .sensitivity(Double(integer))
                    }
                    throw DecodeError.invalidValue(event: eventName, key: key)
                case "use_up_down_in":
                    return .wholePullAndOff(try value(Bool.self, key: key, eventName: eventName, from: payload))
                case "stop_at_rounds":
                    return .stopAtRounds(try value(Bool.self, key: key, eventName: eventName, from: payload))
                case "peal_speed":
                    return .pealSpeed(try value(Int.self, key: key, eventName: eventName, from: payload))
                case "call_composition":
                    return .callComposition(try value(Bool.self, key: key, eventName: eventName, from: payload))
                case "fixed_striking_interval":
                    return .fixedStrikingInterval(try value(Bool.self, key: key, eventName: eventName, from: payload))
                default:
                    throw DecodeError.invalidValue(event: eventName, key: key)
                }
            }
        case "s_wheatley_is_ringing":
            return [.wheatleyIsRinging(try value(Bool.self, key: "is_ringing", eventName: eventName, from: payload))]
        default:
            throw DecodeError.unknownEvent(eventName)
        }
    }

    @MainActor
    func deliver(to delegate: any SocketIODelegate) {
        switch self {
        case .userEntered(let ringer): delegate.userDidEnter(ringer)
        case .userLeft(let ringer): delegate.userDidLeave(ringer)
        case .globalState(let state): delegate.didReceiveGlobalState(state)
        case .userList(let users): delegate.didReceiveUserList(users)
        case .bellRung(let number, let state): delegate.bellDidRing(number: number, globalState: state)
        case .assigned(let userID, let bell): delegate.didAssign(ringerID: userID, to: bell)
        case .audioChanged(let bellType): delegate.audioDidChange(to: bellType)
        case .hostModeChanged(let newMode): delegate.hostModeDidChange(to: newMode)
        case .sizeChanged(let newSize): delegate.sizeDidChange(to: newSize)
        case .message(let message): delegate.didReceiveMessage(message)
        case .call(let call): delegate.didReceiveCall(call)
        case .badToken: delegate.didReceiveBadToken()
        case .rowGeneration(let rowGen): delegate.rowGenDidChange(to: rowGen)
        case .sensitivity: break
        case .wholePullAndOff(let value): delegate.wholePullAndOffDidChange(to: value)
        case .stopAtRounds(let value): delegate.stopAtRoundsDidChange(to: value)
        case .pealSpeed(let value): delegate.pealSpeedDidChange(to: value)
        case .callComposition(let value): delegate.callCompositionDidChange(to: value)
        case .fixedStrikingInterval(let value): delegate.fixedStrikingIntervalDidChange(to: value)
        case .wheatleyIsRinging(let value): delegate.wheatleyStateDidChange(to: value)
        }
    }

    private static func value<T>(_ type: T.Type, key: String, eventName: String, from payload: [String: Any]) throws -> T {
        guard let value = payload[key] else {
            throw DecodeError.missingValue(event: eventName, key: key)
        }
        guard let value = value as? T else {
            throw DecodeError.invalidValue(event: eventName, key: key)
        }
        return value
    }

    private static func bellStates(from payload: [String: Any], eventName: String, key: String) throws -> [BellStroke] {
        try value([Bool].self, key: key, eventName: eventName, from: payload).map(BellStroke.init(bool:))
    }

    private static func ringer(from payload: [String: Any], eventName: String) throws -> Ringer {
        guard payload["user_id"] != nil else {
            throw DecodeError.missingValue(event: eventName, key: "user_id")
        }

        do {
            return try Ringer(socketPayload: payload)
        } catch {
            throw DecodeError.invalidValue(event: eventName, key: "user_id")
        }
    }
}
