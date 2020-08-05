//
//  agreeToPrivacyPolicyView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct agreeToPrivacyPolicyView: View {
    
    @Binding var isPresented:Bool
    @Binding var agreed:Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Scroll down to agree")
                    .bold()
                    .font(.title)
                    .padding()
                privacyPolicyView()
                
                Button("I have read and agree to the privacy policy") {
                    self.agreed = true
                    self.isPresented = false
                }
            .padding()
            }
            .navigationBarTitle("Our Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {Text("Back").bold()})
            
        }
    .navigationViewStyle(StackNavigationViewStyle())
    }
}

