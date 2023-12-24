//
//  AboutView.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI
import MessageUI

struct AboutView: View {
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false
    @State private var noMailAlert = false
    
    @State private var isShowingPrivacyPolicy = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                HStack(spacing: 10.0) {
                    Image("Icon")
                        .cornerRadius(13, antialiased: true)
                    
                    VStack(alignment: .leading, spacing: 4.5) {
                        Text("Ringing Room")
                            .bold()
#if DEBUG
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) (\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String))")
                            .bold()
#else
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                            .bold()
#endif
                        Text("by Matthew Goodship")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 5)
                
                VStack(alignment: .leading, spacing: 20.0) {
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text("This app provides users with a way to ring on Ringing Room using their iPhones and iPads, with a quicker response time than a mobile browser, and a touch friendly user interface.")
                        
                        Text("Ringing Room is a website built by Leland Paul Kusmer and Bryn Marie Reinstadler to allow change ringers to continue ringing with one another even when socially distanced.")
                        
                        Text("The app will be continually improved, with support for features such as tower management and account settings coming soon. If you would like to submit a feature request or bug report, please contact me at")
                        
                        Button("ringingroomapp@gmail.com") {
                            MFMailComposeViewController.canSendMail() ? self.isShowingMailView.toggle() : self.noMailAlert.toggle()
                        }
                        .padding(.top, -5)
                        .sheet(isPresented: $isShowingMailView) {
                            MailView(result: self.$result, recipient:"ringingroomapp@gmail.com")
                        }
                        .alert(isPresented: self.$noMailAlert) {
                            Alert(title: Text("Mail not setup"), message: Text("Mail is not setup on your device."), dismissButton: .default(Text("OK")))
                        }
                        
                        VStack(alignment: .leading, spacing: 0.0) {
                            Text("This app is fully open-source. To view the code, go to")
                            Link("github.com/mattg42/RingingRoomApp", destination: URL(string: "https://github.com/mattg42/RingingRoomApp")!)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text("Privacy Policy")
                            .bold()
                        PrivacyPolicyView()
                        
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("About", displayMode: .inline)
    }
}
