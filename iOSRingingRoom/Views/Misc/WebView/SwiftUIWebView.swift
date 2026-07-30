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
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.configure()
        context.coordinator.update(webView: context.coordinator.webView, link: viewModel.link)
        return context.coordinator.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.update(webView: uiView, link: viewModel.link)
    }
}

class Coordinator: NSObject, WKNavigationDelegate {
    
    let webView = WKWebView()
    private let viewModel: WebViewModel
    
    private var webViewNavigationSubscriber: AnyCancellable?
    private var estimatedProgressObserver: NSKeyValueObservation?
    private var lastRequestedURL: URL?
    
    init(viewModel: WebViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func configure() {
        webView.navigationDelegate = self

        guard estimatedProgressObserver == nil else { return }

        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            MainActor.assumeIsolated {
                AppLogger.ui.debug("Web view loading progress: \(Float(webView.estimatedProgress), privacy: .public)")
                guard let self else { return }

                self.viewModel.estimatedProgress = webView.estimatedProgress
            }
        }

        webViewNavigationSubscriber = viewModel.webViewNavigationPublisher.receive(on: RunLoop.main).sink { [weak self] navigation in
            guard let self else { return }

            switch navigation {
            case .backward:
                if self.webView.canGoBack {
                    self.webView.goBack()
                }
            case .forward:
                if self.webView.canGoForward {
                    self.webView.goForward()
                }
            }
        }
    }

    func update(webView: WKWebView, link: String) {
        guard let url = URL(string: link), url != lastRequestedURL else { return }

        lastRequestedURL = url
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }

        lastRequestedURL = url
        Task { @MainActor [weak self] in
            self?.viewModel.link = url.absoluteString
        }
    }

}
