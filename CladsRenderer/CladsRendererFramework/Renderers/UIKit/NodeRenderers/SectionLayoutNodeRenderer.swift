//
//  SectionLayoutNodeRenderer.swift
//  CladsRendererFramework
//
//  Renders SectionLayoutNode to scrollable section views.
//

import UIKit

/// Renders section layout nodes to scrollable UIViews
public struct SectionLayoutNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNode.Kind = .sectionLayout

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .sectionLayout(let sectionLayoutNode) = node else {
            return UIView()
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = sectionLayoutNode.sectionSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        for section in sectionLayoutNode.sections {
            let sectionView = renderSection(section, context: context)
            stackView.addArrangedSubview(sectionView)
        }

        return scrollView
    }

    // MARK: - Section Rendering

    private func renderSection(_ section: IR.Section, context: UIKitRenderContext) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.translatesAutoresizingMaskIntoConstraints = false

        // Header
        if let header = section.header {
            let headerView = context.render(header)
            container.addArrangedSubview(headerView)
        }

        // Content based on layout type
        let contentView = renderSectionContent(section, context: context)
        container.addArrangedSubview(contentView)

        // Footer
        if let footer = section.footer {
            let footerView = context.render(footer)
            container.addArrangedSubview(footerView)
        }

        // Apply content insets
        if section.config.contentInsets != .zero {
            return wrapWithInsets(container, insets: section.config.contentInsets)
        }

        return container
    }

    private func renderSectionContent(_ section: IR.Section, context: UIKitRenderContext) -> UIView {
        switch section.layoutType {
        case .horizontal:
            return renderHorizontalSection(section, context: context)
        case .list:
            return renderListSection(section, context: context)
        case .grid(let columns):
            return renderGridSection(section, columns: columns, context: context)
        case .flow:
            return renderFlowSection(section, context: context)
        }
    }

    // MARK: - Horizontal Section

    private func renderHorizontalSection(_ section: IR.Section, context: UIKitRenderContext) -> UIView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = section.config.showsIndicators
        scrollView.isPagingEnabled = section.config.isPagingEnabled

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = section.config.itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        for child in section.children {
            let childView = context.render(child)
            stackView.addArrangedSubview(childView)
        }

        return scrollView
    }

    // MARK: - List Section

    private func renderListSection(_ section: IR.Section, context: UIKitRenderContext) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = section.config.itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for (index, child) in section.children.enumerated() {
            let childView = context.render(child)
            stackView.addArrangedSubview(childView)

            // Add divider if needed
            if section.config.showsDividers && index < section.children.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .separator
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }

        return stackView
    }

    // MARK: - Grid Section

    private func renderGridSection(
        _ section: IR.Section,
        columns: IR.ColumnConfig,
        context: UIKitRenderContext
    ) -> UIView {
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = section.config.lineSpacing
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        let columnCount: Int
        switch columns {
        case .fixed(let count):
            columnCount = count
        case .adaptive:
            columnCount = 2  // Default for now
        }

        var currentRow: UIStackView?
        var itemsInRow = 0

        for child in section.children {
            if currentRow == nil || itemsInRow >= columnCount {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = section.config.itemSpacing
                currentRow?.distribution = .fillEqually
                currentRow?.translatesAutoresizingMaskIntoConstraints = false
                containerStack.addArrangedSubview(currentRow!)
                itemsInRow = 0
            }

            let childView = context.render(child)
            currentRow?.addArrangedSubview(childView)
            itemsInRow += 1
        }

        // Fill remaining slots in last row with spacers
        if let lastRow = currentRow, itemsInRow < columnCount {
            for _ in 0..<(columnCount - itemsInRow) {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                lastRow.addArrangedSubview(spacer)
            }
        }

        return containerStack
    }

    // MARK: - Flow Section

    private func renderFlowSection(_ section: IR.Section, context: UIKitRenderContext) -> UIView {
        // Flow layout is complex in UIKit without UICollectionView
        // For now, treat it like a grid with adaptive columns
        return renderGridSection(section, columns: .adaptive(minWidth: 80), context: context)
    }

    // MARK: - Helpers

    private func wrapWithInsets(_ view: UIView, insets: NSDirectionalEdgeInsets) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -insets.bottom),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: insets.leading),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -insets.trailing)
        ])
        return wrapper
    }
}
