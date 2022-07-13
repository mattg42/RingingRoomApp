//
//  HelpView.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI
import Combine

struct HelpView: View {
    
    let asSheet: Bool
    
    var body: some View {
        NavigationView {
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
            .navigationBarTitle("Help")
            .conditionalDismiss(shouldDisplay: asSheet)
            .isInSheet(asSheet)
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
