//
//  WebView.swift
//  SwiftUIWebTest
//
//  Created by Matthew on 27/03/2021.
//

import Foundation
import SwiftUI
import WebKit
import Combine

struct SwiftUIWebView: UIViewRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }
    
    let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        
        return self.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: viewModel.link) {
            self.webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad))
        }
    }
}

class Coordinator: NSObject, WKNavigationDelegate {
    
    private var viewModel: WebViewModel
    
    var webViewNavigationSubscriber: AnyCancellable? = nil
    
    var parent: SwiftUIWebView
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    init(_ parent: SwiftUIWebView, viewModel: WebViewModel) {
        self.parent = parent
        self.viewModel = viewModel
        super.init()
        
        estimatedProgressObserver = self.parent.webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            print(Float(webView.estimatedProgress))
            guard let weakSelf = self else{return}
            
            weakSelf.viewModel.estimatedProgress = webView.estimatedProgress
            
        }
        self.webViewNavigationSubscriber = self.parent.viewModel.webViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveValue: { navigation in
            switch navigation {
            case .backward:
                if parent.webView.canGoBack {
                    parent.webView.goBack()
                }
            case .forward:
                if parent.webView.canGoForward {
                    parent.webView.goForward()
                }
            }
        })
        
    }
    
    deinit {
        estimatedProgressObserver = nil
        webViewNavigationSubscriber?.cancel()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.link = webView.url?.absoluteString ?? ""
    }
    
}

