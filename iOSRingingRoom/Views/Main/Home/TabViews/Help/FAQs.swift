//
//  FAQs.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

struct FAQ: Identifiable {
    
    var question: LocalizedStringKey
    var answer: LocalizedStringKey
    
    let id = UUID()
    
    init(question: LocalizedStringKey, answer: LocalizedStringKey) {
        self.question = question
        self.answer = answer
    }
    
    static var FAQs = [
        FAQ(
            question: "I can't hear any audio",
            answer: "Make sure your volume is up. Ringing room also has it's own volume slider in tower controls. If are using Zoom on the same device and still can't hear any audio, this might be because you joined the Zoom call before opening Ringing Room. Make sure you have Ringing Room open, then leave your Zoom call and rejoin it. Now you should be able to hear Ringing Room and Zoom clearly. If you are not using using Zoom, and still can't hear any audio, then please restart the app."
        ),
        FAQ(
            question: "How can I stop notifications while I'm ringing?",
            answer: "Turn on Do Not Disturb. This is a system setting that will silence your notifications. You can find this setting in Control Centre. To get to Control Centre, swipe down from the top-right corner of the screen, or swipe up from the bottom if you are using an iPhone without a notch or dynamic island. Next, tap the button with the crescent moon icon. If the moon turns purple with a white background, then Do Not Disturb is on. Remember to turn it off again once you have finished ringing. For further help about Do Not Disturb, see [Apple's help page](https://support.apple.com/en-gb/105112)"
        ),
        FAQ(
            question: "My device keeps turning off",
            answer: "To stop your device going to sleep between rings because you don't touch the screen for a while, perhaps while chatting on Zoom or sitting out of a touch, you can set the Auto-Lock duration to Never. The Auto-Lock setting is in the Display & Brightness section of the Settings app."
        ),
        FAQ(
            question: "How can I control Wheatley?",
            answer: "There is no Wheatley control in the app at present. That feature will be added soon. For now, join the tower through ringingroom.com to control Wheatley."
        )
    ]
}

struct FAQsView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(FAQ.FAQs) { faq in
                    Text(faq)
                }
            }
            .padding()
        }
        .conditionalDismissToolbarButton()
        .navigationBarTitle("FAQs", displayMode: .inline)
    }
}

extension Text {
    init(_ faq: FAQ) {
        self = Text(faq.question).bold()
        self = self + Text("\n\n")
        self = self + Text(faq.answer)
        self = self + Text("\n")
    }
}
