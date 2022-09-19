//
//  QuickStartGuide.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

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
                    .conditionalDismissToolbarButton()
                )
            }
        }
        .conditionalDismissToolbarButton()
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
