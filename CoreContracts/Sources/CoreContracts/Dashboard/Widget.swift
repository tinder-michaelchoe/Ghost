//
//  Widget.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import Foundation

// MARK: - Widget Size

/// Defines the grid dimensions a widget occupies
public enum WidgetSize: Hashable, Sendable {
    case small      // 1x1
    case medium     // 2x1 (wide)
    case tall       // 1x2
    case large      // 2x2

    /// Number of columns this widget spans
    public var columns: Int {
        switch self {
        case .small, .tall: return 1
        case .medium, .large: return 2
        }
    }

    /// Number of rows this widget spans
    public var rows: Int {
        switch self {
        case .small, .medium: return 1
        case .tall, .large: return 2
        }
    }

    /// Total grid cells this widget occupies
    public var area: Int {
        columns * rows
    }
}

// MARK: - Widget

/// Represents a dashboard widget
public struct Widget: Hashable, Sendable {
    public let id: String
    public let size: WidgetSize
    public let title: String
    public let priorityTier: WidgetPriorityTier

    public init(
        id: String,
        size: WidgetSize,
        title: String,
        priorityTier: WidgetPriorityTier = .secondary
    ) {
        self.id = id
        self.size = size
        self.title = title
        self.priorityTier = priorityTier
    }
}

// MARK: - Widget Sorting

public extension Array where Element == Widget {
    /// Sorts widgets for optimal dashboard layout.
    /// Widgets are sorted by priority tier first, then by size (largest first) within each tier.
    func sortedForLayout() -> [Widget] {
        sorted { a, b in
            if a.priorityTier != b.priorityTier {
                return a.priorityTier < b.priorityTier
            }
            // Within same tier, larger widgets first for better bin-packing
            return a.size.area > b.size.area
        }
    }
}
