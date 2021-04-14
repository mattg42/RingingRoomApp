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
import MessageUI

class HelpDocumentation {
    static let creatingAnAccount = """
To help Ringing Room give you a safe, secure ringing experience and to help store your preferences, you will need an account to access Ringing Room. You can create an account by clicking the Settings tab at the bottom right of your screen. Your email address and an encrypted version of your password are stored securely on the Ringing Room server. They will not be shared with anyone for any reason.

After you have registered, you will be automatically logged in. In the Settings view, your username will appear at the top of the screen. If you want to manage your account, such as changing your password, you will need to login on the Ringing Room website. These facilities will be added in a future version of the app.

If you ever forget your password, you will need to log out, then press 'Forgot password' in the bottom left corner of the login page. Enter you email address, then press on Request password reset. An email will be sent to your address on file with a link to reset your password. Note that this link is only good for 24 hours after being sent. Make sure to check your spam filter for the email if it doesn't arrive promptly.
"""
    
    static let accountSettings = """
To change your account settings, go to the account tab. There you will find buttons to change your username, email, password, and to delete your account. To change a particular setting, press on the relevant 'change' button. This will bring up a form. Follow the instructions on the form to change the setting.
"""
    
    static let creatingOrJoiningATower = """
If you have visited a tower before, then you can join it by pressing on its name in the list of recent towers.
If you are joining a tower for the first time, then, in the towers tab, press on 'Join tower by ID'. Type in the ID of the tower you wish to join, and press join.

To create a tower, go to the Towers view and press on 'Create new tower' to reveal a text box and the Create Tower button. Next, type the name of the new tower into the text box. Press Create Tower and you will be sent to a new tower with that name.
"""
    
    static let ringingTheBells = """
Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear near the bottom of your screen.

You may wish to change the number of bells in the tower, whether you are ringing tower bells or handbells. This can be achieved by selecting the desired option in the Tower Controls. You can access the Tower Controls by clicking on the button at the top-right of the Ringing view. Also available in the tower controls are a list of users, and the chat. You will also be able to assign ringers to bells; this is covered in the Advanced Features section.
"""
    
    static let makingCalls = """
You can make calls by pressing the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.
"""
    
    static let leavingATower = """
At the top of the ringing view, there is a button called 'Leave'. Pressing this will remove you from the tower and bring you back to the Towers view.
"""
    
    static let tips = """
To prevent notifications from silencing the audio and distracting you while ringing, it's a good idea to switch on "Do Not Disturb" before a ringing session. This setting can be found in the Control Centre (it has a crescent moon icon), or search the Settings app to find it. Remember to turn it off again after ringing if you want to see and hear notifications.


"""
    
    static let assigning = """
The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the name of the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Tapping the \"x\" to the left of a bell number will un-assign the ringer from that bell. There is also an Un-assign All button, which un-assigns every ringer.

Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. There is more about changing your perspective in the section "Rotating the perspective of the bell circle". For every bell you are assigned to, there will be a large button for ringing that bell.

There is also a button called 'Fill In'. This will randomly assign unassigned ringers to available bells. The Fill In button is only enabled if there are at least as many unassigned ringers as available bells. If Wheatley is in the tower, then Fill In will randomly assign all human ringers a bell, then fill in the rest with Wheatley.
"""
    
    static let wheatley = """
Wheatley is a computer ringer for Ringing Room, made by Ben White-Horne and Matthew Johnson and designed to be a 'ninja helper with no ego' - i.e. Wheatley will any number of bells to whatever you want to ring, but should fit in as much as possible to what you're ringing. Wheatley is now available directly inside Ringing Room, without any installation.

Enabling Wheatley
Wheatley needs to be enabled on a per-tower basis with the switch in the tower settings. This can only be done through the website currentley. Once Wheatley is enabled, a user called 'Wheatley' will be present in the users list. You can then assign Wheatley to bells like any other person. The Fill In button will randomly assign all human ringers first, then fill the remaining bells with Wheatley.

To tell Wheatley what to ring, you need to the tower on the website. The control for Wheatley in the app is coming soon.

To start ringing a method with Wheatley (only on the website):
Click on the "Methods" tab in the Wheatley box.
Click in the text box that says "Start typing method name".
Start typing the name of the method you want to ring. As you type, a list of potential method names will appear (filtered according to the tower size).
Click on the method name you want to ring, or press "Enter" to select the first option.
If everything worked out, the first line of the Wheatley box should say "After 'Look To', Wheatley will ring <your method name>", and Wheatley will ring that method after Look To is called.

Wheatley will still respond to all yours calls from the app, such as Look To, or Stand.
"""
    
