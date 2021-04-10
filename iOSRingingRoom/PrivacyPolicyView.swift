//
//  privacyPolicy.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 03/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import MessageUI

struct PrivacyPolicyWebView:View {

//    var webview = Webview(web: nil, url: URL(string: "https://ringingroom.com/privacy")!)

    @Binding var isPresented:Bool

    var body: some View {
        NavigationView {
            WebView.privacy
                            .navigationBarTitle("Privacy", displayMode: .inline)
                            .navigationBarItems(trailing: Button("Dismiss") {isPresented = false})
        }
        .accentColor(.main)

    }
}

//struct MyView:View {
//    var body: some View {
//        GeometryReader { geo in
//            Color.red
//                .onAppear {
//                    print(geo.size)
//                }
//        }
//    }
//}

struct PrivacyPolicyView: View {
    
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false
    @State private var noMailAlert = false
    
    @State private var isShowingPrivacyPolicy = false
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The Ringing Room app is independently operated by Matthew Goodship. This app doesn’t collect any personal information, but it does collect crash reports and performance data if you have opted in on your device (you can find the setting by going to Settings > Privacy > Analytics and Improvements > Share With App Developers). However, it does use the Ringing Room API to function. Therefore Ringing Room is able to see all the requests made and use that information, such as your email address, as they see fit. By using this app, you are subject to Ringing Room’s Privacy Policy, which can be found at")
            Button("ringingroom.com/privacy") {isShowingPrivacyPolicy = true}
        }
        .sheet(isPresented: $isShowingPrivacyPolicy, content: {
//            PrivacyPolicyWebView(isPresented: $isShowingPrivacyPolicy)
            PrivacyPolicyWebView(isPresented: $isShowingPrivacyPolicy)



        })
    }
