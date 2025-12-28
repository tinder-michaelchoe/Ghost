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

            // Content
            VStack(spacing: 0) {
                ForEach(Array(tree.root.children.enumerated()), id: \.offset) { _, node in
                    RenderNodeView(node: node, tree: tree, actionContext: actionContext)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(EdgeInsetsModifier(insets: tree.root.edgeInsets))
        }
        .environmentObject(tree.stateStore)
        .environmentObject(actionContext)
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

    var body: some View {
        Text(node.content)
            .applyTextStyle(node.style)
    }
}

// MARK: - Button Node View

struct ButtonNodeView: View {
    let node: ButtonNode
    let actionContext: ActionContext

    var body: some View {
        Button(action: handleTap) {
            Text(node.label)
                .applyTextStyle(node.style)
                .frame(maxWidth: node.fillWidth ? .infinity : nil)
                .frame(height: node.style.height)
                .background(node.style.backgroundColor ?? .clear)
                .cornerRadius(node.style.cornerRadius ?? 0)
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

            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            case .url(let url):
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: node.style.width, height: node.style.height)
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
        VStack(spacing: 0) {
            // Header
            if let header = section.header {
                RenderNodeView(node: header, tree: tree, actionContext: actionContext)
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
        LazyVStack(spacing: section.config.itemSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { index, child in
                VStack(spacing: 0) {
                    RenderNodeView(node: child, tree: tree, actionContext: actionContext)
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
        // Flow layout using flexible HStack that wraps
        // SwiftUI doesn't have a native flow layout, so we use a LazyVGrid with adaptive
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: section.config.itemSpacing)],
            spacing: section.config.lineSpacing
        ) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                RenderNodeView(node: child, tree: tree, actionContext: actionContext)
            }
        }
    }
}

