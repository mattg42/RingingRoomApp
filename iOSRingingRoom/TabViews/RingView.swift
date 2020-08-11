//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct RingView: View {
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    @State var tower_id = "254317968"
    var body: some View {
        VStack {
            TextField("Tower id", text: $tower_id)
            Button(action: joinTower) {
                Text("Join Tower")
            }
        }
    }
    
    func joinTower() {
        self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
            RingingRoomView(tower_id: tower_id)
        }
    }
}

struct RingView_Previews: PreviewProvider {
    static var previews: some View {
        RingView()
    }
}
