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
    var visited:Date
    var creator:Bool
    var bookmark:Bool
    
    init(id:Int, name:String, host:Int, recent:Int, visited:String, creator:Int, bookmark:Int) {
        var date = Date()
        if visited != "" {
            print(name, host)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, dd MMM y hh:mm:ss a"
            
            var lastVisited = ""
            
            lastVisited = String(visited[visited.startIndex..<visited.index(visited.endIndex, offsetBy: -4)])
            
            
            var temp1Array = lastVisited.split(separator: ":")
            var temp2Array = String(temp1Array[0]).split(separator: " ")
            let tempStr = temp2Array[temp2Array.count-1]
            var hours = Int(tempStr)!
            if hours > 12 {
                hours -= 12
                temp2Array[temp2Array.count - 1] = Substring(String(hours))
                temp1Array[0] = Substring(temp2Array.joined(separator: " "))
                lastVisited = temp1Array.joined(separator: ":")
                lastVisited.append(" pm")
            } else {
                lastVisited.append(" am")
            }
            date = dateFormatter.date(from: lastVisited) ?? Date()
        }
        
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
        self.visited = date
        self.bookmark = Bool(integerLiteral: bookmark)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tower_id)
    }
}

extension Array where Element==Tower {
    func towerForID(_ id:Int) -> Tower? {
        for tower in self {
            if tower.tower_id == id {
                return tower
            }
        }
        return nil
    }
}

extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex...endIndex])
    }
}