//        VStack(alignment: .leading, spacing: 8.5) {
//            Group {
//                Text("Ringing Room is independently operated by Leland Paul Kusmer and Bryn Marie Reinstadler. This privacy policy will explain how we use the personal data we collect from you when you use our website.")
//                Text("Topics:")
//                VStack(alignment: .leading) {
//                    Group {
//                        BulletLine(text: "What data do we collect?")
//                        BulletLine(text: "How do we collect your data?")
//                        BulletLine(text: "How will we use your data?")
//                        BulletLine(text: "How do we store your data")
//                        BulletLine(text: "What are your data protection rights?")
//                        BulletLine(text: "What are cookies?")
//                        BulletLine(text: "How do we use cookies?")
//                        BulletLine(text: "What types of cookies do we use?")
//                        BulletLine(text: "How to manage your cookies")
//                        BulletLine(text: "Privacy policies of other websites")
//                    }
//                    BulletLine(text: "Changes to our privacy policy")
//                    BulletLine(text: "How to contact us")
//                    BulletLine(text: "How to contact the appropriate authorities")
//                }
//                Text("What data do we collect?")
//                    .subtitle()
//                Text("Ringing Room collects the following data:")
//                    .font(.body)
//                BulletLine(text: "Your email address")
//                Text("How do we collect your data?")
//                    .subtitle()
//                Text("We only collect data that you directly provide us with. We collect your email address when you register for an account, or when you update the email address of an existing account. We also collect and process data when you use or view our website via your browsers cookies.")
//            }
//            Group {
//                Text("How will we use your data?")
//                    .subtitle()
//                Text("We collect your data so that we can:")
//                VStack(alignment: .leading) {
//                    BulletLine(text: "Email you if you forget your password and require a reset.")
//                    BulletLine(text: "Keep track of what towers you have visited on our site.")
//                }
//                Text("We will never share your data with any other organizations or individuals for any reason.")
//                Text("How do we store your data?")
//                    .subtitle()
//                Text("We store your data in a password-protected database on our servers hosted at DigitalOcean. We will keep your email address indefinitely, until you request that we delete it. All cookies are deleted after 30 days.")
//            }
//            Group {
//                Text("What are your data protection rights?")
//                    .subtitle()
//                Text("Every user is entitled to the following:")
//                VStack(alignment: .leading, spacing: 14.0) {
//                    Text("The right to access – ").fontWeight(.semibold) + Text("You have the right to request copies of your personal data from Ringing Room.")
//                    Text("The right to rectification – ").fontWeight(.semibold) + Text("You have the right to request that Ringing Room correct any information you believe is inaccurate. You also have the right to request Ringing Room to complete the information you believe is incomplete.")
//                    Text("The right to erasure – ").fontWeight(.semibold) + Text("You have the right to request that Ringing Room erase your personal data.")
//                    Text("The right to restrict processing – ").fontWeight(.semibold) + Text("You have the right to request that Ringing Room restrict the processing of your personal data, under certain conditions.")
//                    Text("The right to object to processing – ").fontWeight(.semibold) + Text("You have the right to object to Ringing Room's processing of your personal data.")
//                    Text("The right to data portability – ").fontWeight(.semibold) + Text("You have the right to request that Ringing Room transfer the data that we have collected to another organization, or directly to you, under certain conditions.")
//                }
//                Text("If you make a request, we have one month to respond to you. If you would like to exercise any of these rights, please contact us at our email: ")
//                Button("ringingroom@gmail.com") {
//                    MFMailComposeViewController.canSendMail() ? self.isShowingMailView.toggle() : self.noMailAlert.toggle()
//                }
//                .sheet(isPresented: $isShowingMailView) {
//                    MailView(result: self.$result, recipient:"ringingroom@gmail.com")
//                }
//                .alert(isPresented: self.$noMailAlert) {
//                    Alert(title: Text("Mail not setup"), message: Text("Mail is not setup on your device."), dismissButton: .default(Text("OK")))
//                }
//            }
//
//
//
//            Group {
//                Text("Cookies")
//                    .subtitle()
//                Text("Cookies are text files placed on your computer to collect standard Internet log information and visitor behavior information. When you visit Ringing Room, we may collect information from you automatically through cookies or similar technology.")
//                Text("For further information, visit allaboutcookies.org.")
//                Text("How do we use cookies?")
//                    .subtitle()
//                Text("Ringing Room uses cookies in a range of ways to improve your experience on our website, including:")
//                VStack(alignment: .leading) {
//                    BulletLine(text: "Keeping you signed in")
//                    BulletLine(text: "Tracking what towers you have visited so that you can return to them easily")
//                    BulletLine(text: "Understanding how you use Ringing Room")
//                }
//                Text("What types of cookies do we use?")
//                    .subtitle()
//                Text("There are a number of different types of cookies. Our website uses the following types:")
//                VStack(alignment: .leading) {
//                    HStack(alignment: .top) {
//                        Text("• ")
//                        (Text("Functionality - ").fontWeight(.semibold) + Text("Ringing Room uses these cookies so that we can recognize you on our website and remember your username and recent towers. Only first-party cookies are used."))
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    .padding(.leading, 15)
//                    HStack(alignment: .top) {
//                        Text("• ")
//                        (Text("Analytics - ").fontWeight(.semibold) + Text("We use third-party cookies from Google Analytics to track how many visitors our website gets."))
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    .padding(.leading, 15)
//                }
//            }
//            Group {
//                Text("How to manage your cookies")
//                    .subtitle()
//                Text("You can set your browser not to accept cookies, and the above website tells you how to remove cookies from your browser. However, if you do not accept cookies, you will not be able to log in and ring on Ringing Room.")
//                Text("Privacy policies of other websites")
//                    .subtitle()
//                Text("Ringing Room contains links to other websites. Our privacy policy applies only to Ringing Room, so if you click on a link to another website, you should read their privacy policy.")
//                Text("Changes to our privacy policy")
//                    .subtitle()
//                Text("Ringing Room keeps its privacy policy under regular review and places any updates on this web page. This privacy policy was last updated on 27 May 2020.")
//            }
//            Group {
//                Text("How to contact us")
//                    .subtitle()
//                Text("If you have any questions about Ringing Room's privacy policy or the data we collect, or you would like to exercise one of your data protection rights, please do not hesitate to contact us by emailing us at:")
//                Button("ringingroom@gmail.com") {
//                    MFMailComposeViewController.canSendMail() ? self.isShowingMailView.toggle() : self.noMailAlert.toggle()
//                }
//                .sheet(isPresented: $isShowingMailView) {
//                    MailView(result: self.$result, recipient:"ringingroom@gmail.com")
//                }
//                .alert(isPresented: self.$noMailAlert) {
//                    Alert(title: Text("Mail not setup"), message: Text("Mail is not setup on your device."), dismissButton: .default(Text("OK")))
//                }
//                Text("How to contact the appropriate authorities")
//                    .subtitle()
//                Text("Should you wish to report a complaint or if you feel that Ringing Room has not addressed your concern in a satisfactory manner, you may contact the Information Commissioner's Office at https://ico.org.uk")
//            }
//        }
//        .accentColor(.main)
//        .padding()
}


extension Text {
    public func subtitle() -> some View {
        self
            .font(.headline)
            .fontWeight(.bold)
            .padding(.vertical, 5)
    }
}
