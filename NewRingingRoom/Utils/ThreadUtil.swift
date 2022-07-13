//
//  ThreadUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

enum ThreadUtil {
    static func runInMain(after delay: Double = 0, _ closure: @escaping () -> Void) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if Thread.isMainThread {
                closure()
            } else {
                DispatchQueue.main.sync {
                    closure()
                }
            }
        }
    }
}

