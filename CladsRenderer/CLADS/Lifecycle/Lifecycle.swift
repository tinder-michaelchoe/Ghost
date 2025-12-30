//
//  RootActions.swift
//  CladsRendererFramework
//
//  Root-level action handling for CladsRenderer views.
//

import Foundation

// MARK: - Root Action Event

/// Supported root-level action events for CladsRenderer views.
///
/// To add a new event:
/// 1. Add a case here
/// 2. Add the corresponding modifier in `RootActionsModifier`
public enum RootActionEvent: String, CaseIterable {
    /// Triggered when the view appears on screen
    case onAppear

    /// Triggered when the view disappears from screen
    case onDisappear

    // Future events:
    // case onForeground
    // case onBackground
}

// MARK: - Root Actions (IR)

/// Container for root-level action bindings (IR layer).
///
/// Parsed from the document's `root.actions` and used by `RootActionsModifier`
/// to execute actions at the appropriate points.
public struct RootActions {
    private var actions: [RootActionEvent: Document.Component.ActionBinding] = [:]

    /// Create empty root actions
    public init() {}

    /// Create root actions from document root actions
    public init(from documentActions: Document.RootActions?) {
        guard let documentActions = documentActions else { return }

        if let onAppear = documentActions.onAppear {
            actions[.onAppear] = onAppear
        }
        if let onDisappear = documentActions.onDisappear {
            actions[.onDisappear] = onDisappear
        }
    }

    /// Get the action binding for a specific event
    public func action(for event: RootActionEvent) -> Document.Component.ActionBinding? {
        actions[event]
    }

    /// Check if any actions are defined
    public var isEmpty: Bool {
        actions.isEmpty
    }

    /// All events that have actions defined
    public var definedEvents: [RootActionEvent] {
        Array(actions.keys)
    }
}
