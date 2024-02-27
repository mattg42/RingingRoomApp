//
//  Region.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

enum Region: CaseIterable, Comparable, Identifiable {
    var id: Self { self }
    
    case uk, na, sg, anzab
}

extension Region {
    var displayName: String {
        switch self {
        case .uk:
            return "UK"
        case .na:
            return "North America"
        case .sg:
            return "Singapore"
        case .anzab:
            return "ANZAB"
        }
    }
    
    var server: String {
        switch self {
        case .uk:
            return ""
        case .na:
            return "na."
        case .sg:
            return "sg."
        case .anzab:
            return "anzab."
        }
    }
    
}

extension Region {
    init?(server: String) {
        for region in Region.allCases {
            if region.server == server {
                self = region
                return
            }
        }
        return nil
    }
}

extension UserDefaults {
    enum Keys {
        static let Server = "server"
    }
}
