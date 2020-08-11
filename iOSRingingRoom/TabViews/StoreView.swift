//
//  StoreView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct StoreView: View {
    
    var body: some View {
        NavigationView {
            WebView(request: URLRequest(url: URL(string: "https://www.redbubble.com/people/ringingroom/shop?asc=u")!))
                .navigationBarTitle("Store", displayMode: .inline)
        }
    }
}

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
    }
}
