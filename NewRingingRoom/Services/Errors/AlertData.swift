//
//  alertHandler.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation
import UIKit

public typealias Action = () -> Void

enum DissmissType {
    case cancel(title: String?, action: Action?)
    case retry(action: Action)
    case logout(action: Action)
}

struct AlertData {
    init(title: String, message: String, dissmiss: DissmissType) {
        self.title = title
        self.message = message
        self.dismiss = dissmiss
    }
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
        self.dismiss = .cancel(title: "Ok", action: nil)
    }
    
    var title: String
    var message: String
    
    var dismiss: DissmissType
}

protocol Alertable {
    var alertData: AlertData { get }
}
