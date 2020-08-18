//
//  SettingsView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
                Form {
                    Section(header: Text("Username")) {
                        Text("Current username: ")
                    }
                    
                }.navigationBarTitle("Settings", displayMode: .inline)
            }
           .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
