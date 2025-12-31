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
public protocol FlippableWidgetProviding {
    /// The front view controller (main widget content)
    var frontViewController: UIViewController { get }

    /// The back view controller (settings/configuration), nil if not flippable
    var backViewController: UIViewController? { get }
}
