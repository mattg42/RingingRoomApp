//
//  Tower.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct Tower: Identifiable {
    enum ConversionError: LocalizedError {
        case invalidIdentifier(String)
        case invalidVisitedDate(String)

        var errorDescription: String? {
            switch self {
            case .invalidIdentifier(let value):
                "Invalid tower identifier: \(value)"
            case .invalidVisitedDate(let value):
                "Invalid tower visit date: \(value)"
            }
        }
    }

    init(bookmark: Bool, creator: Bool, host: Bool, recent: Bool, towerID: Int, towerName: String, visited: Date) {
        self.bookmark = bookmark
        self.creator = creator
        self.host = host
        self.recent = recent
        self.towerID = towerID
        self.towerName = towerName
        self.visited = visited
    }
    
    var bookmark: Bool
    var creator: Bool
    var host: Bool
    var recent: Bool
    var towerID: Int
    var towerName: String
    var visited: Date
    
    init(towerModel: APIModel.Tower) throws {
        guard let towerID = Int(towerModel.tower_id) else {
            throw ConversionError.invalidIdentifier(towerModel.tower_id)
        }

        guard let visited = Self.date(from: towerModel.visited) else {
            throw ConversionError.invalidVisitedDate(towerModel.visited)
        }

        bookmark = Bool(towerModel.bookmark)
        creator = Bool(towerModel.creator)
        host = Bool(towerModel.host)
        recent = Bool(towerModel.recent)
        self.towerID = towerID
        towerName = towerModel.tower_name
        self.visited = visited
    }
    
    static var blank: Tower {
        Tower(bookmark: false, creator: false, host: false, recent: true, towerID: Int.random(in: 0...Int.max), towerName: "Blank", visited: .now)
    }
    
    var id: Int { towerID }

    private static func date(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in ["EEE, dd MMM yyyy HH:mm:ss zzz", "EEE, dd MMM yyyy HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
}
