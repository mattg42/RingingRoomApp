//
//  HelpSection.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

protocol HelpSection {
    var title: String { get }
    var helpText: String { get }
}

enum QuickStartGuideHelpSection: CaseIterable, HelpSection, Identifiable {
    var id: Self { self }
    
    case accountSettings
    case creatingOrJoiningATower
    case ringingTheBells
    case makingCalls
    case leavingATower
    case volume
    
    var title: String {
        switch self {
        case .accountSettings:
            return "Changing account settings"
        case .creatingOrJoiningATower:
            return "Joining or creating a tower"
        case .ringingTheBells:
            return "Ringing the bells"
        case .makingCalls:
            return "Making calls"
        case .leavingATower:
            return "Leaving a tower"
        case .volume:
            return "Reducing the volume"
        }
    }
    
    var helpText: String {
        switch self {
        case .accountSettings:
            return """
To change your account settings such as email or password, you need to login to the ringingroom.com website on your device or computer and change the settings there. Account settings will be added to the app in a later update.
"""
"""
To change your account settings, go to the account tab. There you will find buttons to change your username, email, password, and to delete your account. To change a particular setting, tap on the relevant 'change' button. This will bring up a form. Follow the instructions on the form to change the setting.
"""
        case .creatingOrJoiningATower:
            return """
If you have visited a tower before, then you can join it by tapping on its name in the list of recent towers.
If you are joining a tower for the first time, then, in the towers tab, tap 'Join tower by ID'. Type in the ID of the tower you wish to join, and tap join.

To create a tower, go to the Towers view and tap on 'Create new tower' to reveal a text box and the Create Tower button. Next, type the name of the new tower into the text box. Press Create Tower and you will be sent to a new tower with that name.
"""
        case .ringingTheBells:
            return """
Once you're in a tower, you can ring the bells by tapping on their images. If you are assigned a bell, a button for that bell will appear near the bottom of your screen.

You may wish to change the number of bells in the tower, whether you are ringing tower bells or handbells. This can be achieved by selecting the desired option in the Tower Controls. You can access the Tower Controls by tapping the 3-line button at the top-right of the Ringing view, then tapping Settings. To view a list of ringers in the tower and assign them to bells, tap Users instead of Settings; this is covered in the Advanced Features section.
"""
        case .makingCalls:
            return """
You can make calls by tapping the desired call button below the bell circle. This will display the call in large text, and play a sound of somebody making the call.
"""
        case .leavingATower:
            return """
To leave the tower, tap the 3-line button at the top-right of the Ringing view, then tap Leave tower. Pressing this will remove you from the tower and bring you back to the Towers view.
"""
        case .volume:
            return """
Ringing Room has a volume slider that lets you reduce the volume of the bells without affecting the system volume. This is useful if you are using Ringing Room and Zoom (or other apps such as Discord) at the same time on your device - you can lower the volume of the bells, without making peoples' voices quieter.

To access the volume slider, you must be in a tower. Once in a tower, go to the tower controls. The volume slider will be near the top of the screen, with loudspeaker icons either side. Slide it to the right to increase the volume, and left to decrease the volume.
"""
        }
    }
}

enum AdvancedFeaturesHelpSection: CaseIterable, HelpSection, Identifiable {
    var id: Self { self }
    
    case tips
    case assigning
    case wheatley
    case rotating
    case managingTowers
    case hostMode
    
    var title: String {
        switch self {
        case .tips:
            return "Tips"
        case .assigning:
            return "Assigning Ringers to Bells"
        case .wheatley:
            return "Wheatley"
        case .rotating:
            return "Rotating your Perspective of the Bell Circle"
        case .managingTowers:
            return "Managing Your Towers"
        case .hostMode:
            return "Host Mode"
        }
    }
    
