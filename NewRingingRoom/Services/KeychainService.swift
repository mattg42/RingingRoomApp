//
//  KeychainServices.swift
//  iOSRingingRoom
//
//  Created by Matthew on 20/02/2021.
//  Copyright © 2021 Matthew Goodship. All rights reserved.
//

import Foundation

enum KeychainError: Error, Alertable {
    case badData
    case servicesError(status: OSStatus)
    case itemNotFound
    case unableToConvertToString
    
    var alertData: AlertData {
        switch self {
        case .badData:
            return AlertData(title: "Keychain error", message: "Cannot convert data to password. Please restart the app. If the problem persists, please contact support at ringingroomapp@gmail.com.")
        case .servicesError(let status):
            let message: String
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                message = String(errorMessage)
            } else {
                message = "Status Code: \(status)"
            }
            return AlertData(title: "Keychain error", message: message)
        case .itemNotFound, .unableToConvertToString:
            return AlertData(title: "Failed to retrieve password", message: "Please restart the app. If the problem persists, reinstall the app.")
        }
    }
}

enum KeychainService {
        
    static func storePasswordFor(account: String, password: String, server: String) throws {
        if password.isEmpty {
            try deletePasswordFor(
                account: account,
                server: server
            )
            return
        }
        
        guard let passwordData = password.data(using: .utf8) else {
            print("Error converting value to data.")
            throw KeychainError.badData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: account,
            kSecAttrServer as String: server,
            kSecValueData as String: passwordData
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            try updatePasswordFor(
                account: account,
                password: password,
                server: server
            )
        default:
            throw KeychainError.servicesError(status: status)
        }
    }
    
    static func getPasswordFor(account: String, server: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: account,
            kSecAttrServer as String: server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.servicesError(status: status)
        }
        
        guard
            let existingItem = item as? [String: Any],
            let valueData = existingItem[kSecValueData as String] as? Data,
            let value = String(data: valueData, encoding: .utf8)
        else {
            throw KeychainError.unableToConvertToString
        }
        
        return value
    }
    
    static func updatePasswordFor(account: String, password: String, server: String) throws {
        guard let passwordData = password.data(using: .utf8) else {
            print("Error converting value to data.")
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: account,
            kSecAttrServer as String: server
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.servicesError(status: status)
        }
    }
    
    static func deletePasswordFor(account: String, server: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: account,
            kSecAttrServer as String: server
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.servicesError(status: status)
        }
    }
    
    static func clear() {
        let secItemClasses =  [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
}

