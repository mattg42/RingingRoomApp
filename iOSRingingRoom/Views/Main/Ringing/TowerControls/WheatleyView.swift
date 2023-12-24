//
//  WheatleyView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import Foundation
import SwiftUI

struct WheatleyView: View {
    
    @State var a = 2
    @State var b = 30
    
    var body: some View {
        Form {
            Section {
                Text("After 'Look To', Wheatley will ring [Plain Bob Major](https://rsw.me.uk/blueline/methods/view/Plain_Bob_Major).")
                    .tint(.main)
                NavigationLink("Change method") {
                    WheatleySearchView()
                }
            }
            
            Section(header: Text("Peal Speed")) {
                HStack(spacing: 0) {
//                    Stepper("Hours", value: $a, in: 1...5)
                    Stepper(value: $a, in: 1...5, step: 1) {
                        Text("\(a) hrs")
                    }
                    .fixedSize()
                    Spacer()
                    Stepper(value: $b, in: 0...60, step: 5) {
                        HStack {
                            Spacer()
                            
                            Text("\(b) min")
                                .lineLimit(1)
                        }
                    }
//                    Stepper("Min", value: .constant(0), in: 0...60, step: 5)

//                    Picker("Hours", selection: .constant(0)) {
//                        ForEach(1..<6) { num in
//                            Text(String(num))
//                                .tag(num)
//                        }
//                    }
//                    .pickerStyle(WheelPickerStyle())
//                    
//                    Picker("Minutes", selection: .constant(0)) {
//                        ForEach(0..<13) { num in
//                            Text(String(num*5))
//                                .tag(num*5)
//                        }
//                    }
//                    .pickerStyle(WheelPickerStyle())
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
