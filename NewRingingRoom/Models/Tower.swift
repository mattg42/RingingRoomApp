//
//  Tower.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct Tower: Identifiable {
    init(bookmark: Bool, creator: Bool, host: Bool, recent: Bool, towerId: Int, towerName: String, visited: Date) {
        self.bookmark = bookmark
        self.creator = creator
        self.host = host
        self.recent = recent
        self.towerId = towerId
        self.towerName = towerName
        self.visited = visited
    }
    
    var bookmark: Bool
    var creator: Bool
    var host: Bool
    var recent: Bool
    var towerId: Int
    var towerName: String
    var visited: Date
    
    init(towerModel: APIModel.Tower) {
        bookmark = Bool(towerModel.bookmark)
        creator = Bool(towerModel.creator)
        host = Bool(towerModel.host)
        recent = Bool(towerModel.recent)
        towerId = Int(towerModel.tower_id)!
        towerName = towerModel.tower_name
        
        visited = convertToDate(String(towerModel.visited[...towerModel.visited.index(before: towerModel.visited.lastIndex(of: " ")!)]))
    }
    
    static var blank: Tower {
        Tower(bookmark: false, creator: false, host: false, recent: true, towerId: Int.random(in: 0...Int.max), towerName: "Blank", visited: .now)
    }
    
    var id: Int { towerId }
}

fileprivate func convertToDate(_ str: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
    return dateFormatter.date(from: str)!
}
