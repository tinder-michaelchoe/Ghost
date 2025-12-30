//
//  WidgetLayoutProvider.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import UIKit

// MARK: - Widget Layout Provider

/// Provides compositional layout configuration for widget grid using bin-packing algorithm
struct WidgetLayoutProvider {

    // MARK: - Configuration

    let columnCount: Int
    let cellSpacing: CGFloat
    let baseHeight: CGFloat

    init(columnCount: Int = 2, cellSpacing: CGFloat = 12, baseHeight: CGFloat = 160) {
        self.columnCount = columnCount
        self.cellSpacing = cellSpacing
        self.baseHeight = baseHeight
    }

    // MARK: - Layout Creation

    /// Creates a compositional layout section with custom widget placement
    func createSection(for widgets: [Widget], environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let contentWidth = environment.container.contentSize.width - 32 // Account for section insets

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(calculateTotalHeight(for: widgets, containerWidth: contentWidth))
        )

        let group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
            self.calculateFrames(for: widgets, containerWidth: contentWidth)
        }

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return section
    }

    // MARK: - Frame Calculation

    /// Calculates frames for all widgets using bin-packing algorithm
    private func calculateFrames(for widgets: [Widget], containerWidth: CGFloat) -> [NSCollectionLayoutGroupCustomItem] {
        let cellWidth = (containerWidth - cellSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)

        // Grid occupancy tracker
        var grid: [[Bool]] = []
        var items: [NSCollectionLayoutGroupCustomItem] = []

        for widget in widgets {
            guard let position = findPosition(for: widget.size, in: &grid) else { continue }

            let x = CGFloat(position.col) * (cellWidth + cellSpacing)
            let y = CGFloat(position.row) * (baseHeight + cellSpacing)
            let width = CGFloat(widget.size.columns) * cellWidth + CGFloat(widget.size.columns - 1) * cellSpacing
            let height = CGFloat(widget.size.rows) * baseHeight + CGFloat(widget.size.rows - 1) * cellSpacing

            let frame = CGRect(x: x, y: y, width: width, height: height)
            items.append(NSCollectionLayoutGroupCustomItem(frame: frame))

            markOccupied(row: position.row, col: position.col, size: widget.size, in: &grid)
        }

        return items
    }

    /// Calculates total height needed for all widgets
    private func calculateTotalHeight(for widgets: [Widget], containerWidth: CGFloat) -> CGFloat {
        var grid: [[Bool]] = []
        for widget in widgets {
            if let pos = findPosition(for: widget.size, in: &grid) {
                markOccupied(row: pos.row, col: pos.col, size: widget.size, in: &grid)
            }
        }
        let rowCount = max(grid.count, 1)
        return CGFloat(rowCount) * baseHeight + CGFloat(max(rowCount - 1, 0)) * cellSpacing
    }

    // MARK: - Grid Packing

    /// Finds the first grid position where the widget fits
    private func findPosition(for size: WidgetSize, in grid: inout [[Bool]]) -> (row: Int, col: Int)? {
        var row = 0

        while row < 100 { // Safety limit
            // Expand grid if needed
            while grid.count <= row + size.rows - 1 {
                grid.append(Array(repeating: false, count: columnCount))
            }

            for col in 0...(columnCount - size.columns) {
                if canPlace(size: size, at: row, col: col, in: grid) {
                    return (row, col)
                }
            }

            row += 1
        }

        return nil
    }

    /// Checks if widget fits at the given position without overlapping
    private func canPlace(size: WidgetSize, at row: Int, col: Int, in grid: [[Bool]]) -> Bool {
        for r in row..<(row + size.rows) {
            for c in col..<(col + size.columns) {
                if r >= grid.count || c >= columnCount || grid[r][c] {
                    return false
                }
            }
        }
        return true
    }

    /// Marks grid cells as occupied by a widget
    private func markOccupied(row: Int, col: Int, size: WidgetSize, in grid: inout [[Bool]]) {
        for r in row..<(row + size.rows) {
            for c in col..<(col + size.columns) {
                grid[r][c] = true
            }
        }
    }
}
