//
//  AdvancedFeatures.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

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
                    .conditionalDismissToolbarButton()
                )
            }
        }
        .navigationBarTitle("Advanced Features", displayMode: .inline)
        .conditionalDismissToolbarButton()
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
