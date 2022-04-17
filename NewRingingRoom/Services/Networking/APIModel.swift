//
//  APIModelmmmm1.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

enum APIModel {
    struct Login: Decodable {
        let token: String
    }
    
    struct Tower: Decodable {
        var bookmark: Int
        var creator: Int
        var host: Int
        var recent: Int
        var tower_id: String
        var tower_name: String
        var visited: String
    }
    
    struct TowerInfo: Decodable {
        var tower_id: String
        var tower_name: String
        var server_address: String
        var additional_sizes_enabled: Bool
        var host_mode_permitted: Bool
        var half_muffled: Bool
    }
    
    struct User: Decodable {
        var username: String
        var email: String
    }
}
