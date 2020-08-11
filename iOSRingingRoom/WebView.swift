//
//  WebView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 10/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView : UIViewRepresentable {
    
    let request: URLRequest
    
    func makeUIView(context: Context) -> WKWebView  {
        let webView = WKWebView()
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.alwaysBounceHorizontal = false
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(request)
        uiView.scrollView.bounces = false
        uiView.scrollView.showsHorizontalScrollIndicator = false
        uiView.scrollView.alwaysBounceHorizontal = false
    }
}
