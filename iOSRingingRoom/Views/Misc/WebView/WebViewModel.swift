//
//  ViewModel.swift
//  SwiftUIWebTest
//
//  Created by Matthew on 27/03/2021.
//

import Foundation
import Combine
import WebKit

import SwiftUI

@MainActor
class WebViewModel: ObservableObject {
    var estimatedProgress: Double = 0.0 {
        didSet {
            if estimatedProgress >= 1.0 {
                withAnimation(.linear(duration: 0.3)) {
                    progress = 1
                }
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard let self else { return }
                    withAnimation(.linear(duration: 0.2)) {
                        self.alpha = 0.0
                    }
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    self.progress = 0
                }
            } else {
                alpha = 1.0
                withAnimation {
                    progress = estimatedProgress
                }
            }
        }
    }
    @Published var link : String
    
    var webViewNavigationPublisher = PassthroughSubject<WebViewNavigation, Never>()
    
    init (progress: Double, link : String) {
        self.progress = progress
        self.link = link
    }
    
    @Published var progress = 0.0
    @Published var alpha = 1.0
    
    
    func goForward() {
        webViewNavigationPublisher.send(.forward)
    }
    
    func goBack() {
        webViewNavigationPublisher.send(.backward)
    }
}

enum WebViewNavigation {
    case forward, backward
}
