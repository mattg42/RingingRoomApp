//
//  Bool+IntInit.swift
//  NewRingingRoom
//
//  Created by Matthew on 08/08/2021.
//

import Foundation

public extension Bool {
    init<T: Numeric>(_ num: T) {
        self.init(num != 0)
    }
}
