//
//  RingingRoomApp.swift
//  iOSRingingRoom
//
//  Created by Matthew on 19/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import SwiftUI

@main
struct RingingRoomApp: App {
    var body: some Scene {
        WindowGroup {
            MainApp()
        }
    }
}

extension URL {
    var isTowerLink:Bool {
        (self.pathComponents.count > 1)
    }
    var towerID:Int? {
        if isTowerLink {
            return Int(self.pathComponents[1])
        } else {
            return nil
        }
    }
}
