//
//  FlowSectionLayoutRenderer.swift
//  CladsModules
//
//  SwiftUI renderer for flow-style section layouts.
//

import CLADS
import SwiftUI

/// Renders flow-style section layouts in SwiftUI.
///
/// Flow layouts arrange items horizontally, wrapping to new lines as needed.
public struct FlowSectionLayoutRenderer: SwiftUISectionLayoutRendering {
    
    public static let layoutTypeIdentifier = SectionLayoutTypeIdentifier.flow
    
    public init() {}
    
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
        AnyView(
            FlowSectionContentView(section: section, context: context)
        )
    }
}

// MARK: - Flow Section Content View

private struct FlowSectionContentView: View {
    let section: IR.Section
    let context: SwiftUISectionRenderContext
    
    var body: some View {
        FlowLayout(
            horizontalSpacing: section.config.itemSpacing,
            verticalSpacing: section.config.lineSpacing
        ) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                context.renderChild(child)
            }
        }
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed.
public struct FlowLayout: Layout {
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity

        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + horizontalSpacing
            totalWidth = max(totalWidth, currentX - horizontalSpacing)
        }

        totalHeight = currentY + lineHeight

        return ArrangementResult(
            size: CGSize(width: totalWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }

    private struct ArrangementResult {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}
