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

class HelpDocumentation {
    static let creatingAnAccount = """
To help Ringing Room give you a safe, secure ringing experience and to help store your preferences, you will need an account to access Ringing Room. You can create an account by clicking the Settings tab at the bottom right of your screen. Your email address and an encrypted version of your password are stored securely on the Ringing Room server. They will not be shared with anyone for any reason.

After you have registered, you will be automatically logged in. In the Settings view, your username will appear at the top of the screen. If you want to manage your account, such as changing your password, you will need to login on the Ringing Room website. These facilities will be added in a future version of the app.

If you ever forget your password, you will need to go to ringingroom.com, where you can use the password reset link on the login page, which will send an email to your address on file with a link to reset your password. Note that this link is only good for 24 hours after being sent. Make sure to check your spam filter for the email if it doesn't arrive promptly.
"""
    
    static let creatingOrJoiningATower = """
To join a tower, if you have visited it before, you can just press on its name in the list of towers. If you want to join a tower you haven't been to before, then press on 'Enter existing tower ID', to reveal a text box and a Join Tower button. Enter the desired tower's 9 digit ID number in the text box and press Join Tower. The Join Tower button is only enabled when 9 digits are in the text box.

Creating a tower on Ringing Room is simple. Go to the Towers view and press on 'Create new tower' to reveal a text box and the Create Tower button. Next, type the name of the new tower into the text box. Press Create Tower and you will be sent to a new tower with that name.
"""
    
    static let ringingTheBells = """
Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear near the bottom of your screen.

You may wish to change the number of bells in the tower, whether you are ringing tower bells or handbells, and if you are ringing tower bells, whether you are ringing half-muffled or open. This can be achieved by selecting the desired option in the Tower Controls. You can access the Tower Controls by clicking on the button at the top-right of the Ringing view. Also available in the tower controls are a list of users, and the chat. You will also be able to assign ringers to bells; this is covered in the Advanced Features section.
"""
    
    static let makingCalls = """
You can make calls by pressing the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.
"""
    
    static let leavingATower = """
At the top of the ringing view, there is a button called 'Leave'. Pressing this will remove you from the tower and bring you back to the Towers view.
"""
    
    static let tips = """
To prevent notifications from silencing the audio and distracting you while ringing, it's a good idea to switch on "Do Not Disturb" before a ringing session. This setting can be found in the Control Centre (it has a crescent moon icon), or search the Settings app to find it. Remember to turn it off again after ringing if you want to see and hear notifications.

To stop your device going to sleep between rings because you don't touch the screen for a while, perhaps while chatting on Zoom or sitting out of a touch, you can set the Auto-Lock duration to Never. The Auto-Lock setting is in the Display & Brightness section of the Settings app.
"""
    
    static let assigning = """
The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the name of the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Tapping the \"x\" to the left a bell number will un-assign the ringer from that bell. There is also an Un-assign All button, which un-assigns every ringer.

Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. There is more about changing your perspective in the section "Rotating the perspective of the bell circle". This will also make a large dedicated button for each assigned bell near the bottom of the screen. If a user is assigned to multiple bells, the lowest-numbered one will be placed on the right.

There is also a button called 'Fill In'. This will randomly assign unassigned ringers to available bells. The Fill In button is only enabled if there are at least as many unassigned ringers as available bells.
"""
    
    static let rotating = """
By default, whenever you are assigned a bell, that bell will appear in the bottom right corner of the bell circle. However, if you would like to have control over your perspective of the bell circle, the is a button at the bottom right corner of the bell circle with four arrows in a circle. Pressing this will enter you into Rotate mode. In Rotate mode, when you press a bell, instead of it ringing, it will change your perspective so that bell will be in the bottom right corner, and you will exit Rotate mode. To cancel Rotate mode without changing the perspective, press the button with four arrows in a circle again.

In addition, in the Settings tab, there is an option to disable the automatic rotation of the bell circle when you are assigned a bell.
"""
    
    
    static let managingTowers = """
The Towers tab shows all the towers associated with your account. They are sorted by last visited, with the most recent at the bottom.

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

Host mode can only be activated or deactivated by any hosts currently in the tower through the Ringing Room website. If there are no hosts present in the tower, host mode will automatically be disabled so that ringing can proceed normally.

A future version of this app will add support for full control of host mode.
"""
    
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
                NavigationLink("Quick Start Guide", destination: QuickStartGuideView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Advanced Features", destination: AdvancedFeaturesView(asSheet: self.asSheet, isPresented: self.$isPresented))
//                NavigationLink("FAQs",  destination: QuickStartGuideView(asSheet: self.asSheet, isPresented: self.$isPresented))
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
                NavigationLink("Creating an account", destination: CreatingAnAccountView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Joining or creating a tower", destination: CreatingOrJoiningATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Ringing the Bells", destination: RingingTheBellsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Making calls", destination: MakingCallsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Leaving a tower", destination: LeavingATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Tips", destination: HintsAndTipsView(asSheet: self.asSheet, isPresented: self.$isPresented))
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

struct HintsAndTipsView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body:some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumentation.tips)
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
            .navigationBarTitle("Hints and Tips", displayMode: .inline)
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
                Group {
                    Text("Creating an account\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.creatingAnAccount)
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
                    Text("\n\nTips\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumentation.tips)
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
                Text("\nAdvanced Features")
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

