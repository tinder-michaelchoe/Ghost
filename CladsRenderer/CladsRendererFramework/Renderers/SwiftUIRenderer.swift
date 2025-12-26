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

        case .text(let text):
            TextNodeView(node: text)

        case .button(let button):
            ButtonNodeView(node: button, actionContext: actionContext)

        case .textField(let textField):
            TextFieldNodeView(node: textField)

        case .image(let image):
            ImageNodeView(node: image)

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
            switch node.axis {
            case .vertical:
                VStack(alignment: horizontalAlignment, spacing: node.spacing) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        RenderNodeView(node: child, tree: tree, actionContext: actionContext)
                    }
                }
            case .horizontal:
                HStack(alignment: verticalAlignment, spacing: node.spacing) {
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
        switch node.alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    private var verticalAlignment: SwiftUI.VerticalAlignment {
        switch node.alignment {
        case .top: return .top
        case .bottom: return .bottom
        default: return .center
        }
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
        guard let actionId = node.onTap else { return }
        Task { @MainActor in
            await actionContext.executeAction(id: actionId)
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
                }
            }
        }
        .frame(width: node.style.width, height: node.style.height)
    }
}

