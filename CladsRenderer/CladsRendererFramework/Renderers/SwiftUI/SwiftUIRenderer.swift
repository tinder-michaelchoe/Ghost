//
//  SwiftUIRenderer.swift
//  CladsRendererFramework
//
//  Renders a RenderTree into SwiftUI views.
//

import SwiftUI

// MARK: - SwiftUI Renderer

/// Renders a RenderTree into SwiftUI views
public struct SwiftUIRenderer: Renderer {
    private let actionContext: ActionContext

    public init(actionContext: ActionContext) {
        self.actionContext = actionContext
    }

    public func render(_ tree: RenderTree) -> some View {
        RenderTreeView(tree: tree, actionContext: actionContext)
    }
}

// MARK: - Render Tree View

/// SwiftUI view that renders a RenderTree
struct RenderTreeView: View {
    let tree: RenderTree
    let actionContext: ActionContext

    var body: some View {
        ZStack {
            // Background
            if let bg = tree.root.backgroundColor {
                bg.ignoresSafeArea()
            }

            // Content with edge insets using custom RootLayout
            RootLayout(edgeInsets: tree.root.edgeInsets) {
                VStack(spacing: 0) {
                    ForEach(Array(tree.root.children.enumerated()), id: \.offset) { _, node in
                        RenderNodeView(node: node, tree: tree, actionContext: actionContext)
                    }
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea(edges: absoluteEdges)
        }
        .environmentObject(tree.stateStore)
        .environmentObject(actionContext)
        .rootActions(tree.root.actions, context: actionContext)
    }

    /// Edges that should ignore safe area (absolute positioning)
    private var absoluteEdges: Edge.Set {
        var edges: Edge.Set = []
        if tree.root.edgeInsets?.top?.positioning == .absolute { edges.insert(.top) }
        if tree.root.edgeInsets?.bottom?.positioning == .absolute { edges.insert(.bottom) }
        if tree.root.edgeInsets?.leading?.positioning == .absolute { edges.insert(.leading) }
        if tree.root.edgeInsets?.trailing?.positioning == .absolute { edges.insert(.trailing) }
        return edges
    }
}

// MARK: - Root Layout

/// A custom Layout that positions content based on edge insets
struct RootLayout: Layout {
    let edgeInsets: IR.EdgeInsets?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Return the proposed size (fill available space)
        CGSize(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }

        // Calculate insets from the bounds
        // For safeArea positioning: bounds already accounts for safe area, add our value
        // For absolute positioning: bounds extends to screen edge due to ignoresSafeArea, add our value
        let topInset = edgeInsets?.top?.value ?? 0
        let bottomInset = edgeInsets?.bottom?.value ?? 0
        let leadingInset = edgeInsets?.leading?.value ?? 0
        let trailingInset = edgeInsets?.trailing?.value ?? 0

        // Calculate the content frame
        let contentWidth = bounds.width - leadingInset - trailingInset
        let contentHeight = bounds.height - topInset - bottomInset

        let origin = CGPoint(
            x: bounds.minX + leadingInset,
            y: bounds.minY + topInset
        )

        subview.place(
            at: origin,
            proposal: ProposedViewSize(width: contentWidth, height: contentHeight)
        )
    }
}

// MARK: - Render Node View

/// SwiftUI view that renders a single RenderNode
struct RenderNodeView: View {
    let node: RenderNode
    let tree: RenderTree
    let actionContext: ActionContext

    var body: some View {
        switch node {
        case .container(let container):
            ContainerNodeView(node: container, tree: tree, actionContext: actionContext)

        case .sectionLayout(let sectionLayout):
            SectionLayoutView(node: sectionLayout, tree: tree, actionContext: actionContext)

        case .text(let text):
            TextNodeView(node: text)

        case .button(let button):
            ButtonNodeView(node: button, actionContext: actionContext)

        case .textField(let textField):
            TextFieldNodeView(node: textField)

        case .toggle(let toggle):
            ToggleNodeView(node: toggle)

        case .slider(let slider):
            SliderNodeView(node: slider)

        case .image(let image):
            ImageNodeView(node: image)

        case .gradient(let gradient):
            GradientNodeView(node: gradient, colorScheme: tree.root.colorScheme)

        case .spacer:
            Spacer()
        }
    }
}

// MARK: - Container Node View

struct ContainerNodeView: View {
    let node: ContainerNode
    let tree: RenderTree
    let actionContext: ActionContext

