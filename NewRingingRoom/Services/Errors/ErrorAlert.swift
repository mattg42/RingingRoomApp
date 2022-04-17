//
//  ErrorHandler.swift
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
}

struct ErrorAlert {
    var title: String
    var message: String
    
    var dissmiss: DissmissType
}

protocol Alertable {
    var errorAlert: ErrorAlert { get }
}
