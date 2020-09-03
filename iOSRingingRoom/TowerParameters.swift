//
//  TowerParameters.swift
//  iOSRingingRoom
//
//  Created by Matthew on 12/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//



import Foundation

class TowerParameters: Codable {
    
    var host_mode_permitted:Bool! = nil
    var cur_user_name:String! = nil
    var bookmarked:Bool! = nil
    var host_mode:Bool! = nil
    var audio:String! = nil
    var server_ip:String! = nil
    var id:Int! = nil
    var listen_link:Bool! = nil
    var assignments:[String]! = nil
    var observers:Int! = nil
    var anonymous_user:Bool! = nil
    var cur_user_email:String! = nil
    var name:String! = nil
    var size:Int! = nil
    var host_permissions:Bool! = nil
    var user_token:String! = nil
}

extension Bool: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = value != 0
    }
}
