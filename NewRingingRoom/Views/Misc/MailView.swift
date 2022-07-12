//
//  mailView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss
    @Binding var result: Result<MFMailComposeResult, Error>?

    var recipient: String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        var dismiss: DismissAction
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(dismiss: DismissAction,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            self.dismiss = dismiss
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                dismiss()
            }
            
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(dismiss: dismiss,
                           result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {

    }
}
