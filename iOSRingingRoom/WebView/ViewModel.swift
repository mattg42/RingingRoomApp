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

class WebViewModel: ObservableObject {
    var estimatedProgress: Double = 0.0 {
        didSet {
            DispatchQueue.main.async { [self] in
                if estimatedProgress >= 1.0 {
                    withAnimation(.linear(duration:0.3)) {
                        self.progress = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: {
                        withAnimation(.linear(duration: 0.2)) {
                            alpha = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) { [weak self] in
                            self?.progress = 0
                        }
                    })
                    
                } else {
                    alpha = 1.0
                    withAnimation {
                        progress = estimatedProgress
                    }
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
