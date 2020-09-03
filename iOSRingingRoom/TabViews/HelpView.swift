//
//  HelpView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct HelpView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    
    var body: some View {
        NavigationView {
            MasterHelpView(asSheet: self.asSheet, isPresented: self.$isPresented)
        }
            
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MasterHelpView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Quick Start Guide", destination: QuickStartGuideView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Advanced Features", destination: AdvancedFeaturesView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("FAQs",  destination: QuickStartGuideView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
            Section {
                NavigationLink("Full help document", destination: HelpTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("Help")
    }
}

struct QuickStartGuideView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Computing set-up", destination: ComputingSetUpView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Creating an account", destination: CreatingAnAccountView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Creating or joining a tower", destination: CreatingOrJoiningATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Ringing the Bells", destination: RingingTheBellsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Making calls", destination: MakingCallsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Leaving a tower", destination: LeavingATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
            Section {
                NavigationLink("Full Quick Start Guide", destination: QuickStartGuideTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("Quick Start Guide", displayMode: .inline)
    }
}

struct ComputingSetUpView:View {
    
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    
    var body:some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("The ideal computing set-up for using the Ringing Room website is:")
                VStack(alignment: .leading) {
                    bulletLine(text: "Hardware: A laptop or desktop computer")
                    bulletLine(text: "Operating System: any modern operating system")
                    bulletLine(text: "Browser: Google Chrome or the latest version of Microsoft Edge (Other browsers may be OK)")
                    bulletLine(text: "Voice Chat: There is text chat in Ringing Room, but voice chat is often preferred. We suggest Zoom or Discord.")
                    bulletLine(text: "Headphones: Ideal to reduce echo and double-clappering")
                    bulletLine(text: "Internet Connection: Use a wired connection where wireless is too slow.")
                }
                Text("Alternatively, if you use an iPhone, you can download the Ringing Room app from the App Store")
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Computing set-up", displayMode: .inline)
    }
}

struct CreatingAnAccountView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("To help us give you a safe, secure ringing experience and to help us store your preferences, you will need an account to access Ringing Room. You can create an account by clicking the settings tab at the bottom right of your screen. Your email address and an encrypted version of your password are stored securely on our server. We will not share them with anyone for any reason.")
                Text("After you have registered, you will be automatically logged in. When you are logged in, in the settings tab, your username will appear at the top of the screen and you will also be able to see various advanced settings, including facilities for changing your username, email address, or password. You can also permanently delete your account.")
                Text("If you ever forget your password, you can use the password reset link on the log-in page, which will send an email to your address on file with a link to reset your password. Note that this link is only good for 24 hours after being sent. Make sure to check your spam filter for the email if it doesn't arrive promptly.")
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Creating an account", displayMode: .inline)
    }
}

struct CreatingOrJoiningATowerView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Creating a tower on Ringing Room is simple. Go to the ring tab and type your desired name into the box in the center of the page. Once you press enter, you will be sent to a tower with that name. Each tower comes with a unique 9-digit ID which can be shared to allow others into that same tower.")
                Text("To join a tower, you must be equipped with its 9-digit ID number, which can then be typed or copied into the box at the bottom of the ring tab. Alternately, if you have been furnished with a link to a tower, you can click that link and be sent to the tower directly.")
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Creating or joining a tower", displayMode: .inline)
    }
}

struct RingingTheBellsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear at the bottom of your screen.")
                Text("You may wish to change the number of bells in the tower, or whether you are in ringing tower bells or handbells. This can be achieved by selecting the desired option in the tower controls. You can access the tower controls by clicking on the 3-lined black menu button in the top-right. Also available in the tower controls are a list of users, and a chat box. You will also be able to assign ringers to bells; this will be covered in the Advanced Features section.")
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Ringing the bells", displayMode: .inline)
    }
}

struct MakingCallsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("You can make calls by pressing the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.")
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Making calls", displayMode: .inline)
    }
}

struct LeavingATowerView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        VStack {
            Text("At the bottom of the tower controls menu, there is a button called 'Leave tower'. Pressing this will remove you from the tower and bring you back to the ring tab.")
            Spacer()
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
            .navigationBarTitle("Leaving a tower", displayMode: .inline)
    }
}

