//
//  ErrorHandler.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation
import UIKit

protocol ErrorHandleable {
    func handle(error: Alertable)
}

public struct ErrorHandler: ErrorHandleable {
    private func presentAlert(title: String, message: String, dismiss: DissmissType) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        switch dismiss {
        case .cancel(let title, let action):
            ac.addAction(UIAlertAction(title: title, style: .cancel, handler: { _ in
                action?()
            }))
        case .retry(let action):
            ac.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                action()
            }))
        }
        UIApplication.shared.keyWindowPresentedController?.present(ac, animated: true, completion: nil)
    }
    
    func handle(error: Alertable) {
        presentAlert(title: error.errorAlert.title, message: error.errorAlert.message, dismiss: error.errorAlert.dissmiss)
    }
}

fileprivate extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
        // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
    var keyWindowPresentedController: UIViewController? {
        var viewController = self.keyWindow?.rootViewController
        
        // If root `UIViewController` is a `UITabBarController`
        if let presentedController = viewController as? UITabBarController {
            // Move to selected `UIViewController`
            viewController = presentedController.selectedViewController
        }
        
        // Go deeper to find the last presented `UIViewController`
        while let presentedController = viewController?.presentedViewController {
            // If root `UIViewController` is a `UITabBarController`
            if let presentedController = presentedController as? UITabBarController {
                // Move to selected `UIViewController`
                viewController = presentedController.selectedViewController
            } else {
                // Otherwise, go deeper
                viewController = presentedController
            }
        }
        
        return viewController
    }
    
}
