//
//  bulletLine.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct bulletLine: View {
    var text:String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("• ")
            Text(text)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 15)
    }
}

struct bulletLine_Previews: PreviewProvider {
    static var previews: some View {
        bulletLine(text: "test")
    }
}