    var body: some View {
        Group {
            switch node.layoutType {
            case .vstack:
                VStack(alignment: horizontalAlignment, spacing: node.spacing) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        RenderNodeView(node: child, tree: tree, actionContext: actionContext)
                    }
                }
                .frame(maxWidth: .infinity, alignment: Alignment(horizontal: horizontalAlignment, vertical: .center))
            case .hstack:
                HStack(alignment: verticalAlignment, spacing: node.spacing) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        RenderNodeView(node: child, tree: tree, actionContext: actionContext)
                    }
                }
            case .zstack:
                ZStack(alignment: zstackAlignment) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        RenderNodeView(node: child, tree: tree, actionContext: actionContext)
                    }
                }
            }
        }
        .padding(.top, node.padding.top)
        .padding(.bottom, node.padding.bottom)
        .padding(.leading, node.padding.leading)
        .padding(.trailing, node.padding.trailing)
    }

    private var horizontalAlignment: SwiftUI.HorizontalAlignment {
        node.alignment.horizontal
    }

    private var verticalAlignment: SwiftUI.VerticalAlignment {
        node.alignment.vertical
    }

    private var zstackAlignment: SwiftUI.Alignment {
        node.alignment
    }
}

// MARK: - Text Node View

struct TextNodeView: View {
    let node: TextNode
    @EnvironmentObject var stateStore: StateStore

    var body: some View {
        Text(displayContent)
            .applyTextStyle(node.style)
            .padding(.top, node.padding.top)
            .padding(.bottom, node.padding.bottom)
            .padding(.leading, node.padding.leading)
            .padding(.trailing, node.padding.trailing)
    }

    /// Compute the content to display, reading from StateStore if dynamic
    private var displayContent: String {
        // If there's a binding path, read directly from state
        if let path = node.bindingPath {
            return stateStore.get(path) as? String ?? node.content
        }

        // If there's a template, interpolate with state
        if let template = node.bindingTemplate {
            return stateStore.interpolate(template)
        }

        // Otherwise, use static content
        return node.content
    }
}

// MARK: - Button Node View

struct ButtonNodeView: View {
    let node: ButtonNode
    let actionContext: ActionContext
    @EnvironmentObject var stateStore: StateStore

    /// Check if button is selected based on state binding
    private var isSelected: Bool {
        guard let bindingPath = node.isSelectedBinding else { return false }
        return stateStore.get(bindingPath) as? Bool ?? false
    }

    /// Get the current style based on selection state
    private var currentStyle: IR.Style {
        node.styles.style(isSelected: isSelected)
    }

    var body: some View {
        Button(action: handleTap) {
            Text(node.label)
                .applyTextStyle(currentStyle)
                .padding(.top, currentStyle.paddingTop ?? 0)
                .padding(.bottom, currentStyle.paddingBottom ?? 0)
                .padding(.leading, currentStyle.paddingLeading ?? 0)
                .padding(.trailing, currentStyle.paddingTrailing ?? 0)
                .frame(maxWidth: node.fillWidth ? .infinity : nil)
                .frame(height: currentStyle.height)
                .background(currentStyle.backgroundColor ?? .clear)
                .cornerRadius(currentStyle.cornerRadius ?? 0)
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        guard let binding = node.onTap else { return }
        Task { @MainActor in
            switch binding {
            case .reference(let actionId):
                await actionContext.executeAction(id: actionId)
            case .inline(let action):
                await actionContext.executeAction(action)
            }
        }
    }
}

// MARK: - TextField Node View

struct TextFieldNodeView: View {
    let node: TextFieldNode
    @EnvironmentObject var stateStore: StateStore
    @State private var text: String = ""

