//
//  SectionLayoutNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and views for section layouts.
//

import CLADS
import SwiftUI

// MARK: - Section Layout Node SwiftUI Renderer

public struct SectionLayoutNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.sectionLayout

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .sectionLayout(let sectionLayoutNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            SectionLayoutView(node: sectionLayoutNode, context: context)
                .environmentObject(context.tree.stateStore)
                .environmentObject(context.actionContext)
        )
    }
}

// MARK: - Section Layout View

struct SectionLayoutView: View {
    let node: SectionLayoutNode
    let context: SwiftUIRenderContext

    var body: some View {
        ScrollView {
            LazyVStack(spacing: node.sectionSpacing) {
                ForEach(Array(node.sections.enumerated()), id: \.offset) { _, section in
                    SectionView(section: section, context: context)
                }
            }
        }
    }
}

// MARK: - Section View

struct SectionView: View {
    let section: IR.Section
    let context: SwiftUIRenderContext

    var body: some View {
        VStack(alignment: section.config.alignment, spacing: 0) {
            // Header
            if let header = section.header {
                renderNode(header)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: section.config.alignment, vertical: .center))
                    .padding(.leading, section.config.contentInsets.leading)
                    .padding(.trailing, section.config.contentInsets.trailing)
            }

            // Content based on layout type
            sectionContent
                .padding(.top, section.config.contentInsets.top)
                .padding(.bottom, section.config.contentInsets.bottom)
                .padding(.leading, section.config.contentInsets.leading)
                .padding(.trailing, section.config.contentInsets.trailing)

            // Footer
            if let footer = section.footer {
                renderNode(footer)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: section.config.alignment, vertical: .center))
                    .padding(.leading, section.config.contentInsets.leading)
                    .padding(.trailing, section.config.contentInsets.trailing)
            }
        }
    }

    @ViewBuilder
    private func renderNode(_ node: RenderNode) -> some View {
        context.render(node)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section.layoutType {
        case .horizontal:
            horizontalSection
        case .list:
            listSection
        case .grid(let columns):
            gridSection(columns: columns)
        case .flow:
            flowSection
        }
    }

    @ViewBuilder
    private var horizontalSection: some View {
        ScrollView(.horizontal, showsIndicators: section.config.showsIndicators) {
            LazyHStack(spacing: section.config.itemSpacing) {
                ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                    HorizontalSectionItemView(
                        child: child,
                        context: context,
                        dimensions: section.config.itemDimensions
                    )
                }
            }
            .scrollTargetLayout()
        }
        .applySnapBehavior(section.config.snapBehavior)
    }

    @ViewBuilder
    private var listSection: some View {
        LazyVStack(alignment: section.config.alignment, spacing: section.config.itemSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { index, child in
                VStack(spacing: 0) {
                    renderNode(child)
                        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: section.config.alignment, vertical: .center))
                    if section.config.showsDividers && index < section.children.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gridSection(columns: IR.ColumnConfig) -> some View {
        let gridColumns: [GridItem] = {
            switch columns {
            case .fixed(let count):
                return Array(repeating: GridItem(.flexible(), spacing: section.config.itemSpacing), count: count)
            case .adaptive(let minWidth):
                return [GridItem(.adaptive(minimum: minWidth), spacing: section.config.itemSpacing)]
            }
        }()

        LazyVGrid(columns: gridColumns, spacing: section.config.lineSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                renderNode(child)
            }
        }
    }

    @ViewBuilder
    private var flowSection: some View {
        FlowLayout(horizontalSpacing: section.config.itemSpacing, verticalSpacing: section.config.lineSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                renderNode(child)
            }
        }
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
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

// MARK: - Horizontal Section Item View

/// A view that wraps section items with optional dimension constraints
struct HorizontalSectionItemView: View {
    let child: RenderNode
    let context: SwiftUIRenderContext
    let dimensions: IR.ItemDimensions?

    var body: some View {
        context.render(child)
            .modifier(ItemDimensionsModifier(dimensions: dimensions))
    }
}

// MARK: - Item Dimensions Modifier

/// Modifier that applies item dimensions using containerRelativeFrame for fractional widths
struct ItemDimensionsModifier: ViewModifier {
    let dimensions: IR.ItemDimensions?

    func body(content: Content) -> some View {
        if let dimensions = dimensions {
            content
                .modifier(WidthModifier(width: dimensions.width))
                .modifier(HeightModifier(height: dimensions.height, aspectRatio: dimensions.aspectRatio, width: dimensions.width))
        } else {
            content
        }
    }
}

/// Applies width dimension (absolute or fractional)
struct WidthModifier: ViewModifier {
    let width: IR.DimensionValue?

    func body(content: Content) -> some View {
        if let width = width {
            switch width {
            case .absolute(let value):
                content.frame(width: value)
            case .fractional(let fraction):
                content.containerRelativeFrame(.horizontal) { containerWidth, _ in
                    containerWidth * fraction
                }
            }
        } else {
            content
        }
    }
}

/// Applies height dimension (absolute, or computed from aspect ratio)
struct HeightModifier: ViewModifier {
    let height: IR.DimensionValue?
    let aspectRatio: CGFloat?
    let width: IR.DimensionValue?

    func body(content: Content) -> some View {
        if let height = height {
            switch height {
            case .absolute(let value):
                content.frame(height: value)
            case .fractional(let fraction):
                content.containerRelativeFrame(.vertical) { containerHeight, _ in
                    containerHeight * fraction
                }
            }
        } else if let aspectRatio = aspectRatio {
            content.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            content
        }
    }
}

// MARK: - Snap Behavior Extension

extension View {
    @ViewBuilder
    func applySnapBehavior(_ behavior: IR.SnapBehavior) -> some View {
        switch behavior {
        case .none:
            self
        case .viewAligned:
            self.scrollTargetBehavior(.viewAligned)
        case .paging:
            self.scrollTargetBehavior(.paging)
        }
    }
}
