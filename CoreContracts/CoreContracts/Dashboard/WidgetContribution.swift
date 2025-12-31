//
//  WidgetContribution.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/30/25.
//

import UIKit

// MARK: - Widget Priority Tier

/// Priority tiers for widget placement in the dashboard.
/// Widgets are sorted by tier first, then by size within each tier for optimal packing.
public enum WidgetPriorityTier: Int, Comparable, Sendable, CaseIterable {
    /// User-pinned widgets - always appear at the top
    case pinned = 0

    /// Primary widgets - core functionality (e.g., weather, calendar)
    case primary = 1

    /// Secondary widgets - supporting functionality
    case secondary = 2

    /// Tertiary widgets - nice-to-have, appear at the bottom
    case tertiary = 3

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Widget Contribution

/// Protocol for widget metadata.
/// Widgets are registered as regular contributions via `contribute`.
/// The factory should return a UIViewController that conforms to FlippableWidgetProviding
/// if the widget supports front/back views.
public protocol WidgetContribution: ViewContribution {
    /// The size of the widget in the grid
    var size: WidgetSize { get }

    /// The display title for the widget
    var title: String { get }

    /// The priority tier for layout ordering
    var priorityTier: WidgetPriorityTier { get }
}

// MARK: - Default Implementation

public extension WidgetContribution {
    /// Default priority tier is secondary
    var priorityTier: WidgetPriorityTier { .secondary }
}

// MARK: - Widget Model from Contribution

public extension WidgetContribution {
    /// Creates a Widget model from this contribution
    var widget: Widget {
        Widget(id: id.rawValue, size: size, title: title, priorityTier: priorityTier)
    }
}

// MARK: - Flippable Widget Providing

/// Protocol for widget view controllers that support front/back views.
/// The Dashboard module uses this to create card views with flip capability.
@MainActor
public protocol FlippableWidgetProviding: AnyObject {
    /// The front view controller (main widget content)
    var frontViewController: UIViewController { get }

    /// The back view controller (settings/configuration), nil if not flippable
    var backViewController: UIViewController? { get }
}

// MARK: - Widget Coordination

/// Protocol for widgets that can be refreshed externally.
/// Implement this on front view controllers that should refresh when settings change.
@MainActor
public protocol RefreshableWidget: AnyObject {
    /// Refreshes the widget's content.
    func refreshContent()
}

/// Protocol for coordinating between widgets.
/// The Dashboard implements this to handle cross-widget communication.
@MainActor
public protocol WidgetCoordinator: AnyObject {
    /// Called when a widget's settings change that may affect other widgets.
    /// - Parameter widgetId: The ID of the widget that changed
    func widgetDidChangeSettings(widgetId: String)
}

/// Protocol for widget containers that support coordination.
/// Implement this on container view controllers that need to communicate with the dashboard.
@MainActor
public protocol CoordinatedWidgetProviding: FlippableWidgetProviding {
    /// The coordinator for cross-widget communication. Set by the Dashboard.
    var coordinator: WidgetCoordinator? { get set }

    /// The widget ID for identification in coordination calls.
    var widgetId: String { get }
}
