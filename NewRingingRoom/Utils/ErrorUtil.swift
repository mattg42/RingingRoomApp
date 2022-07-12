//
//  ErrorUtil.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation

enum ErrorUtil {
    static func `do`(_ closure: () async throws -> Void) async {
        do {
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
