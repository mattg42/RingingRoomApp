//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/04/2022.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        Text("main")
            .task {
                await setupUserAndTowers()
            }
    }
    
    func setupUserAndTowers() async {
        
    }
}
