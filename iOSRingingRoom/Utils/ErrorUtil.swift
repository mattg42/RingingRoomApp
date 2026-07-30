//
//  ErrorUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation

@MainActor
enum ErrorUtil {
    static func `do`(networkRequest: Bool = false, _ closure: @escaping @MainActor () async throws -> Void) async {
        do {
            // URLSession is the source of truth for request reachability. The
            // networkRequest parameter remains for call-site compatibility.
            _ = networkRequest
            try await closure()
        } catch let error as Alertable {
            AlertHandler.handle(error: error)
        } catch {
            print(error)
            AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
        }
    }
    
    static func `do`(_ closure: @MainActor () throws -> Void) {
        do {
            try closure()
        } catch let error as Alertable {
            AlertHandler.handle(error: error)
        } catch {
            AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: nil, action: nil))
        }
    }
}