    static let rotating = """
By default, whenever you are assigned a bell, that bell will appear in the bottom right corner of the bell circle. However, if you would like to have control over your perspective of the bell circle, the is a button at the bottom right corner of the bell circle with four arrows in a circle. Pressing this will enter you into Rotate mode. In Rotate mode, when you press a bell, instead of it ringing, it will change your perspective so that bell will be in the bottom right corner, and you will exit Rotate mode. To cancel Rotate mode without changing the perspective, press the button with four arrows in a circle again.

In addition, in the Settings tab, there is an option to disable the automatic rotation of the bell circle when you are assigned a bell.
"""
    
    static let managingTowers = """
The Towers tab shows all the towers associated with your account. They are sorted by last visited, with the most recent at the top.

In a later version, you will be able to view separate lists for recent, bookmarked, created and host towers, and be able to change the settings for the towers you have created.
"""
    
    static let hostMode = """
Host Mode is a special mode that can be enabled for towers in order to restrict who can direct the ringing at that tower. To enable Host Mode, you will need to go to the Tower Settings page on the ringingroom.com website and set the \"Permit Host Mode\" feature to \"Yes\".

A tower host is someone who has special privileges at a Ringing Room virtual tower. You can think of this as being like a tower captain or a ringing master: A host is someone who might take charge of a practice. A tower can have multiple hosts who can share responsibility for running practices. You can add hosts to towers that you have created by going to the My Towers page on the ringingroom.com website, finding the tower you want, clicking the Settings button, and entering the email address of the Ringing Room account you want to add as a host in the box at the bottom left. You can remove hosts from a tower by clicking the \"X\" icon in the list of tower hosts. The creator of a tower is always a host there.

If Host Mode is permitted at a tower, hosts have an extra switch in the tower controls, allowing them to enable or disable Host Mode. When a tower is in Host Mode, various restrictions are imposed:
    • Only hosts may change the number of bells or switch between handbell and tower-bell mode.
    • Non-hosts may only make calls when assigned to a bell.
    • Non-hosts may only ring bells that they are assigned to.
    • Only hosts may assign other ringers to bells.
    • Non-hosts may assign themselves to open bells only — that is, they can \"catch hold\" of unused bells, but not displace other ringers.

Host mode can only be activated or deactivated by any hosts currently in the tower. If there are no hosts present in the tower, host mode will automatically be disabled so that ringing can proceed normally.
"""
    
    static let volume = """
Ringing Room has a volume slider that lets you reduce the volume of the bells without affecting the system volume. This is useful if you are using Ringing Room and Zoom (or other apps such as Discord) at the same time on your device - you can lower the volume of the bells, without making peoples' voices quieter.

To access the volume slider, you must be in a tower. Once in a tower, go to the tower controls. Then press on the button with a speaker symbol on it. This will reveal the volume slider. Press the speaker button again to hide the volume slider.
"""
    
}

class FAQ:Identifiable {

    var question:String
    var answer:String
    
    var id = UUID()
    
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
    
    static var FAQs = [
        FAQ(question: "I can't hear any audio", answer: "Make sure your volume is up. If are using Zoom on the same device and still can't hear any audio, this might be because you joined the Zoom call before opening Ringing Room. Make sure you have Ringing Room open, then leave your Zoom call and rejoin it. Now you should be able to hear Ringing Room and Zoom clearly. If you are not using using Zoom, and still can't hear any audio, then please restart the app."),
        FAQ(question: "How can I stop notifications while I'm ringing?", answer: "Turn on Do Not Disturb. This is a system setting that will silence your notifications. You can find this setting in two places: the settings app, and Control Centre. To find it in the setting app, go to settings, then swipe down to reveal the search bar. Tap it, and enter 'Do not disturb'. Tap on the first result. Then, turn on the Do Not Disturb toggle. Alternatively, you can find the setting in Control Centre. To get to Control Centre, swipe down from the top-right corner of the screen, or swipe up from the bottom if you are using an iPhone without a notch. Next, press the button with the crescent moon icon. If the moon turns purple, with a white background, then Do Not Disturb is on. Remember to turn it off again once you have finished ringing."),
        FAQ(question: "My device keeps turning off", answer: "To stop your device going to sleep between rings because you don't touch the screen for a while, perhaps while chatting on Zoom or sitting out of a touch, you can set the Auto-Lock duration to Never. The Auto-Lock setting is in the Display & Brightness section of the Settings app."),
        FAQ(question: "How can I control Wheatley?", answer: "There is no Wheatley control in the app at present. That feature will be added soon. For now, join the tower through ringingroom.com to control Wheatley.")
    ]
    
}

