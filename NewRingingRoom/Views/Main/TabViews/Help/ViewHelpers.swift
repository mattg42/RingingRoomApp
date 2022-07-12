//
//  ViewHelpers.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

private struct IsInSheetKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isInSheet: Bool {
        get { self[IsInSheetKey.self] }
        set { self[IsInSheetKey.self] = newValue }
    }
}

extension View {
    func isInSheet(_ isInSheet: Bool) -> some View {
        environment(\.isInSheet, isInSheet)
    }
}

struct ConditionalDismissModifier: ViewModifier {
    var shouldDisplay: Bool
    
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if shouldDisplay {
                        Button {
                            dismiss()
                        } label: {
                            Text("Dismiss")
                        }
                    }
                }
            }
    }
}

extension View {
    func conditionalDismiss(shouldDisplay: Bool) -> some View {
        self
            .modifier(ConditionalDismissModifier(shouldDisplay: shouldDisplay))
    }
}


