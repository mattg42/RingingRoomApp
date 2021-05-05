//
//  ChatManager.swift
//  iOSRingingRoom
//
//  Created by Matthew on 05/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class ChatManager:ObservableObject {
    @Published var messages = [Message]() //[""]
    @Published var newMessages = 0
    
    var canSeeMessages = false {
        didSet {
            if canSeeMessages {
                newMessages = 0
            }
        }
    }
    
    static var shared = ChatManager()
    
    private init() {}
//    var firstMessage = true
    
    func newMessage(user:String, message:String) {
       // self.objectWillChange.send()
        print("appended new message")
        var newMessagesArray = messages
//        if firstMessage {
//            newMessagesArray[0] = "\(user): \(message)"
//            firstMessage = false
//        } else {
            newMessagesArray.append(Message(sender: user, message: message))
//        }
        if !canSeeMessages {
            self.objectWillChange.send()
            newMessages += 1
        }
        messages = newMessagesArray
        print(messages.count)
    }
}

struct Message:Identifiable {
    var id = UUID()
    
    var sender:String
    var message:String
}
