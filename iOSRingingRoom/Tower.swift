//
//  Tower.swift
//  iOSRingingRoom
//
//  Created by Matthew on 11/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class Tower:Identifiable, Hashable {
    static func == (lhs: Tower, rhs: Tower) -> Bool {
        return lhs.tower_id == rhs.tower_id
    }
    
    var id = UUID()
    
    var tower_id:Int
    var tower_name:String
    var host:Bool
    var recent:Bool
    var visited:String
    var creator:Bool
    var bookmark:Bool
    
    init(id:Int, name:String, host:Int, recent:Int, visited:String, creator:Int, bookmark:Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, dd MMM y HH:mm:ss"
        
        var lastVisited = ""
        
        if visited != "" {
            lastVisited = String(visited[visited.startIndex..<visited.index(visited.endIndex, offsetBy: -4)])
        }
        
        print(lastVisited)
//        let date = dateFormatter.date(from: lastVisited)
        
        self.tower_id = id
        self.tower_name = name
        self.host = Bool(integerLiteral: host)
        self.recent = Bool(integerLiteral: recent)
        self.creator = Bool(integerLiteral: creator)
//        if visited == "" {
//            self.visited = Date()
//        } else {
//            self.visited = date!
//        }
        self.visited = visited
        self.bookmark = Bool(integerLiteral: bookmark)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tower_id)
    }
}
