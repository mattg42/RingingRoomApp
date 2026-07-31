//
//  Ringer.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation

struct Ringer: Identifiable, Codable, Equatable, Sendable {
    var id: Int { ringerID }
    
    var name: String
    var ringerID: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.ringerID = id
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "username"
        case ringerID = "user_id"
    }
    
    init(socketPayload: [String: Any]) throws {
        AppLogger.socket.debug("Parsing ringer payload")

        guard JSONSerialization.isValidJSONObject(socketPayload) else {
            throw RingerPayloadError.invalidJSON
        }

        let data = try JSONSerialization.data(withJSONObject: socketPayload)
        let payload = try JSONDecoder().decode(SocketPayload.self, from: data)

        if payload.ringerID == -1 {
            self = .wheatley
        } else {
            self = Ringer(name: payload.name ?? "Username not found", id: payload.ringerID)
        }
    }
    
    static let wheatley = Ringer(name: "Wheatley", id: -1)

    private struct SocketPayload: Decodable {
        let name: String?
        let ringerID: Int

        enum CodingKeys: String, CodingKey {
            case name = "username"
            case ringerID = "user_id"
        }
    }
}

private enum RingerPayloadError: LocalizedError {
    case invalidJSON

    var errorDescription: String? {
        "Ringer payload is not a valid JSON object."
    }
}

extension Array where Element == Ringer? {
    func allIndicesOfRinger(_ ringer: Ringer) -> [Int] {
        var output = [Int]()
        
        if contains(ringer) {
            for (index, element) in self.enumerated() {
                if element == ringer {
                    output.append(index)
                }
            }
            return output
        } else {
            return [Int]()
        }
    }
}

extension Array where Element == Ringer {
    mutating func remove(_ ringer: Ringer) {
        for (index, element) in self.enumerated() {
            if element == ringer {
                self.remove(at: index)
                return
            }
        }
    }
    
    mutating func sortAlphabetically() {
        self.sort { (first, second) -> Bool in
            first.name.lowercased() < second.name.lowercased()
        }
    }
}
