//
//  UserDefaults.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import Foundation

extension UserDefaults {
    public func optionalInt(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }
    
    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
    
    public func optionalDouble(forKey defaultName: String) -> Double? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Double
        }
        return nil
    }
}
