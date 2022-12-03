//
//  String.swift
//  NewRingingRoom
//
//  Created by Matthew on 21/10/2021.
//

import Foundation

public extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
    
    mutating func prefix(_ prefix:String) {
        self = prefix + self
    }
}
