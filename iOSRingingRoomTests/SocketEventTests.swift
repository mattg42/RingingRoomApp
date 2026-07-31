import Foundation
import XCTest
@testable import Ringing_Room

@MainActor
final class SocketEventTests: XCTestCase {
    func testEverySupportedServerEventHasAValidatedDecoder() throws {
        let payloads: [String: [String: Any]] = [
            "s_user_entered": ["username": "Alice", "user_id": 1],
            "s_user_left": ["username": "Alice", "user_id": 1],
            "s_global_state": ["global_bell_state": [true, false, true, false]],
            "s_set_userlist": ["user_list": [["username": "Alice", "user_id": 1], ["username": "Bob", "user_id": 2]]],
            "s_bell_rung": ["who_rang": 2, "global_bell_state": [true, false, true, false]],
            "s_assign_user": ["bell": 2, "user": 1],
            "s_audio_change": ["new_audio": "Hand"],
            "s_host_mode": ["new_mode": true],
            "s_size_change": ["size": 6],
            "s_msg_sent": ["user": "Alice", "msg": "Hello"],
            "s_call": ["call": "Bob"],
            "s_bad_token": [:],
            "s_wheatley_row_gen": [
                "type": "method", "title": "Plain Bob", "stage": 5,
                "notation": "x5x125", "url": "plain-bob", "bob": [:], "single": [:]
            ],
            "s_wheatley_setting": [
                "sensitivity": 0.5,
                "use_up_down_in": true,
                "stop_at_rounds": false,
                "peal_speed": 180,
                "call_composition": true,
                "fixed_striking_interval": false
            ],
            "s_wheatley_is_ringing": ["is_ringing": true]
        ]

        XCTAssertEqual(Set(ServerSocketEvent.supportedEventNames), Set(payloads.keys))
        for eventName in ServerSocketEvent.supportedEventNames {
            let events = try ServerSocketEvent.decode(eventName: eventName, payload: try XCTUnwrap(payloads[eventName]))
            XCTAssertFalse(events.isEmpty, "Expected decoded events for \(eventName)")
        }
    }

    func testSupportedServerEventsDecodeToExactCasesAndValues() throws {
        let state = [true, false, true].map(BellStroke.init(bool:))

        guard case .userEntered(let entered) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_user_entered", payload: ["username": "Alice", "user_id": 1]).first
        ) else { return XCTFail("Expected user-entered event") }
        XCTAssertEqual(entered, Ringer(name: "Alice", id: 1))

