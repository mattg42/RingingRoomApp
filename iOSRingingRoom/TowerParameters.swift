//
//  TowerParameters.swift
//  iOSRingingRoom
//
//  Created by Matthew on 12/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

enum Stroke:Bool {
    case handstoke = true, backstroke = false
    
    mutating func toggle() {
        switch self {
            case .handstoke:
                self = .backstroke
            case .backstroke:
                self = .handstoke
        }
    }
}

import Foundation

class TowerParameters: Codable {
    
    var host_mode_permitted:Bool!
    var cur_user_name:String!
    var bookmarked:Bool!
    var host_mode:Bool!
    var audio:String!
    var server_ip:String!
    var id:Int!
    var listen_link:Bool!
    var assignments:[String]!
    var observers:Int!
    var anonymous_user:Bool!
    var cur_user_email:String!
    var name:String!
    var size:Int
    var host_permissions:Bool!
    var user_token:String!
}

extension Bool: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = value != 0
    }
}
