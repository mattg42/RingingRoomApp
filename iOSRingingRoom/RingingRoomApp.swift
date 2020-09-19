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
            if UserDefaults.standard.bool(forKey: "keepMeLoggedIn") {
                AutoLogin()
            } else {
                WelcomeLoginScreen().colorScheme(.light)
            }
        }
    }
}
