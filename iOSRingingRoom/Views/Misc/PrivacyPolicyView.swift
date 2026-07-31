//
//  privacyPolicy.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 03/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @State private var isShowingPrivacyPolicy = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The Ringing Room app is independently operated by Matthew Goodship. To provide account and tower features, it sends your username, account email address, and other account details to the Ringing Room API. Your email address is used for login and password recovery and is not included in chat messages sent to tower participants. Messages you send in a tower are shared with that tower’s participants. The app may also collect crash reports and performance data if you have opted in on your device (you can find the setting by going to Settings > Privacy > Analytics and Improvements > Share With App Developers). By using this app, you are subject to Ringing Room’s Privacy Policy.")

            Button("Read the full Ringing Room privacy policy") {
                isShowingPrivacyPolicy = true
            }
        }
        .sheet(isPresented: $isShowingPrivacyPolicy) {
            PrivacyPolicyWebView(isPresented: $isShowingPrivacyPolicy)
        }
    }
}

struct PrivacyPolicyWebView: View {
        
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            WebView.privacy
                .navigationBarTitle("Privacy", displayMode: .inline)
                .navigationBarItems(trailing: Button("Dismiss") { isPresented = false })
        }
        .accentColor(.main)
    }
}