extension Text {
    init(_ faq: FAQ) {
        self.init("")
        self = Text(faq.question).bold()
        self = self + Text("\n\n\(faq.answer)\n")
    }
}

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
                NavigationLink("About", destination: AboutView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
            Section {
                NavigationLink("Quick Start Guide", destination: QuickStartGuideView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Advanced Features", destination: AdvancedFeaturesView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("FAQs",  destination: FAQsView(asSheet: self.asSheet, isPresented: self.$isPresented))
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

struct FAQsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    
    var body: some View {
//        ZStack {
        ScrollView {
            VStack {
                ForEach(FAQ.FAQs) { faq in
                    Text(faq)
                }
            }
            .padding()
        }

        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("FAQs", displayMode: .inline)
    }
}

struct AboutView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
        
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false
    @State private var noMailAlert = false
    
    @State private var isShowingPrivacyPolicy = false
    
    var body: some View {
//        ZStack {
        ScrollView {
            VStack(spacing: 20.0) {
                
                HStack(spacing: 10.0) {
                    Image("Icon")
                        .cornerRadius(13, antialiased: true)
                    
                    VStack(alignment: .leading, spacing: 4.5) {
                        Text("Ringing Room").bold()
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)").bold()
                        Text("by Matthew Goodship")
                            .foregroundColor(.secondary)
                        
                    }
                }.padding(.top, 5)
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
                            Link("github.com/Matthew15625/iOSRingingRoom", destination: URL(string: "https://github.com/Matthew15625/iOSRingingRoom")!)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text("Privacy Policy").bold()
                        PrivacyPolicyView()
                        
                    }
                }
            }
            .padding()

        }
        

        .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
            if asSheet {
                Text("Dismiss")
            } else {
                Text("")
            }
            
        })
            .navigationBarTitle("About", displayMode: .inline)
    }
}

struct QuickStartGuideView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
        
    var body: some View {
        Form {
            Section {
//                NavigationLink("Creating an account", destination: CreatingAnAccountView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Changing account settings", destination: ChangingAccountSettingsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Joining or creating a tower", destination: CreatingOrJoiningATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Ringing the bells", destination: RingingTheBellsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Making calls", destination: MakingCallsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Leaving a tower", destination: LeavingATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Reducing the volume", destination: VolumeView(asSheet: self.asSheet, isPresented: self.$isPresented))
            }
            Section {
                NavigationLink("Full Quick Start Guide", destination: ScrollView {
                    QuickStartGuideTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                }
                .navigationBarTitle("Full Quick Start Guide", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
                    if asSheet {
                        Text("Dismiss")
                    } else {
                        Text("")
                    }
                    
                }))
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

struct CreatingAnAccountView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.creatingAnAccount)
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

struct ChangingAccountSettingsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.accountSettings)
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
            .navigationBarTitle("Changing account settings", displayMode: .inline)
    }
}

struct VolumeView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.volume)
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
            .navigationBarTitle("Reducing the volume", displayMode: .inline)
    }
}


struct CreatingOrJoiningATowerView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.creatingOrJoiningATower)
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
            .navigationBarTitle("Joining or creating a tower", displayMode: .inline)
    }
}