        guard case .userLeft(let left) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_user_left", payload: ["username": "Alice", "user_id": 1]).first
        ) else { return XCTFail("Expected user-left event") }
        XCTAssertEqual(left, Ringer(name: "Alice", id: 1))

        guard case .globalState(let globalState) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_global_state", payload: ["global_bell_state": [true, false, true]]).first
        ) else { return XCTFail("Expected global-state event") }
        XCTAssertEqual(globalState.map(\.boolValue), state.map(\.boolValue))

        guard case .userList(let userList) = try XCTUnwrap(
            ServerSocketEvent.decode(
                eventName: "s_set_userlist",
                payload: ["user_list": [["username": "Alice", "user_id": 1], ["username": "Bob", "user_id": 2]]]
            ).first
        ) else { return XCTFail("Expected user-list event") }
        XCTAssertEqual(userList, [Ringer(name: "Alice", id: 1), Ringer(name: "Bob", id: 2)])

        guard case .bellRung(let number, let bellState) = try XCTUnwrap(
            ServerSocketEvent.decode(
                eventName: "s_bell_rung",
                payload: ["who_rang": 2, "global_bell_state": [true, false, true]]
            ).first
        ) else { return XCTFail("Expected bell-rung event") }
        XCTAssertEqual(number, 2)
        XCTAssertEqual(bellState.map(\.boolValue), state.map(\.boolValue))

        guard case .assigned(let userID, let bell) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_assign_user", payload: ["user": 7, "bell": 4]).first
        ) else { return XCTFail("Expected assignment event") }
        XCTAssertEqual(userID, 7)
        XCTAssertEqual(bell, 4)

        guard case .audioChanged(let audio) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_audio_change", payload: ["new_audio": "Cow"]).first
        ) else { return XCTFail("Expected audio event") }
        XCTAssertEqual(audio, .cowbell)

        guard case .hostModeChanged(let hostMode) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_host_mode", payload: ["new_mode": true]).first
        ) else { return XCTFail("Expected host-mode event") }
        XCTAssertTrue(hostMode)

        guard case .sizeChanged(let size) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_size_change", payload: ["size": 8]).first
        ) else { return XCTFail("Expected size event") }
        XCTAssertEqual(size, 8)

        guard case .message(let message) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_msg_sent", payload: ["user": "Alice", "msg": "Hello"]).first
        ) else { return XCTFail("Expected message event") }
        XCTAssertEqual(message.sender, "Alice")
        XCTAssertEqual(message.message, "Hello")

        guard case .call(let call) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_call", payload: ["call": "Bob"]).first
        ) else { return XCTFail("Expected call event") }
        XCTAssertEqual(call, "Bob")

        guard case .badToken = try XCTUnwrap(ServerSocketEvent.decode(eventName: "s_bad_token", payload: [:]).first) else {
            return XCTFail("Expected bad-token event")
        }

        guard case .rowGeneration(let rowGen) = try XCTUnwrap(
            ServerSocketEvent.decode(
                eventName: "s_wheatley_row_gen",
                payload: [
                    "type": "method", "title": "Plain Bob", "stage": 5,
                    "notation": "x5x125", "url": "plain-bob", "bob": [:], "single": [:]
                ]
            ).first
        ) else { return XCTFail("Expected row-generation event") }
        guard case .method(let method) = rowGen else { return XCTFail("Expected method row generator") }
        XCTAssertEqual(method.title, "Plain Bob")
        XCTAssertEqual(method.stage, 5)
        XCTAssertEqual(method.notation, "x5x125")

        let settingEvents = try ServerSocketEvent.decode(
            eventName: "s_wheatley_setting",
            payload: [
                "sensitivity": 0.5,
                "use_up_down_in": true,
                "stop_at_rounds": false,
                "peal_speed": 180,
                "call_composition": true,
                "fixed_striking_interval": false
            ]
        )
        XCTAssertEqual(settingEvents.count, 6)
        guard case .callComposition(true) = settingEvents[0],
              case .fixedStrikingInterval(false) = settingEvents[1],
              case .pealSpeed(180) = settingEvents[2],
              case .sensitivity(let sensitivity) = settingEvents[3],
              case .stopAtRounds(false) = settingEvents[4],
              case .wholePullAndOff(true) = settingEvents[5] else {
            return XCTFail("Wheatley settings were not decoded in the expected order")
        }
        XCTAssertEqual(sensitivity, 0.5)

        guard case .wheatleyIsRinging(true) = try XCTUnwrap(
            ServerSocketEvent.decode(eventName: "s_wheatley_is_ringing", payload: ["is_ringing": true]).first
        ) else { return XCTFail("Expected Wheatley ringing-state event") }
    }

    func testServerDecoderAppliesDefaultsAndMapsPayloadValues() throws {
        let unassigned = try XCTUnwrap(ServerSocketEvent.decode(eventName: "s_assign_user", payload: ["bell": 3]).first)
        guard case .assigned(let userID, let bell) = unassigned else {
            return XCTFail("Expected an assignment event")
        }
        XCTAssertEqual(userID, 0)
        XCTAssertEqual(bell, 3)

        let globalState = try XCTUnwrap(ServerSocketEvent.decode(eventName: "s_global_state", payload: ["global_bell_state": [true, false]]).first)
        guard case .globalState(let state) = globalState else {
            return XCTFail("Expected a global state event")
        }
        XCTAssertEqual(state.map(\.boolValue), [true, false])

        let settingEvents = try ServerSocketEvent.decode(
            eventName: "s_wheatley_setting",
            payload: ["sensitivity": 2, "peal_speed": 200, "use_up_down_in": false]
        )
        XCTAssertEqual(settingEvents.count, 3)
        XCTAssertTrue(settingEvents.contains { if case .sensitivity(2) = $0 { return true }; return false })
        XCTAssertTrue(settingEvents.contains { if case .pealSpeed(200) = $0 { return true }; return false })
        XCTAssertTrue(settingEvents.contains { if case .wholePullAndOff(false) = $0 { return true }; return false })
    }

    func testMalformedServerEventsAreRejected() {
        XCTAssertThrowsError(try ServerSocketEvent.decode(eventName: "s_unknown", payload: [:])) { error in
            guard case ServerSocketEvent.DecodeError.unknownEvent("s_unknown") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertThrowsError(try ServerSocketEvent.decode(eventName: "s_size_change", payload: [:]))
        XCTAssertThrowsError(try ServerSocketEvent.decode(eventName: "s_audio_change", payload: ["new_audio": "Not a bell"]))
        XCTAssertThrowsError(try ServerSocketEvent.decode(eventName: "s_wheatley_setting", payload: ["unknown": true]))
    }

    func testMalformedPayloadsProduceExactDecodeErrorsAndDescriptions() {
        let cases: [(Result<[ServerSocketEvent], Error>, ServerSocketEvent.DecodeError, String)] = [
            (
                Result { try ServerSocketEvent.decode(eventName: "s_size_change", payload: [:]) },
                .missingValue(event: "s_size_change", key: "size"),
                "Event s_size_change is missing size."
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_host_mode", payload: ["new_mode": "yes"]) },
                .invalidValue(event: "s_host_mode", key: "new_mode"),
                "Event s_host_mode contains an invalid new_mode."
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_audio_change", payload: ["new_audio": "Not a bell"]) },
                .invalidAudio("Not a bell"),
                "Unable to convert Not a bell to an audio type."
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_unknown", payload: [:]) },
                .unknownEvent("s_unknown"),
                "Unknown server socket event: s_unknown"
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_user_entered", payload: ["username": "Alice"]) },
                .missingValue(event: "s_user_entered", key: "user_id"),
                "Event s_user_entered is missing user_id."
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_set_userlist", payload: ["user_list": [["user_id": "bad"]]]) },
                .invalidValue(event: "s_set_userlist", key: "user_id"),
                "Event s_set_userlist contains an invalid user_id."
            ),
            (
                Result { try ServerSocketEvent.decode(eventName: "s_wheatley_row_gen", payload: ["type": "unknown"]) },
                .invalidValue(event: "s_wheatley_row_gen", key: "row_generation"),
                "Event s_wheatley_row_gen contains an invalid row_generation."
            )
        ]

        for (result, expected, description) in cases {
            guard case .failure(let error) = result else {
                return XCTFail("Expected a decoding failure")
            }
            guard let decodeError = error as? ServerSocketEvent.DecodeError else {
                return XCTFail("Expected DecodeError, got \(error)")
            }
            switch (decodeError, expected) {
            case (.unknownEvent(let actual), .unknownEvent(let expected)):
                XCTAssertEqual(actual, expected)
            case (.missingValue(let actualEvent, let actualKey), .missingValue(let expectedEvent, let expectedKey)):
                XCTAssertEqual(actualEvent, expectedEvent)
                XCTAssertEqual(actualKey, expectedKey)
            case (.invalidValue(let actualEvent, let actualKey), .invalidValue(let expectedEvent, let expectedKey)):
                XCTAssertEqual(actualEvent, expectedEvent)
                XCTAssertEqual(actualKey, expectedKey)
            case (.invalidAudio(let actual), .invalidAudio(let expected)):
                XCTAssertEqual(actual, expected)
            default:
                XCTFail("Unexpected error pair: \(decodeError), \(expected)")
            }
            XCTAssertEqual(decodeError.errorDescription, description)
        }
    }

    func testEachWheatleySettingDecodesIndependently() throws {
        let cases: [(String, Any, (ServerSocketEvent) -> Bool)] = [
            ("sensitivity", 0.25, { if case .sensitivity(0.25) = $0 { return true }; return false }),
            ("use_up_down_in", true, { if case .wholePullAndOff(true) = $0 { return true }; return false }),
            ("stop_at_rounds", false, { if case .stopAtRounds(false) = $0 { return true }; return false }),
            ("peal_speed", 200, { if case .pealSpeed(200) = $0 { return true }; return false }),
            ("call_composition", true, { if case .callComposition(true) = $0 { return true }; return false }),
            ("fixed_striking_interval", false, { if case .fixedStrikingInterval(false) = $0 { return true }; return false })
        ]

        for (key, value, matches) in cases {
            let events = try ServerSocketEvent.decode(eventName: "s_wheatley_setting", payload: [key: value])
            XCTAssertEqual(events.count, 1, "Expected one event for \(key)")
            XCTAssertTrue(matches(try XCTUnwrap(events.first)), "Unexpected event for \(key)")
        }
    }

    func testDeliverForwardsEverySupportedEventToTheDelegate() throws {
        let rowGen = try RowGen(dictionary: [
            "type": "composition", "title": "Composition", "url": "https://example.com/composition"
        ])
        let events: [ServerSocketEvent] = [
            .userEntered(Ringer(name: "Alice", id: 1)),
            .userLeft(Ringer(name: "Bob", id: 2)),
            .globalState([.hand, .back]),
            .userList([Ringer(name: "Alice", id: 1)]),
            .bellRung(number: 3, globalState: [.back, .hand]),
            .assigned(userID: 2, bell: 3),
            .audioChanged(.hand),
            .hostModeChanged(true),
            .sizeChanged(6),
            .message(Message(sender: "Alice", message: "Hello")),
            .call("Bob"),
            .badToken,
            .rowGeneration(rowGen),
            .sensitivity(0.4),
            .wholePullAndOff(true),
            .stopAtRounds(false),
            .pealSpeed(180),
            .callComposition(true),
            .fixedStrikingInterval(false),
            .wheatleyIsRinging(true)
        ]
        let delegate = SocketDelegateSpy()

        for event in events {
            event.deliver(to: delegate)
        }

        XCTAssertEqual(delegate.calls, [
            "userDidEnter", "userDidLeave", "globalState", "userList", "bellDidRing", "assigned",
            "audioChanged", "hostModeChanged", "sizeChanged", "message", "call", "badToken", "rowGeneration",
            "wholePullAndOff", "stopAtRounds", "pealSpeed", "callComposition", "fixedStrikingInterval", "wheatleyIsRinging"
        ])
        XCTAssertEqual(delegate.entered, Ringer(name: "Alice", id: 1))
        XCTAssertEqual(delegate.left, Ringer(name: "Bob", id: 2))
        XCTAssertEqual(delegate.globalState?.map(\.boolValue), [true, false])
        XCTAssertEqual(delegate.userList, [Ringer(name: "Alice", id: 1)])
        XCTAssertEqual(delegate.bellNumber, 3)
        XCTAssertEqual(delegate.bellState?.map(\.boolValue), [false, true])
        XCTAssertEqual(delegate.assigned?.0, 2)
        XCTAssertEqual(delegate.assigned?.1, 3)
        XCTAssertEqual(delegate.audio, .hand)
        XCTAssertTrue(delegate.hostMode ?? false)
        XCTAssertEqual(delegate.size, 6)
        XCTAssertEqual(delegate.message?.sender, "Alice")
        XCTAssertEqual(delegate.message?.message, "Hello")
        XCTAssertEqual(delegate.call, "Bob")
        XCTAssertTrue(delegate.badToken)
        guard case .comp(let composition) = try XCTUnwrap(delegate.rowGen) else {
            return XCTFail("Expected composition row generator")
        }
        XCTAssertEqual(composition.title, "Composition")
        XCTAssertTrue(delegate.wholePullAndOff ?? false)
        XCTAssertFalse(delegate.stopAtRounds ?? true)
        XCTAssertEqual(delegate.pealSpeed, 180)
        XCTAssertTrue(delegate.callComposition ?? false)
        XCTAssertFalse(delegate.fixedStrikingInterval ?? true)
        XCTAssertTrue(delegate.wheatleyIsRinging ?? false)
    }

    func testClientEventNamesAndWheatleySettingsRemainStable() {
        XCTAssertEqual(ClientSocketEvent.join.eventName, "c_join")
        XCTAssertEqual(ClientSocketEvent.leaveTower.eventName, "c_user_left")
        XCTAssertEqual(ClientSocketEvent.requestGlobalState.eventName, "c_request_global_state")
        XCTAssertEqual(ClientSocketEvent.bellRung(bell: 1, stroke: true).eventName, "c_bell_rung")
        XCTAssertEqual(ClientSocketEvent.assignUser(bell: 1, user: 2).eventName, "c_assign_user")
        XCTAssertEqual(ClientSocketEvent.unassignBell(bell: 1).eventName, "c_assign_user")
        XCTAssertEqual(ClientSocketEvent.audioChange(to: .cowbell).eventName, "c_audio_change")
        XCTAssertEqual(ClientSocketEvent.hostModeSet(to: true).eventName, "c_host_mode")
        XCTAssertEqual(ClientSocketEvent.sizeChange(to: 6).eventName, "c_size_change")
        XCTAssertEqual(ClientSocketEvent.messageSent(message: "Hi", time: "now").eventName, "c_msg_sent")
        XCTAssertEqual(ClientSocketEvent.call("Bob").eventName, "c_call")
        XCTAssertEqual(ClientSocketEvent.setBells.eventName, "c_set_bells")
        XCTAssertEqual(ClientSocketEvent.setWheatleySetting(setting: .pealSpeed(180)).eventName, "c_wheatley_setting")
        XCTAssertEqual(ClientSocketEvent.setWheatleyRowGen(rowGen: [:]).eventName, "c_wheatley_row_gen")
        XCTAssertEqual(ClientSocketEvent.wheatleyStopTouch.eventName, "c_wheatley_stop_touch")
        XCTAssertEqual(ClientSocketEvent.resetWheatley.eventName, "c_reset_wheatley")

        XCTAssertEqual(WheatleySetting.sensitivity(0.5).json["sensitivity"] as? Double, 0.5)
        XCTAssertEqual(WheatleySetting.useUpDownIn(true).json["use_up_down_in"] as? Bool, true)
        XCTAssertEqual(WheatleySetting.stopAtRounds(false).json["stop_at_rounds"] as? Bool, false)
        XCTAssertEqual(WheatleySetting.pealSpeed(180).json["peal_speed"] as? Int, 180)
        XCTAssertEqual(WheatleySetting.callComposition(true).json["call_composition"] as? Bool, true)
        XCTAssertEqual(WheatleySetting.fixedStrikingInterval(false).json["fixed_striking_interval"] as? Bool, false)
    }
}

