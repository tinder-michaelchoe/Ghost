//
//  SectionLayoutNodeRenderer.swift
//  CladsModules
//
//  Renders SectionLayoutNode to scrollable section views.
//

import CLADS
import UIKit

/// Renders section layout nodes to scrollable UIViews
public struct SectionLayoutNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .sectionLayout

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
        // Check if we have item dimensions that require Compositional Layout
        if let dimensions = section.config.itemDimensions, dimensions.width != nil {
            return renderHorizontalSectionWithCompositionalLayout(section, context: context)
        }

        // Fall back to simple scroll view for natural sizing
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

    private func renderHorizontalSectionWithCompositionalLayout(
        _ section: IR.Section,
        context: UIKitRenderContext
    ) -> UIView {
        // Pre-render all children
        let childViews = section.children.map { context.render($0) }

        // Create the compositional layout
        let layout = createHorizontalCompositionalLayout(
            config: section.config,
            itemCount: childViews.count
        )

        // Create a hosting view that manages the collection view
        let hostingView = CompositionalHorizontalSectionView(
            layout: layout,
            childViews: childViews,
            config: section.config
        )

        return hostingView
    }

    private func createHorizontalCompositionalLayout(
        config: IR.SectionConfig,
        itemCount: Int
    ) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            // Determine item width
            let itemWidth: NSCollectionLayoutDimension
            if let dimensions = config.itemDimensions, let width = dimensions.width {
                switch width {
                case .absolute(let value):
                    itemWidth = .absolute(value)
                case .fractional(let fraction):
                    itemWidth = .fractionalWidth(fraction)
                }
            } else {
                itemWidth = .estimated(200)
            }

            // Determine item height
            let itemHeight: NSCollectionLayoutDimension
            if let dimensions = config.itemDimensions {
                if let height = dimensions.height {
                    switch height {
                    case .absolute(let value):
                        itemHeight = .absolute(value)
                    case .fractional(let fraction):
                        itemHeight = .fractionalHeight(fraction)
                    }
                } else if let aspectRatio = dimensions.aspectRatio, let width = dimensions.width {
                    // Calculate height based on aspect ratio
                    switch width {
                    case .absolute(let widthValue):
                        itemHeight = .absolute(widthValue / aspectRatio)
                    case .fractional(let fraction):
                        // For fractional width with aspect ratio, we need to estimate
                        let estimatedWidth = environment.container.effectiveContentSize.width * fraction
                        itemHeight = .absolute(estimatedWidth / aspectRatio)
                    }
                } else {
                    itemHeight = .estimated(200)
                }
            } else {
                itemHeight = .estimated(200)
            }

            // Create item
            let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: itemHeight)
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Create group (horizontal)
            let groupSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: itemHeight)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Create section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = config.itemSpacing
            section.orthogonalScrollingBehavior = self.orthogonalBehavior(for: config.snapBehavior)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: config.contentInsets.leading,
                bottom: 0,
                trailing: config.contentInsets.trailing
            )

            return section
        }

        return layout
    }

    private func orthogonalBehavior(for snapBehavior: IR.SnapBehavior) -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
        switch snapBehavior {
        case .none:
            return .continuous
        case .viewAligned:
            return .groupPagingCentered
        case .paging:
            return .paging
        }
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

// MARK: - Compositional Horizontal Section View

/// A UIView that hosts a UICollectionView with compositional layout for horizontal sections
final class CompositionalHorizontalSectionView: UIView {
    private let collectionView: UICollectionView
    private let childViews: [UIView]
    private var heightConstraint: NSLayoutConstraint?

    init(layout: UICollectionViewCompositionalLayout, childViews: [UIView], config: IR.SectionConfig) {
        self.childViews = childViews
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)

        setupCollectionView(config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionView(config: IR.SectionConfig) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = config.showsIndicators
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HostingCell.self, forCellWithReuseIdentifier: HostingCell.reuseIdentifier)

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Calculate height based on item dimensions
        if let dimensions = config.itemDimensions {
            let estimatedHeight = calculateEstimatedHeight(dimensions: dimensions)
            heightConstraint = heightAnchor.constraint(equalToConstant: estimatedHeight)
            heightConstraint?.isActive = true
        }
    }

    private func calculateEstimatedHeight(dimensions: IR.ItemDimensions) -> CGFloat {
        if let height = dimensions.height {
            switch height {
            case .absolute(let value):
                return value
            case .fractional:
                return 200 // Fallback for fractional height
            }
        } else if let aspectRatio = dimensions.aspectRatio, let width = dimensions.width {
            switch width {
            case .absolute(let widthValue):
                return widthValue / aspectRatio
            case .fractional(let fraction):
                // Estimate based on screen width
                let estimatedWidth = UIScreen.main.bounds.width * fraction
                return estimatedWidth / aspectRatio
            }
        }
        return 200 // Default height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension CompositionalHorizontalSectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childViews.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HostingCell.reuseIdentifier, for: indexPath) as! HostingCell
        cell.configure(with: childViews[indexPath.item])
        return cell
    }
}

// MARK: - Hosting Cell

/// A collection view cell that hosts an arbitrary UIView
private final class HostingCell: UICollectionViewCell {
    static let reuseIdentifier = "HostingCell"

    private var hostedView: UIView?

    func configure(with view: UIView) {
        // Remove previous hosted view
        hostedView?.removeFromSuperview()

        // Remove view from its current superview if any
        view.removeFromSuperview()

        // Add new view
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        hostedView = view
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}