    var body: some View {
        TextField(node.placeholder, text: $text)
            .applyTextStyle(node.style)
            .onAppear {
                if let path = node.bindingPath {
                    text = stateStore.get(path) as? String ?? ""
                }
            }
            .onChange(of: text) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}

// MARK: - Toggle Node View

struct ToggleNodeView: View {
    let node: ToggleNode
    @EnvironmentObject var stateStore: StateStore
    @State private var isOn: Bool = false

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(node.style.tintColor)
            .onAppear {
                if let path = node.bindingPath {
                    isOn = stateStore.get(path) as? Bool ?? false
                }
            }
            .onChange(of: isOn) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}

// MARK: - Slider Node View

struct SliderNodeView: View {
    let node: SliderNode
    @EnvironmentObject var stateStore: StateStore
    @State private var value: Double = 0.0

    var body: some View {
        Slider(value: $value, in: node.minValue...node.maxValue)
            .tint(node.style.tintColor)
            .onAppear {
                if let path = node.bindingPath {
                    value = stateStore.get(path) as? Double ?? node.minValue
                }
            }
            .onChange(of: value) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}

// MARK: - Image Node View

struct ImageNodeView: View {
    let node: ImageNode

    var body: some View {
        Group {
            switch node.source {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .url(let url):
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
        }
        .frame(width: node.style.width, height: node.style.height)
        .frame(maxWidth: node.style.width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: node.style.cornerRadius ?? 0))
    }
}

/// Applies tint color to an image if specified
private struct TintModifier: ViewModifier {
    let tintColor: Color?

    func body(content: Content) -> some View {
        if let tintColor {
            content.foregroundStyle(tintColor)
        } else {
            content
        }
    }
}

// MARK: - Gradient Node View

struct GradientNodeView: View {
    let node: GradientNode
    let colorScheme: RenderColorScheme
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        LinearGradient(
            stops: node.colors.map { stop in
                Gradient.Stop(
                    color: stop.color.resolved(for: colorScheme, systemScheme: systemColorScheme),
                    location: stop.location
                )
            },
            startPoint: node.startPoint,
            endPoint: node.endPoint
        )
        .frame(width: node.style.width, height: node.style.height)
    }
}

// MARK: - Section Layout View

struct SectionLayoutView: View {
    let node: SectionLayoutNode
    let tree: RenderTree
    let actionContext: ActionContext

    var body: some View {
        ScrollView {
            LazyVStack(spacing: node.sectionSpacing) {
                ForEach(Array(node.sections.enumerated()), id: \.offset) { _, section in
                    SectionView(section: section, tree: tree, actionContext: actionContext)
                }
            }
        }
    }
}

// MARK: - Section View

struct SectionView: View {
    let section: IR.Section
    let tree: RenderTree
    let actionContext: ActionContext

    var body: some View {
        VStack(alignment: section.config.alignment, spacing: 0) {
            // Header
            if let header = section.header {
                RenderNodeView(node: header, tree: tree, actionContext: actionContext)
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
                RenderNodeView(node: footer, tree: tree, actionContext: actionContext)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: section.config.alignment, vertical: .center))
                    .padding(.leading, section.config.contentInsets.leading)
                    .padding(.trailing, section.config.contentInsets.trailing)
            }
        }
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
        let content = ScrollView(.horizontal, showsIndicators: section.config.showsIndicators) {
            LazyHStack(spacing: section.config.itemSpacing) {
                ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                    RenderNodeView(node: child, tree: tree, actionContext: actionContext)
                }
            }
        }

        if section.config.isPagingEnabled {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }

    @ViewBuilder
    private var listSection: some View {
        LazyVStack(alignment: section.config.alignment, spacing: section.config.itemSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { index, child in
                VStack(spacing: 0) {
                    RenderNodeView(node: child, tree: tree, actionContext: actionContext)
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
                RenderNodeView(node: child, tree: tree, actionContext: actionContext)
            }
        }
    }

    @ViewBuilder
    private var flowSection: some View {
        FlowLayout(horizontalSpacing: section.config.itemSpacing, verticalSpacing: section.config.lineSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                RenderNodeView(node: child, tree: tree, actionContext: actionContext)
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

