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
                NavigationLink("Computing set-up", destination: ComputingSetUpView(asSheet: self.asSheet, isPresented: self.$isPresented))
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
                Text("Alternatively, if you use an iPhone, you can download the free Ringing Room app from the App Store")
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
                Text("Creating a tower on Ringing Room is simple. Go to the ring tab and type your desired name into the box at the bottom of the page. Once you press enter, you will be sent to a tower with that name. Each tower comes with a unique 9-digit ID which can be shared to allow others into that same tower.")
                Text("To join a tower, you must be equipped with its 9-digit ID number, which can then be typed or copied into the box at the bottom of the ring tab.")
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
                Text("You may wish to change the number of bells in the tower, or whether you are in ringing tower bells or handbells. This can be achieved by selecting the desired option in the tower controls. You can access the tower controls by clicking on the 3-lined black menu button in the top-right. Also available in the tower controls are a list of users. You will also be able to assign ringers to bells; this will be covered in the Advanced Features section.")
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
                    Text("Alternatively, if you use an iPhone, you can download the free Ringing Room app from the App Store.")
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
                    Text("Creating a tower on Ringing Room is simple. Go to the ring tab and type your desired name into the box at the bottom of the page. Once you press enter, you will be sent to a tower with that name. Each tower comes with a unique 9-digit ID which can be shared to allow others into that same tower.")
                    Text("To join a tower, you must be equipped with its 9-digit ID number, which can then be typed or copied into the box at the bottom of the ring tab.")
                }
                Group {
                    Text("Ringing the bells")
                        .font(.headline)
                        .bold()
                    Text("Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear at the bottom of your screen.")
                    Text("You may wish to change the number of bells in the tower, or whether you are in ringing tower bells or handbells. This can be achieved by selecting the desired option in the tower controls. You can access the tower controls by clicking on the 3-lined black menu button in the top-right. Also available in the tower controls are a list of users. You will also be able to assign ringers to bells; this will be covered in the Advanced Features section.")
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
        VStack(alignment: .leading, spacing: 10) {
            Group {
                Text("Assigning Ringers")
                .font(.headline)
                .bold()
                Text("The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Clicking the \"x\" by a bell number will unassign the ringer from that bell.")
                Text("Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. This will allow it to be rung using large dedicated button at the bottom. If a user is assigned to multiple bells, the lowest-numbered one will be placed in the bottom right position.")
                Text("There is also a button called 'Fill in'. This will randomly assign users to fill the bell circle if there are enough users.")
            }
            Group {
                Text("Managing towers")
                .font(.headline)
                .bold()
                Text("The Ring tab shows all the towers associated with your account. Managing your towers and sorting by bookmarked, created etc. will be coming in a later version.")
            }
            Group {
                Text("Host and host mode")
                .font(.headline)
                .bold()
                Text("Host Mode is a special mode that can be enabled for towers in order to restrict who can direct the ringing at that tower. To enable Host Mode, you will need to go to the Tower Settings page on the ringingroom.com website and set the \"Permit Host Mode\" feature to \"Yes\".")
                Text("A tower host is someone who has special privileges at a Ringing Room virtual tower. You can think of this as being like a tower captain or a ringing master: A host is someone who might take charge of a practice. A tower can have multiple hosts who can share responsibility for running practices. You can add hosts to towers that you have created by going to the My Towers page on the ringingroom.com website, finding the tower you want, clicking the Settings button, and entering the email address of the Ringing Room account you want to add as a host in the box at the bottom left. You can remove hosts from a tower by clicking the \"X\" icon in the list of tower hosts. The creator of a tower is always a host there.")
                Text("If Host Mode is permitted at a tower, hosts have an extra switch in the tower controls, allowing them to enable or disable Host Mode. When a tower is in Host Mode, various restrictions are imposed:")
                VStack(alignment: .leading) {
                        bulletLine(text: "Non-hosts may not change the number of bells or switch between handbell and towerbell mode.")
                        bulletLine(text: "Non-hosts may only make calls when assigned to a bell")
                        bulletLine(text: "All ringers may only ring bells that they are assigned to.")
                        bulletLine(text: "Only hosts may assign other ringers to bells.")
                        bulletLine(text: "Non-hosts may assign themselves to open bells only — that is, they can \"catch hold\" of unused bells, but not displace other ringers.")
                }
                Text("Host mode can be activated or deactivated by any hosts currently in the tower. If there are no hosts present, host mode will automatically be disabled so that ringing can proceed normally.")
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
            
            VStack(alignment: .leading, spacing: 10) {
                Text("The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. Clicking the \"x\" by a bell number will unassign the ringer from that bell.")
                Text("Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. This will allow it to be rung using large dedicated button at the bottom. If a user is assigned to multiple bells, the lowest-numbered one will be placed in the bottom right position.")
                Text("There is also a button called 'Fill in'. This will randomly assign users to fill the bell circle if there are enough users.")
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
                Text("The Ring tab shows all the towers associated with your account. Managing your towers and sorting by bookmarked, created etc. will be coming in a later version.")
//                VStack(alignment: .leading) {
//                    bulletLine(text: "Recent: shows a reverse-chronological list of towers that you have visited.")
//                    bulletLine(text: "Favourite: shows a list of all towers that you have specifically bookmarked.")
//                    bulletLine(text: "Created:  shows a list of all towers that you have created.")
//                    bulletLine(text: "Host: shows a list of towers at which you are a host (see below).")
//                }
//                Text("On any tower you can press the bookmark icon to add or remove the tower from your list of bookmarked towers. If you are the tower's creator, you can click the Settings button to access the Tower Settings page, where you can change the tower name, enable Host Mode and add or remove hosts (see below), or permanently delete the tower. If you long/hard press on any of the towers, you will see an option to copy the tower ID to your clipboard, and in the recents tab only there will also be an option to remove the tower from your recents.")

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
                Text("Host Mode is a special mode that can be enabled for towers in order to restrict who can direct the ringing at that tower. To enable Host Mode, you will need to go to the Tower Settings page on the ringingroom.com website and set the \"Permit Host Mode\" feature to \"Yes\".")
                Text("A tower host is someone who has special privileges at a Ringing Room virtual tower. You can think of this as being like a tower captain or a ringing master: A host is someone who might take charge of a practice. A tower can have multiple hosts who can share responsibility for running practices. You can add hosts to towers that you have created by going to the My Towers page on the ringingroom.com website, finding the tower you want, clicking the Settings button, and entering the email address of the Ringing Room account you want to add as a host in the box at the bottom left. You can remove hosts from a tower by clicking the \"X\" icon in the list of tower hosts. The creator of a tower is always a host there.")
                Text("If Host Mode is permitted at a tower, hosts have an extra switch in the tower controls, allowing them to enable or disable Host Mode. When a tower is in Host Mode, various restrictions are imposed:")
                VStack(alignment: .leading) {
                    bulletLine(text: "Non-hosts may not change the number of bells or switch between handbell and towerbell mode.")
                    bulletLine(text: "Non-hosts may only make calls when assigned to a bell")
                    bulletLine(text: "All ringers may only ring bells that they are assigned to.")
                    bulletLine(text: "Only hosts may assign other ringers to bells.")
                    bulletLine(text: "Non-hosts may assign themselves to open bells only — that is, they can \"catch hold\" of unused bells, but not displace other ringers.")
                }
                Text("Host mode can be activated or deactivated by any hosts currently in the tower. If there are no hosts present, host mode will automatically be disabled so that ringing can proceed normally.")
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
            VStack {
                Text("Quick Start Guide")
                    .font(.title)
                    .bold()
                QuickStartGuideTextView(asSheet: self.asSheet, isPresented: self.$isPresented)
                Text("Advanced Features")
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

