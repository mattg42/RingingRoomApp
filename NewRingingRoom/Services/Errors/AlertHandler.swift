//
//  alertHandler.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation
import UIKit

public enum AlertHandler {
    static func presentAlert(title: String, message: String?, dismiss: DissmissType) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        switch dismiss {
        case .cancel(let title, let action):
            let alertAction = UIAlertAction(title: title, style: .cancel, handler: { _ in
                action?()
            })
            alertAction.titleTextColor = .systemBlue
            ac.addAction(alertAction)
        case .retry(let action):
            let alertAction = UIAlertAction(title: "Retry", style: .default, handler: { _ in
                action()
            })
            alertAction.titleTextColor = .systemBlue
            ac.addAction(alertAction)
        case .logout(let action):
            let logoutAlertAction = UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                action()
            })
            let cancelAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAlertAction.titleTextColor = .systemBlue
            ac.addAction(logoutAlertAction)
            ac.addAction(cancelAlertAction)
        }
        
        ThreadUtil.runInMain {
            UIApplication.shared.keyWindowPresentedController?.present(ac, animated: true, completion: nil)
        }
    }
    
    static func handle(error: Alertable) {
        presentAlert(title: error.alertData.title, message: error.alertData.message, dismiss: error.alertData.dismiss)
    }
}

extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}

extension UIApplication {
    
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
    
    var orientation: UIInterfaceOrientation? {
        keyWindow?.windowScene?.interfaceOrientation
    }
}
