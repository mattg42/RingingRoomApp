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
        var date = ""
        if visited != "" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy hh:mm:ss a"
            
            var lastVisited = ""
            
            lastVisited = String(visited[visited.index(visited.startIndex, offsetBy: 5)..<visited.index(visited.endIndex, offsetBy: -4)])
            
            let visitedComponents = VisitedComponents()
            let stringComponents = lastVisited.split(separator: " ")
            visitedComponents.day = String(stringComponents[0])
            
            switch stringComponents[1] {
            case "Jan":
                visitedComponents.month = "01"
            case "Feb":
                visitedComponents.month = "02"
            case "Mar":
                visitedComponents.month = "03"
            case "Apr":
                visitedComponents.month = "04"
            case "May":
                visitedComponents.month = "05"
            case "Jun":
                visitedComponents.month = "06"
            case "Jul":
                visitedComponents.month = "07"
            case "Aug":
                visitedComponents.month = "08"
            case "Sep":
                visitedComponents.month = "09"
            case "Oct":
                visitedComponents.month = "10"
            case "Nov":
                visitedComponents.month = "11"
            case "Dec":
                visitedComponents.month = "12"
            default:
                print("Month not parsed")
                visitedComponents.month = "01"
            }
            
            visitedComponents.year = String(stringComponents[2])

            visitedComponents.hour = String(String(stringComponents[3]).split(separator: ":")[0])
            if visitedComponents.hour.count < 2 {
                visitedComponents.hour.prefix("0")
            }
            visitedComponents.minute = String(String(stringComponents[3]).split(separator: ":")[1])
            visitedComponents.second = String(String(stringComponents[3]).split(separator: ":")[2])
            
//            var temp1Array = lastVisited.split(separator: ":")
//            var temp2Array = String(temp1Array[0]).split(separator: " ")
//            let tempStr = temp2Array[temp2Array.count-1]
//            var hours = Int(tempStr)!
//            if hours > 12 {
//                hours -= 12
//                temp2Array[temp2Array.count - 1] = Substring(String(hours))
//                temp1Array[0] = Substring(temp2Array.joined(separator: " "))
//                lastVisited = temp1Array.joined(separator: ":")
//                lastVisited.append(" pm")
//            } else {
//                lastVisited.append(" am")
//            }
            print(lastVisited)
            date = visitedComponents.combine()
            print(date)
        }
        
        self.tower_id = id
        self.tower_name = name
        self.host = Bool(host)
        self.recent = Bool(recent)
        self.creator = Bool(creator)
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
    
    var names:[String] {
        get {
            var arr = [String]()
            for tower in self {
                arr.append(tower.tower_name)
            }
            return arr
        }
    }
    
//    var dates:[Date] {
//        get {
//            var visiteds = [Date]()
//            for tower in self {
//                visiteds.append(tower.visited)
//            }
//            return visiteds
//        }
//    }
}

extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex...endIndex])
    }
}

class VisitedComponents {
    var year:String!
    var month:String!
    var day:String!
    var hour:String!
    var minute:String!
    var second:String!
    
    func combine() -> String {
        var output = year!
        output += month!
        output += day!
        output += hour!
        output += minute!
        output += second!
        return output
    }
}

extension Bool {
    init(_ num: Int) {
        self.init(num != 0)
    }
}
