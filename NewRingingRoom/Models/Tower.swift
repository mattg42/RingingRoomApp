//
//  Tower.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct Tower {
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
}

func convertToDate(_ str: String) -> Date {
    let dateFormatter = DateFormatter()
    print(str)
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
    return dateFormatter.date(from: str)!
}
