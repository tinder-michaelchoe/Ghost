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

/// Protocol for contributing widgets to the dashboard.
/// Contributors must provide a front view and can optionally provide a back view.
/// If no back view is provided, double-tapping the widget will show a wiggle animation.
public protocol WidgetContribution: ViewContribution {
    /// The size of the widget in the grid
    var size: WidgetSize { get }

    /// The display title for the widget
    var title: String { get }

    /// The priority tier for layout ordering
    var priorityTier: WidgetPriorityTier { get }

    /// Creates the front view for the widget
    /// - Parameter context: The app context for resolving dependencies
    /// - Returns: The front view controller
    @MainActor func makeFrontViewController(context: AppContext) -> UIViewController

    /// Creates the optional back view for the widget
    /// - Parameter context: The app context for resolving dependencies
    /// - Returns: The back view controller, or nil if no back side
    @MainActor func makeBackViewController(context: AppContext) -> UIViewController?
}

// MARK: - Default Implementation

public extension WidgetContribution {
    /// Default priority tier is secondary
    var priorityTier: WidgetPriorityTier { .secondary }

    /// Default implementation returns nil (no back view)
    @MainActor func makeBackViewController(context: AppContext) -> UIViewController? {
        nil
    }
}

// MARK: - Widget Model from Contribution

public extension WidgetContribution {
    /// Creates a Widget model from this contribution
    var widget: Widget {
        Widget(id: id.rawValue, size: size, title: title, priorityTier: priorityTier)
    }
}