@MainActor
private final class SocketDelegateSpy: SocketIODelegate {
    var calls = [String]()
    var entered: Ringer?
    var left: Ringer?
    var globalState: [BellStroke]?
    var userList: [Ringer]?
    var bellNumber: Int?
    var bellState: [BellStroke]?
    var assigned: (Int, Int)?
    var audio: BellType?
    var hostMode: Bool?
    var size: Int?
    var message: Message?
    var call: String?
    var badToken = false
    var rowGen: RowGen?
    var wholePullAndOff: Bool?
    var stopAtRounds: Bool?
    var pealSpeed: Int?
    var callComposition: Bool?
    var fixedStrikingInterval: Bool?
    var wheatleyIsRinging: Bool?

    func socketDidConnect() { calls.append("socketDidConnect") }
    func socketWillReconnect() { calls.append("socketWillReconnect") }
    func socketDidDisconnect(reason: String) { calls.append("socketDidDisconnect") }
    func socketDidFail(message: String) { calls.append("socketDidFail") }
    func sizeDidChange(to newSize: Int) { calls.append("sizeChanged"); size = newSize }
    func userDidEnter(_ ringer: Ringer) { calls.append("userDidEnter"); entered = ringer }
    func userDidLeave(_ ringer: Ringer) { calls.append("userDidLeave"); left = ringer }
    func didReceiveGlobalState(_ globalState: [BellStroke]) { calls.append("globalState"); self.globalState = globalState }
    func didReceiveUserList(_ userList: [Ringer]) { calls.append("userList"); self.userList = userList }
    func bellDidRing(number: Int, globalState: [BellStroke]) { calls.append("bellDidRing"); bellNumber = number; bellState = globalState }
    func didAssign(ringerID: Int, to bell: Int) { calls.append("assigned"); assigned = (ringerID, bell) }
    func audioDidChange(to bellType: BellType) { calls.append("audioChanged"); audio = bellType }
    func hostModeDidChange(to newMode: Bool) { calls.append("hostModeChanged"); hostMode = newMode }
    func didReceiveMessage(_ message: Message) { calls.append("message"); self.message = message }
    func didReceiveCall(_ call: String) { calls.append("call"); self.call = call }
    func rowGenDidChange(to rowGen: RowGen) { calls.append("rowGeneration"); self.rowGen = rowGen }
    func didReceiveBadToken() { calls.append("badToken"); badToken = true }
    func pealSpeedDidChange(to speed: Int) { calls.append("pealSpeed"); pealSpeed = speed }
    func fixedStrikingIntervalDidChange(to newValue: Bool) { calls.append("fixedStrikingInterval"); fixedStrikingInterval = newValue }
    func wholePullAndOffDidChange(to newValue: Bool) { calls.append("wholePullAndOff"); wholePullAndOff = newValue }
    func stopAtRoundsDidChange(to newValue: Bool) { calls.append("stopAtRounds"); stopAtRounds = newValue }
    func callCompositionDidChange(to newValue: Bool) { calls.append("callComposition"); callComposition = newValue }
    func wheatleyStateDidChange(to newValue: Bool) { calls.append("wheatleyIsRinging"); wheatleyIsRinging = newValue }
}
