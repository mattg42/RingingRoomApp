//
//  agreeToPrivacyPolicyView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AgreeToPrivacyPolicyView: View {
    
    @Binding var isPresented:Bool
    @Binding var agreed:Bool
    
    var body: some View {
        NavigationView {
            VStack {

                PrivacyPolicyView()
                Spacer()
                Button(action: {
                    self.agreed = true
                    self.isPresented = false
                }) {
                    ZStack {
                        Color.main.cornerRadius(10)
                        //                                 VStack {
                        Text("I have read and agree\nto the privacy policy")
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                    }
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }

            }
            .padding()
            .navigationBarTitle("Our Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {Text("Back").bold()})
            
        }
        .accentColor(.main)
    .navigationViewStyle(StackNavigationViewStyle())
    }
}