struct RingingTheBellsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.ringingTheBells)
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
                Text(HelpDocumentation.makingCalls)
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
            Text(HelpDocumentation.leavingATower)
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
            VStack(alignment: .leading) {
//                Group {
//                    Text("Creating an account\n")
//                        .font(.headline)
//                        .bold()
//                    Text(HelpDocumentation.creatingAnAccount)
//                }
                Group {
                    Text("\n\nChanging account settings\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.accountSettings)
                }
                Group {
                    Text("\n\nJoining or creating a tower\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.creatingOrJoiningATower)
                }
                Group {
                    Text("\n\nRinging the bells\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.ringingTheBells)
                }
                Group {
                    Text("\n\nMaking calls\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.makingCalls)
                }
                Group {
                    Text("\n\nLeaving a tower\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.leavingATower)
                }
                Group {
                    Text("\n\nReducing the volume\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.volume)
                }
                
            }
            .padding()
    }
}

struct AdvancedFeaturesView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        Form {
            Section {
                NavigationLink("Assigning Ringers to Bells", destination: AssigningRingersView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Wheatley", destination: WheatleyHelpView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Rotating your Perspective of the Bell Circle", destination: RotateBellCircleView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Managing Your Towers", destination: ManagingTowersView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Hosts and Host Mode", destination: HostsAndHostModeView(asSheet: self.asSheet, isPresented: self.$isPresented))
                
//                NavigationLink("Listener links", destination: ListenerLinksView(asSheet: self.asSheet, isPresented: self.$isPresented))
//            NavigationLink("Handbell and Towerbell Simulators", destination: )
            }
            Section {
                NavigationLink("Full Advanced Features", destination: ScrollView {
                    AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                }
                .navigationBarTitle("Advanced Features", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
                    if asSheet {
                        Text("Dismiss")
                    } else {
                        Text("")
                    }
                }))
            }
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
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text("Assigning Ringers\n")
                .font(.headline)
                .bold()
                Text(HelpDocumentation.assigning)
            }
            Group {
                Text("\n\nWheatley\n")
                    .font(.headline)
                    .bold()
                Text(HelpDocumentation.wheatley)
            }
            Group {
                Text("\n\nRotating your perspective of the bell circle\n")
                .font(.headline)
                .bold()
                Text(HelpDocumentation.rotating)
            }
            Group {
                Text("\n\nManaging towers\n")
                .font(.headline)
                .bold()
                Text(HelpDocumentation.managingTowers)
            }
            Group {
                Text("\n\nHost and host mode\n")
                .font(.headline)
                .bold()
                Text(HelpDocumentation.hostMode)
            }
        }
        .padding()

    }
}

struct AssigningRingersView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 0) {
                Text(HelpDocumentation.assigning)
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
            .navigationBarTitle("Assigning Ringers to Bells")
    }
}

struct WheatleyHelpView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.wheatley)
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
            .navigationBarTitle("Wheatley", displayMode: .inline)
    }
}


struct RotateBellCircleView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 0) {
                Text(HelpDocumentation.rotating)
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
            .navigationBarTitle("Rotating your Perspective of the Bell Circle")
    }
}

struct ManagingTowersView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.managingTowers)
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
            .navigationBarTitle("Managing Your Towers")
    }
}

struct HostsAndHostModeView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.hostMode )
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
            .navigationBarTitle("Hosts and Host Mode")
    }
}

struct ListenerLinksView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("If you append \"/listen\" to the link of any tower, the resulting page will be a \"listen-only\" version of the tower appropriate for sending to anyone who wishes to observe the ringing without risking disturbing the band. (For example, if you have the tower ID '1234' and name 'Example', then the link \"ringingroom.com/1234/example/listen\" will go to the listen-only page.)") + Text(" Currently the iOS App does not support listener-only mode. Coming soon in a later version.").bold()
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
            .navigationBarTitle("Listener Links")
    }
}

//struct FAQsTextView:View {
//    var asSheet:Bool
//
//    @Binding var isPresented:Bool
//    var body: some View {
//        NavigationView {
//            Form {
//                Section {
//
//                }
//                Section {
//
//                }
//            }
//
//            .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {
//                if asSheet {
//                    Text("Dismiss")
//                } else {
//                    Text("")
//                }
//
//            })
//        }
//    }
//}
//
//struct FAQsTextView:View {
//    var asSheet:Bool
//
//    @Binding var isPresented:Bool
//    var body: some View {
//        Text("")
//    }
//}

struct HelpTextView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0)    {
                Text("Quick Start Guide")
                    .font(.title)
                    .bold()
                QuickStartGuideTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                Text("\n") + Text("Advanced Features")
                    .font(.title)
                    .bold()
                AdvancedFeaturesTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
//                Text("FAQs")
//                    .font(.title)
//                    .bold()
//                FAQsTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
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

