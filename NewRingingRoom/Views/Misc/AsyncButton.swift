//
//  AsyncButton.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import SwiftUI

struct AsyncButton<Label: View, Background: View>: View {
    init(progressViewColor: Color = .primary, progressViewPadding: Double = 0, action: @escaping () async -> Void, label: () -> Label, background: () -> Background) {
        self.progressViewColor = progressViewColor
        self.progressViewPadding = progressViewPadding
        self.action = action
        self.label = label()
        self.background = background()
    }
    
    init(progressViewColor: Color = .primary, progressViewPadding: Double = 0, action: @escaping () async -> Void, label: () -> Label) where Background == EmptyView {
        self.progressViewColor = progressViewColor
        self.progressViewPadding = progressViewPadding
        self.action = action
        self.label = label()
        self.background = EmptyView()
    }

    init(_ label: String, progressViewColor: Color = .primary, progressViewPadding: Double = 0, action: @escaping () async -> Void, @ViewBuilder background: () -> Background) where Label == Text {
        self.progressViewColor = progressViewColor
        self.progressViewPadding = progressViewPadding
        self.action = action
        self.label = Text(label)
        self.background = background()
    }
    
    init(_ label: String, progressViewColor: Color = .primary, progressViewPadding: Double = 0, action: @escaping () async -> Void, @ViewBuilder background: () -> Background = { EmptyView() }) where Label == Text, Background == EmptyView {
        self.progressViewColor = progressViewColor
        self.progressViewPadding = progressViewPadding
        self.action = action
        self.label = Text(label)
        self.background = background()
    }
    
    var progressViewColor: Color = .primary

    let progressViewPadding: Double
    
    var action: () async -> Void
    
    @ViewBuilder var label: Label
    @ViewBuilder var background: Background
    
    @State private var isPerformingTask = false
    
    var body: some View {
        Button {
            isPerformingTask = true
            
            Task {
                await action()
                isPerformingTask = false
            }
        } label: {
            ZStack {
                background
                if isPerformingTask {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .foregroundColor(progressViewColor)
                        .tint(progressViewColor)
                        .padding(progressViewPadding)
                } else {
                    label
                }
            }
        }
        .disabled(isPerformingTask)
        .contentShape(RoundedRectangle(cornerRadius: 5))
    }
}
