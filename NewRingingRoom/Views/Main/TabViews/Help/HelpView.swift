//
//  HelpView.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI
import Combine
import MessageUI


struct FAQ: Identifiable {
    
    var question: String
    var answer: String
    
    let id = UUID()
    
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
    
    static var FAQs = [
        FAQ(
            question: "I can't hear any audio",
            answer: "Make sure your volume is up. If are using Zoom on the same device and still can't hear any audio, this might be because you joined the Zoom call before opening Ringing Room. Make sure you have Ringing Room open, then leave your Zoom call and rejoin it. Now you should be able to hear Ringing Room and Zoom clearly. If you are not using using Zoom, and still can't hear any audio, then please restart the app."
        ),
        FAQ(
            question: "How can I stop notifications while I'm ringing?",
            answer: "Turn on Do Not Disturb. This is a system setting that will silence your notifications. You can find this setting in two places: the settings app, and Control Centre. To find it in the setting app, go to settings, then swipe down to reveal the search bar. Tap it, and enter 'Do not disturb'. Tap on the first result. Then, turn on the Do Not Disturb toggle. Alternatively, you can find the setting in Control Centre. To get to Control Centre, swipe down from the top-right corner of the screen, or swipe up from the bottom if you are using an iPhone without a notch. Next, press the button with the crescent moon icon. If the moon turns purple, with a white background, then Do Not Disturb is on. Remember to turn it off again once you have finished ringing."
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
        .conditionalDismiss(shouldDisplay: isInSheet)
        .padding()
        .navigationBarTitle(helpSection.title, displayMode: .inline)
    }
}

extension Text {
    init(_ faq: FAQ) {
        self = Text(faq.question).bold()
        self = self + Text("\n\n\(faq.answer)\n")
    }
}

private struct IsInSheetKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isInSheet: Bool {
        get { self[IsInSheetKey.self] }
        set { self[IsInSheetKey.self] = newValue }
    }
}

extension View {
    func isInSheet(_ isInSheet: Bool) -> some View {
        environment(\.isInSheet, isInSheet)
    }
}

struct ConditionalDismissModifier: ViewModifier {
    var shouldDisplay: Bool
    
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if shouldDisplay {
                        Button {
                            dismiss()
                        } label: {
                            Text("Dismiss")
                        }
                    }
                }
            }
    }
}

extension View {
    
    func conditionalDismiss(shouldDisplay: Bool) -> some View {
        self
            .modifier(ConditionalDismissModifier(shouldDisplay: shouldDisplay))
    }
}

struct HelpView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    var body: some View {
        NavigationView {
            MasterHelpView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MasterHelpView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Quick Start Guide", destination: QuickStartGuideView())
                NavigationLink("Advanced Features", destination: AdvancedFeaturesView())
                NavigationLink("FAQs",  destination: FAQsView())
            }
            Section {
                NavigationLink("Full help document", destination: HelpTextView())
            }
        }
        .conditionalDismiss(shouldDisplay: isInSheet)
        .navigationBarTitle("Help")
    }
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
        .conditionalDismiss(shouldDisplay: isInSheet)
        .navigationBarTitle("FAQs", displayMode: .inline)
    }
}

struct QuickStartGuideView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    
    
    var body: some View {
        Form {
            Section {
                ForEach(QuickStartGuideHelpSection.allCases) { helpSection in
                    NavigationLink(helpSection.title, destination: HelpSectionView(helpSection: helpSection))
                }
            }
            Section {
                NavigationLink("Full Quick Start Guide", destination: ScrollView {
                    QuickStartGuideTextView()
                }
                    .conditionalDismiss(shouldDisplay: isInSheet)
                )
            }
        }
        .conditionalDismiss(shouldDisplay: isInSheet)
        .navigationBarTitle("Quick Start Guide", displayMode: .inline)
    }
}

struct QuickStartGuideTextView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(QuickStartGuideHelpSection.allCases) { helpSection in
                Text("\n\n\(helpSection.title)\n")
                    .font(.headline)
                    .bold()
                
                Text(helpSection.helpText)
            }
        }
        .padding()
    }
}

struct AdvancedFeaturesView: View {
    @Environment(\.isInSheet) var isInSheet: Bool

    var body: some View {
        Form {
            Section {
                ForEach(AdvancedFeaturesHelpSection.allCases) { helpSection in
                    NavigationLink(helpSection.title, destination: HelpSectionView(helpSection: helpSection))
                }
            }
            
            Section {
                NavigationLink("Full Advanced Features", destination: ScrollView {
                    AdvancedFeaturesTextView()
                }
                    .conditionalDismiss(shouldDisplay: isInSheet)
                )
            }
        }
        .navigationBarTitle("Advanced Features", displayMode: .inline)
        .conditionalDismiss(shouldDisplay: isInSheet)
    }
}

struct AdvancedFeaturesTextView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(AdvancedFeaturesHelpSection.allCases) { helpSection in
                Text("\n\n\(helpSection.title)\n")
                    .font(.headline)
                    .bold()
                
                Text(helpSection.helpText)
            }
        }
        .padding()
    }
}

struct HelpTextView: View {
    @Environment(\.isInSheet) var isInSheet: Bool
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0)    {
                Text("Quick Start Guide")
                    .font(.title)
                    .bold()
                
                QuickStartGuideTextView()
                
                Text("\nAdvanced Features")
                    .font(.title)
                    .bold()
                
                AdvancedFeaturesTextView()
            }
            .padding(.vertical)
        }
        .conditionalDismiss(shouldDisplay: isInSheet)
        .navigationBarTitle("Help", displayMode: .inline)
    }
}

