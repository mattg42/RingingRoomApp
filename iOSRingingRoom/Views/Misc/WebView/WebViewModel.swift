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
            DispatchQueue.main.async { [weak self] in
                if self?.estimatedProgress ?? 1 >= 1.0 {
                    withAnimation(.linear(duration: 0.3)) {
                        self?.progress = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
                        withAnimation(.linear(duration: 0.2)) {
                            self?.alpha = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                            self?.progress = 0
                        }
                    })
                    
                } else {
                    self?.alpha = 1.0
                    withAnimation {
                        self?.progress = self?.estimatedProgress ?? 1
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
