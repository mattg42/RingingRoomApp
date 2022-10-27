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

private struct DismissFunctionKey: EnvironmentKey {
    static let defaultValue: DismissAction? = nil
}

extension EnvironmentValues {
    var dismissFunction: DismissAction? {
        get { self[DismissFunctionKey.self] }
        set { self[DismissFunctionKey.self] = newValue }
    }
}

struct ConditionalDismissModifier: ViewModifier {    
    @Environment(\.dismissFunction) var dismiss
    @Environment(\.isInSheet) var isInSheet
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isInSheet {
                        Button {
                            dismiss!()
                        } label: {
                            Text("Dismiss")
                        }
                    }
                }
            }
    }
}

extension View {
    func conditionalDismissToolbarButton() -> some View {
        self
            .modifier(ConditionalDismissModifier())
    }
}


