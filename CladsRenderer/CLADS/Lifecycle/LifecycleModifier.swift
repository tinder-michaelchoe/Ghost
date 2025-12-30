//
//  RootActionsModifier.swift
//  CladsRendererFramework
//
//  SwiftUI view modifier that applies root action hooks.
//

import SwiftUI

// MARK: - Root Actions Modifier

/// View modifier that applies root action bindings to a view.
///
/// To add support for a new event:
/// 1. Add the case to `RootActionEvent`
/// 2. Add the corresponding SwiftUI modifier here
struct RootActionsModifier: ViewModifier {
    let actions: RootActions
    let context: ActionContext

    func body(content: Content) -> some View {
        content
            .onAppear {
                execute(.onAppear)
            }
            .onDisappear {
                execute(.onDisappear)
            }
        // Future events:
        // .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        //     execute(.onForeground)
        // }
    }

    private func execute(_ event: RootActionEvent) {
        if let action = actions.action(for: event) {
            context.execute(action)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply root action hooks to this view
    func rootActions(_ actions: RootActions, context: ActionContext) -> some View {
        modifier(RootActionsModifier(actions: actions, context: context))
    }
}
