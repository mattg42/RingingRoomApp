//
//  ThreadUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

@MainActor
enum ThreadUtil {
    static func runInMain(
        after delay: Double = 0,
        scheduler: (any TaskScheduling)? = nil,
        _ closure: @escaping @MainActor () -> Void
    ) {
        if delay == 0 {
            closure()
        } else if let scheduler {
            _ = scheduler.schedule(after: UInt64(delay * 1_000_000_000)) {
                closure()
            }
        } else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                closure()
            }
        }
    }
}
