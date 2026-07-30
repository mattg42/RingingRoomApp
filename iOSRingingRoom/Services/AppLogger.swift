//
//  AppLogger.swift
//  iOSRingingRoom
//

import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.goodship.iOSRingingRoom"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let auth = Logger(subsystem: subsystem, category: "authentication")
    static let navigation = Logger(subsystem: subsystem, category: "navigation")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let socket = Logger(subsystem: subsystem, category: "socket")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