    var helpText: String {
        switch self {
        case .tips:
            return """
To prevent notifications from silencing the audio and distracting you while ringing, it's a good idea to switch on "Do Not Disturb" before a ringing session. This setting can be found in the Control Centre (it has a crescent moon icon), or search the Settings app to find it. Remember to turn it off again after ringing if you want to see and hear notifications.
"""
        case .assigning:
            return """
The tower controls includes a list of users presently in the tower, which you can use to assign bells to particular ringers. To assign ringers, tap on the name of the ringer you would like to assign, then tap on the number of the bell you would like to assign them to. To unassign them, swipe their name to the left. There is also an Un-assign All button, which un-assigns every ringer.

Assigning a user to a bell will have the effect of automatically rotating that ringer's \"perspective\" on the tower so that the bell is placed in the bottom right position. There is more about changing your perspective in the section "Rotating the perspective of the bell circle". For every bell you are assigned to, there will be a large button for ringing that bell.

There is also a button called 'Fill In'. This will randomly assign unassigned ringers to available bells. The Fill In button is only enabled if there are at least as many unassigned ringers as available bells. If Wheatley is in the tower, then Fill In will randomly assign all human ringers a bell, then fill in the rest with Wheatley.
"""
        case .wheatley:
            return """
Wheatley is a computer ringer for Ringing Room, made by Ben White-Horne and Matthew Johnson and designed to be a 'ninja helper with no ego' - i.e. Wheatley will ring any number of bells to whatever you want to ring, but should fit in as much as possible to what you're ringing. Wheatley is now available directly inside Ringing Room, without any installation.

Enabling Wheatley
Wheatley needs to be enabled on a per-tower basis with the switch in the tower settings. This can only be done through the website currently. Once Wheatley is enabled, a user called 'Wheatley' will be present in the users list. You can then assign Wheatley to bells like any other person. The Fill In button will randomly assign all human ringers first, then fill the remaining bells with Wheatley.

To tell Wheatley what to ring, you need to join the tower through the website. The control for Wheatley in the app is coming soon.

To start ringing a method with Wheatley (only on the website):
Click on the "Methods" tab in the Wheatley box.
Click in the text box that says "Start typing method name".
Start typing the name of the method you want to ring. As you type, a list of potential method names will appear (filtered according to the tower size).
Click on the method name you want to ring, or click "Enter" to select the first option.
If everything worked out, the first line of the Wheatley box should say "After 'Look To', Wheatley will ring <your method name>", and Wheatley will ring that method after Look To is called.

Wheatley will still respond to all yours calls from the app, such as Look to, or Stand.
"""
        case .rotating:
            return """
By default, whenever you are assigned a bell, that bell will appear in the bottom right corner of the bell circle. However, if you would like to have control over your perspective of the bell circle, tap the 'Change perspective' button in the tower controls. This will take you back to the ringing view in Rotate mode. In Rotate mode, when you tap a bell, instead of it ringing, it will change your perspective so that bell will be in the bottom right corner, and you will exit Rotate mode. To cancel Rotate mode without changing the perspective, tap 'Cancel' in the top right of the screen.

In addition, in the Controls tab there is an option to disable the automatic rotation of the bell circle when you are assigned a bell.
"""
        case .managingTowers:
            return """
The Towers tab shows all the towers associated with your account. They are sorted by last visited, with the most recent at the top.

In a later version, you will be able to view separate lists for recent, bookmarked, created and host towers, and be able to change the settings for the towers you have created.
"""
        case .hostMode:
            return """
Host Mode is a special mode that can be enabled for towers in order to restrict who can direct the ringing at that tower. To enable Host Mode, you will need to go to the Tower Settings page on the ringingroom.com website and set the \"Permit Host Mode\" feature to \"Yes\". Once Host Mode is enabled, you can turn it on in the app in a tower using a new toggle that will appear in the tower controls if you are a host.

A tower host is someone who has special privileges at a Ringing Room virtual tower. You can think of this as being like a tower captain or a ringing master: A host is someone who might take charge of a practice. A tower can have multiple hosts who can share responsibility for running practices. You can add hosts to towers that you have created by going to the My Towers page on the ringingroom.com website, finding the tower you want, clicking the Settings button, and entering the email address of the Ringing Room account you want to add as a host in the box at the bottom left. You can remove hosts from a tower by clicking the \"X\" icon in the list of tower hosts. The creator of a tower is always a host there.

If Host Mode is permitted at a tower, hosts have an extra switch in the tower controls, allowing them to enable or disable Host Mode. When a tower is in Host Mode, various restrictions are imposed:
    • Only hosts may change the number of bells or switch between handbell and tower-bell mode.
    • Non-hosts may only make calls when assigned to a bell.
    • Non-hosts may only ring bells that they are assigned to.
    • Only hosts may assign other ringers to bells.
    • Non-hosts may assign themselves to open bells only — that is, they can \"catch hold\" of unused bells, but not displace other ringers.

Host mode can only be activated or deactivated by any hosts currently in the tower. If there are no hosts present in the tower, host mode will automatically be disabled so that ringing can proceed normally.
"""
        }
    }
}

struct HelpSectionView: View {
    
    let helpSection: HelpSection
    
    @Environment(\.isInSheet) var isInSheet: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(helpSection.helpText)
                Spacer()
            }
        }
        .conditionalDismissToolbarButton()
        .padding()
        .navigationBarTitle(helpSection.title, displayMode: .inline)
    }
}
