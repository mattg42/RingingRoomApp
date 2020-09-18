//
//  ChatManager.swift
//  iOSRingingRoom
//
//  Created by Matthew on 05/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class ChatManager:ObservableObject {
    @Published var messages = [""]
    @Published var newMessages = 0
    
    var canSeeMessages = false
    
    static var shared = ChatManager()
    
    var firstMessage = true
    
    func newMessage(user:String, message:String) {
       // self.objectWillChange.send()
        print("appended new message")
        var newMessagesArray = messages
        if firstMessage {
            newMessagesArray[0] = "\(user): \(message)"
        } else {
            newMessagesArray.append("\(user): \(message)")
        }
        if !canSeeMessages {
            self.objectWillChange.send()
            newMessages += 1
        }
        messages = newMessagesArray
    }
}

struct message:Identifiable {
    var id = UUID()
    
    var sender:String
    var message:String
}