struct QuickStartGuideTextView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    Text("Computing set-up")
                        .font(.headline)
                        .bold()
                    Text("The ideal computing set-up for using the Ringing Room website is:")
                    VStack(alignment: .leading) {
                        bulletLine(text: "Hardware: A laptop or desktop computer")
                        bulletLine(text: "Operating System: any modern operating system")
                        bulletLine(text: "Browser: Google Chrome or the latest version of Microsoft Edge (Other browsers may be OK)")
                        bulletLine(text: "Voice Chat: There is text chat in Ringing Room, but voice chat is often preferred. We suggest Zoom or Discord.")
                        bulletLine(text: "Headphones: Ideal to reduce echo and double-clappering")
                        bulletLine(text: "Internet Connection: Use a wired connection where wireless is too slow.")
                    }
                    Text("Alternatively, if you use an iPhone, you can download the Ringing Room app from the App Store.")
                }
                Group {
                    Text("Creating an account")
                        .font(.headline)
                        .bold()
                    Text("To help us give you a safe, secure ringing experience and to help us store your preferences, you will need an account to access Ringing Room. You can create an account by clicking the settings tab at the bottom right of your screen. Your email address and an encrypted version of your password are stored securely on our server. We will not share them with anyone for any reason.")
                    Text("After you have registered, you will be automatically logged in. When you are logged in, in the settings tab, your username will appear at the top of the screen and you will also be able to see various advanced settings, including facilities for changing your username, email address, or password. You can also permanently delete your account.")
                    Text("If you ever forget your password, you can use the password reset link on the log-in page, which will send an email to your address on file with a link to reset your password. Note that this link is only good for 24 hours after being sent. Make sure to check your spam filter for the email if it doesn't arrive promptly.")
                }
                Group {
                    Text("Creating or joining a tower")
                        .font(.headline)
                        .bold()
                    Text("Creating a tower on Ringing Room is simple. Go to the ring tab and type your desired name into the box in the center of the page. Once you press enter, you will be sent to a tower with that name. Each tower comes with a unique 9-digit ID which can be shared to allow others into that same tower.")
                    Text("To join a tower, you must be equipped with its 9-digit ID number, which can then be typed or copied into the box at the bottom of the ring tab. Alternately, if you have been furnished with a link to a tower, you can click that link and be sent to the tower directly.")
                }
                Group {
                    Text("Ringing the bells")
                        .font(.headline)
                        .bold()
                    Text("Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear at the bottom of your screen.")
                    Text("You may wish to change the number of bells in the tower, or whether you are in ringing tower bells or handbells. This can be achieved by selecting the desired option in the tower controls. You can access the tower controls by clicking on the 3-lined black menu button in the top-right. Also available in the tower controls are a list of users, and a chat box. You will also be able to assign ringers to bells; this will be covered in the Advanced Features section.")
                }
                Group {
                    Text("Making calls")
                        .font(.headline)
                        .bold()
                    Text("You can make calls by pressing the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.")
                }
                Group {
                    Text("Leaving a tower")
                        .font(.headline)
                        .bold()
                    Text("At the bottom of the tower controls menu, there is a button called 'Leave tower'. Pressing this will remove you from the tower and bring you back to the ring tab.")
                }
            }
        }
        .navigationBarTitle("Full Quick Start Guide", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .padding()
    }
}

struct AdvancedFeaturesView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        Form {
            NavigationLink("Assigning ringers to bells", destination: AssigningRingersView(asSheet: self.asSheet, isPresented: self.$isPresented))
            NavigationLink("Managing your towers", destination: AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
            NavigationLink("Hosts and host mode", destination: AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
            NavigationLink("Listener links", destination: AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
            NavigationLink("Handbell and Towerbell Simulators", destination: AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented))
        }
        .navigationBarTitle("Advanced Features", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
    }
}

struct AdvancedFeaturesTextView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        Text("")
    }
}

struct AssigningRingersView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack {
                Text("The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Clicking the \"x\" by a bell number will unassign the ringer from that bell.")
                Spacer()
            }
        
        }
    .padding()
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("Assigning ringers to bells")
    }
}
struct FAQsTextView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        Text("")
            .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
                if asSheet {
                    Text("Dismiss")
                } else {
                    Text("")
                }
                
            })
    }
}

struct HelpTextView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            VStack {
                Text("Quick Start Guide")
                    .font(.title)
                    .bold()
                QuickStartGuideTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                Text("Advanced Features")
                    .font(.title)
                    .bold()
                AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                Text("FAQs")
                    .font(.title)
                    .bold()
                FAQsTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
            }
            .padding(.vertical)
        }
        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("Help", displayMode: .inline)
    }
}

