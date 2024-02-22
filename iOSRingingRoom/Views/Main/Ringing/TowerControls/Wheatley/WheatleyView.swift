//
//  WheatleyView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import Foundation
import SwiftUI

struct WheatleyView: View {
    @EnvironmentObject var wheatleyState: WheatleyState
    
    @State var hours = 2
    @State var minutes = 30
    
    var wheatleyText: LocalizedStringKey {
        // Needs to be split up to get the markdown link working
        let urlString = "After 'Look To', Wheatley will ring [\(wheatleyState.rowGen.title)](https://rsw.me.uk/blueline/methods/view/\(wheatleyState.rowGen.url))."
        return LocalizedStringKey(urlString)
    }
    
    var body: some View {
        Form {
            Section {
                Text(wheatleyText)
                    .tint(.main)
                NavigationLink("Change method") {
                    WheatleySearchView()
                }
            }
            
            Section(header: Text("Peal Speed")) {
                HStack(spacing: 0) {
//                    Stepper("Hours", value: $a, in: 1...5)
                    Stepper(value: Binding(get: {
                        return hours
                    }, set: { newValue in
                        if newValue == 8 {
                            minutes = 0
                        }
                        hours = newValue
                    }), in: 1...8, step: 1) {
                        Text("\(hours) hrs")
                    }
                    .fixedSize()
                    Spacer()
                    Stepper(value: Binding(get: {
                        return minutes
                    }, set: { newValue in
                        if newValue == -5 {
                            if hours > 1 {
                                hours -= 1
                                minutes = 55
                            } else {
                                minutes = 0
                            }
                        } else if newValue == 60 {
                            if hours < 8 {
                                hours += 1
                                minutes = 0
                            }
                        } else {
                            if hours == 8 {
                                minutes = 0
                            } else {
                                minutes = newValue
                            }
                        }
                    }), in: -5...60, step: 5) {
                        HStack {
                            Spacer()
                            
                            Text("\(minutes) min")
                                .lineLimit(1)
                        }
                    }
                }
                Toggle("Fixed striking interval", isOn: .constant(false))
                
            }
            
            Section {
                Toggle("Whole pull and off", isOn: .constant(false))
                Toggle("Stop at rounds", isOn: .constant(false))
            }
            
            Section {
                Button("Reset Wheatley", role: .destructive) {}
            }
        }
    }
}
