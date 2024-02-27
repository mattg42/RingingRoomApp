//
//  APIModel.swift
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
    
    struct TowerDetails: Decodable {
        init(tower_id: Int, tower_name: String, server_address: String, additional_sizes_enabled: Bool, host_mode_permitted: Bool, half_muffled: Bool, fully_muffled: Bool) {
            self.tower_id = tower_id
            self.tower_name = tower_name
            self.server_address = server_address
            self.additional_sizes_enabled = additional_sizes_enabled
            self.host_mode_permitted = host_mode_permitted
            self.half_muffled = half_muffled
            self.fully_muffled = fully_muffled
        }
        
        var tower_id: Int
        var tower_name: String
        var server_address: String
        var additional_sizes_enabled: Bool
        var host_mode_permitted: Bool
        var half_muffled: Bool
        var fully_muffled: Bool
        
        enum CodingKeys: CodingKey {
            case tower_id
            case tower_name
            case server_address
            case additional_sizes_enabled
            case host_mode_permitted
            case half_muffled
            case fully_muffled
        }
        
        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<APIModel.TowerDetails.CodingKeys> = try decoder.container(keyedBy: APIModel.TowerDetails.CodingKeys.self)
            self.tower_id = try container.decode(Int.self, forKey: APIModel.TowerDetails.CodingKeys.tower_id)
            self.tower_name = try container.decode(String.self, forKey: APIModel.TowerDetails.CodingKeys.tower_name)
            self.server_address = try container.decode(String.self, forKey: APIModel.TowerDetails.CodingKeys.server_address)
            
            self.additional_sizes_enabled = try container.decode((Bool?).self, forKey: APIModel.TowerDetails.CodingKeys.additional_sizes_enabled) ?? false
            self.host_mode_permitted = try container.decode((Bool?).self, forKey: APIModel.TowerDetails.CodingKeys.host_mode_permitted) ?? false
            self.half_muffled = try container.decode((Bool?).self, forKey: APIModel.TowerDetails.CodingKeys.half_muffled) ?? false
            self.fully_muffled = try container.decode((Bool?).self, forKey: APIModel.TowerDetails.CodingKeys.fully_muffled) ?? false
        }
    }
    
    struct TowerCreationDetails: Decodable {
        var tower_id: Int
        var server_address: String
    }
    
    struct User: Decodable {
        var username: String
        var email: String
    }
}
