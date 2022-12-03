//
//  ErrorUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation

enum ErrorUtil {
    static func `do`(networkRequest: Bool = false, _ closure: @escaping () async throws -> Void) async {
        do {
            if networkRequest {
                guard NetworkMonitor.shared.isConnected else {
                    AlertHandler.presentAlert(title: "Connection Error", message: "Unable to connect to the server. Please check your internet connection and try again.", dismiss: .cancel(title: "Try again.", action: {
                        Task {
                            await ErrorUtil.do(networkRequest: true) {
                                try await closure()
                            }
                        }
                    }))
                    return
                }
            }
            
            try await closure()
        } catch let error as Alertable {
            AlertHandler.handle(error: error)
        } catch {
            fatalError()
        }
    }
    
    static func `do`(_ closure: () throws -> Void) {
        do {
            try closure()
        } catch let error as Alertable {
            AlertHandler.handle(error: error)
        } catch {
            fatalError()
        }
    }
}
