//
//  ThreadUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

enum ThreadUtil {
    static func runInMain(_ closure: () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.sync {
                closure()
            }
        }
    }
}

