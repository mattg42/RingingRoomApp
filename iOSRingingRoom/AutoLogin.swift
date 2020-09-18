//
//  AutoLogin.swift
//  iOSRingingRoom
//
//  Created by Matthew on 05/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AutoLogin: View {
    @State var showingAlert = false
    var body: some View {
        ZStack {
            Color.main
            .edgesIgnoringSafeArea(.all)
            HStack {
                Spacer(minLength: 55)
                Image("rrLogo").resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer(minLength: 55)
            }
            .padding(.top, -20)
        }
        .alert(isPresented: $showingAlert) {
        //present welcome login screen
            Alert(title: Text("Error"), message: Text("There was an error trying to log you in."), dismissButton: .cancel(Text("OK"), action: {
                self.viewControllerHolder?.present(style: .fullScreen, name: "", animated: false) {
                    WelcomeLoginScreen()
                }
            }))
        }
    }
}

struct AutoLogin_Previews: PreviewProvider {
    static var previews: some View {
        AutoLogin()
    }
}
