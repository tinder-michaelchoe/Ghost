//
//  CladsActionsModifier.swift
//  CLADS
//
//  SwiftUI view modifier for applying CLADS actions to custom components.
//

import Foundation
import SwiftUI

// MARK: - CLADS Actions Modifier

/// View modifier that applies CLADS actions to a SwiftUI view.
///
/// This allows custom components to use the same action system as built-in components.
///
/// Example:
/// ```swift
/// MyCustomView()
///     .applyCladsActions(context.component.actions, context: context)
/// ```
public struct CladsActionsModifier: ViewModifier {
    let actions: Document.Component.Actions?
    let context: CustomComponentContext

    public init(actions: Document.Component.Actions?, context: CustomComponentContext) {
        self.actions = actions
        self.context = context
    }

    public func body(content: Content) -> some View {
        content
            .applyOnTap(actions?.onTap, context: context)
    }
}

// MARK: - View Extension

extension View {
    /// Apply CLADS actions to this view
    public func applyCladsActions(_ actions: Document.Component.Actions?, context: CustomComponentContext) -> some View {
        modifier(CladsActionsModifier(actions: actions, context: context))
    }

    /// Apply a single tap action to this view
    @MainActor
    public func applyCladsOnTap(_ action: Document.Component.ActionBinding?, context: CustomComponentContext) -> some View {
        applyOnTap(action, context: context)
    }
}

// MARK: - Action Application Helpers

private extension View {
    @MainActor
    @ViewBuilder
    func applyOnTap(_ action: Document.Component.ActionBinding?, context: CustomComponentContext) -> some View {
        if let action = action {
            self.onTapGesture {
                Task {
                    await context.executeAction(action)
                }
            }
        } else {
            self
        }
    }
}

