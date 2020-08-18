//
//  WebView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 10/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import WebKit

struct Webview: UIViewControllerRepresentable {
    let url: URL

    var webviewController:WebviewController?
    
    init(web: WKWebView?, url: URL) {
        self.webviewController = WebviewController()
        self.url = url
    }
    
    func makeUIViewController(context: Context) -> WebviewController {
        return webviewController!
    }

    func updateUIViewController(_ webviewController: WebviewController, context: Context) {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webviewController.webview.load(request)
    }
    
    func goBack() {
        webviewController?.back()
    }
    
    func goForward() {
        webviewController?.forward()
    }
    
}

class WebviewController: UIViewController, UIScrollViewDelegate {
    lazy var webview: WKWebView = WKWebView()
    lazy var progressbar: UIProgressView = UIProgressView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webview.frame = self.view.frame
        self.view.addSubview(self.webview)

        self.view.addSubview(self.progressbar)
        self.progressbar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([
            self.progressbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.progressbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.progressbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])

        webview.scrollView.delegate = self
        webview.scrollView.showsHorizontalScrollIndicator = false
        webview.scrollView.bounces = false
                        
        self.progressbar.progress = 0.1
        webview.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    func back() {
        if (self.webview.canGoBack) {
            self.webview.goBack()
        }
    }

    func forward() {
        if (self.webview.canGoForward) {
            self.webview.goForward()
        }
    }
    
    // MARK: - Web view progress
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "estimatedProgress":
            if self.webview.estimatedProgress >= 1.0 {
                progressbar.setProgress(Float(self.webview.estimatedProgress), animated: true)
                UIView.animate(withDuration: 0.3, animations: { () in
                    self.progressbar.alpha = 0.0
                }, completion: { finished in
                    self.progressbar.setProgress(0.0, animated: false)
                })
            } else {
                self.progressbar.isHidden = false
                self.progressbar.alpha = 1.0
                progressbar.setProgress(Float(self.webview.estimatedProgress), animated: true)
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
    }
}
