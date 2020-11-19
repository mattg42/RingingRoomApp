//
//  ShareSheet.swift
//  iOSRingingRoom
//
//  Created by Matthew on 13/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    
    let activityItems:[Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

