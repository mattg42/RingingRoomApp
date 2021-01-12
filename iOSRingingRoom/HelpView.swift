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

class HelpDocumention {
    static let creatingAnAccount = """
To help Ringing Room give you a safe, secure ringing experience and to help store your preferences, you will need an account to access Ringing Room. You can create an account by clicking the settings tab at the bottom right of your screen. Your email address and an encrypted version of your password are stored securely on the Ringing Room server. They will not share them with anyone for any reason.

After you have registered, you will be automatically logged in. In the settings view, your username will appear at the top of the screen. If you want to manage your account, such as changing your password, you will need to login on the Ringing Room website. These facilites will be added in a future version of the app.

If you ever forget your password, you will need to go to ringingroom.com, where you can use the password reset link on the log-in page, which will send an email to your address on file with a link to reset your password. Note that this link is only good for 24 hours after being sent. Make sure to check your spam filter for the email if it doesn't arrive promptly.
"""
    
    static let creatingOrJoiningATower = """
Creating a tower on Ringing Room is simple. Go to the towers view and type your desired name into the box at the bottom of the page. Once you press enter, you will be sent to a tower with that name. Each tower comes with a unique 9-digit ID which can be shared to allow others into that same tower.

To join a tower, you know its 9-digit ID number, which you enter into the box at the bottom of the towers view.
"""
    
    static let ringingTheBells = """
Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear at the bottom of your screen.

You may wish to change the number of bells in the tower, whether you are ringing tower bells or handbells, and if you are ringing tower bells, whether you are ringing half-muffled or open. This can be achieved by selecting the desired option in the tower controls. You can access the tower controls by clicking on the 3-lined black menu button in the top-right. Also available in the tower controls are a list of users, and the chat. You will also be able to assign ringers to bells; this will be covered in the Advanced Features section.
"""
    
    static let makingCalls = """
You can make calls by pressing the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.
"""
    
    static let leavingATower = """
At the top-left of the ringing view, there is a button called 'Leave tower'. Pressing this will remove you from the tower and bring you back to the towers view.
"""
    
    static let assinging = """
The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the name of ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Clicking the \"x\" on the left a bell number will unassign the ringer from that bell.

Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. This will also make a large dedicated button for each assigned bell at the bottom. If a user is assigned to multiple bells, the lowest-numbered one will be placed in the bottom right position.

There is also a button called 'Fill in'. This will randomly assign unassigned ringers to availible bells, if there are enough free ringers.
"""
    
    static let managingTowers = """
The Towers tab shows all the towers associated with your account. They are sorted by last visited, with the most recent at the bottom.

In a later version, you will be able to view separate lists for bookmarked towers, created towers and host towers, and change the settings for the towers you created.
"""
    
    static let hostMode = """
Host Mode is a special mode that can be enabled for towers in order to restrict who can direct the ringing at that tower. To enable Host Mode, you will need to go to the Tower Settings page on the ringingroom.com website and set the \"Permit Host Mode\" feature to \"Yes\".

A tower host is someone who has special privileges at a Ringing Room virtual tower. You can think of this as being like a tower captain or a ringing master: A host is someone who might take charge of a practice. A tower can have multiple hosts who can share responsibility for running practices. You can add hosts to towers that you have created by going to the My Towers page on the ringingroom.com website, finding the tower you want, clicking the Settings button, and entering the email address of the Ringing Room account you want to add as a host in the box at the bottom left. You can remove hosts from a tower by clicking the \"X\" icon in the list of tower hosts. The creator of a tower is always a host there.

If Host Mode is permitted at a tower, hosts have an extra switch in the tower controls, allowing them to enable or disable Host Mode. When a tower is in Host Mode, various restrictions are imposed:
    • Only hosts may change the number of bells or switch between handbell and towerbell mode.
    • Non-hosts may only make calls when assigned to a bell.
    • Non-hosts may only ring bells that they are assigned to.
    • Only hosts may assign other ringers to bells.
    • Non-hosts may assign themselves to open bells only — that is, they can \"catch hold\" of unused bells, but not displace other ringers.

Host mode can only be activated or deactivated by any hosts currently in the tower through the website. If there are no hosts present, host mode will automatically be disabled so that ringing can proceed normally.
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
                NavigationLink("Creating or joining a tower", destination: CreatingOrJoiningATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Ringing the Bells", destination: RingingTheBellsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Making calls", destination: MakingCallsView(asSheet: self.asSheet, isPresented: self.$isPresented))
                NavigationLink("Leaving a tower", destination: LeavingATowerView(asSheet: self.asSheet, isPresented: self.$isPresented))
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
                Text(HelpDocumention.creatingAnAccount)
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
                Text(HelpDocumention.creatingOrJoiningATower)
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
                Text(HelpDocumention.ringingTheBells)
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
                Text(HelpDocumention.makingCalls)
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
            Text(HelpDocumention.leavingATower)
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
                    Text(HelpDocumention.creatingAnAccount)
                }
                Group {
                    Text("\n\nCreating or joining a tower\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumention.creatingOrJoiningATower)
                }
                Group {
                    Text("\n\nRinging the bells\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumention.ringingTheBells)
                }
                Group {
                    Text("\n\nMaking calls\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumention.makingCalls)
                }
                Group {
                    Text("\n\nLeaving a tower\n")
                        .font(.headline)
                        .bold()
                    Text(HelpDocumention.leavingATower)
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
                Text(HelpDocumention.assinging)
            }
            Group {
                Text("\n\nManaging towers\n")
                .font(.headline)
                .bold()
                Text(HelpDocumention.managingTowers)
            }
            Group {
                Text("\n\nHost and host mode\n")
                .font(.headline)
                .bold()
                Text(HelpDocumention.hostMode)
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
                Text(HelpDocumention.assinging)
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

struct ManagingTowersView:View {
    var asSheet:Bool
    
    @Binding var isPresented:Bool
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(HelpDocumention.managingTowers)
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
                Text(HelpDocumention.hostMode )
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

