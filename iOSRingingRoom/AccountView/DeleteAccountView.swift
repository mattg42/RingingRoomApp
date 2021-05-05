//
//  DeleteAccountView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 13/04/2021.
//  Copyright © 2021 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct DeleteAccountView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var parent:AccountView
        
    @State var password = ""
    @State var correctPassword = true
        
    @State var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter your password to confirm"), footer: Text("Incorrect Password").foregroundColor(.red).opacity(correctPassword ? 0 : 1).animation(.default)) {
                    SecureField("Password", text: $password) {
                        correctPassword = password == User.shared.password || password == ""
                    }
                        .textContentType(.password)
                        .autocapitalization(.none)
                    .onChange(of: password, perform: { value in
                        correctPassword = true
                    })
                }
            
                Section {
                    Button("Delete account") {
                        showingAlert = true
                    }
                    .disabled(password != User.shared.password)
                }
            }
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text("Delete account"), message: Text("Are you sure you want to delete your account? This will permanently delete all your data."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete"), action: makeChange))
            })
            .navigationBarTitle("Delete account", displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(.main)
    }
    
    func makeChange() {
//        parent.comController.deleteAccount()
        presentationMode.wrappedValue.dismiss()
    }
}

