//
//  ContainerNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for ContainerNode.
//

import CLADS
import SwiftUI

// MARK: - Container Node SwiftUI Renderer

public struct ContainerNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.container

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .container(let containerNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ContainerNodeView(node: containerNode, context: context)
                .environmentObject(context.tree.stateStore)
                .environmentObject(context.actionContext)
        )
    }
}

// MARK: - Container Node View

struct ContainerNodeView: View {
    let node: ContainerNode
    let context: SwiftUIRenderContext

    var body: some View {
        Group {
            switch node.layoutType {
            case .vstack:
                VStack(alignment: horizontalAlignment, spacing: node.spacing) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        renderChild(child)
                    }
                }
                .frame(maxWidth: .infinity, alignment: Alignment(horizontal: horizontalAlignment, vertical: .center))
            case .hstack:
                HStack(alignment: verticalAlignment, spacing: node.spacing) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        renderChild(child)
                    }
                }
            case .zstack:
                ZStack(alignment: zstackAlignment) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                        renderChild(child)
                    }
                }
            }
        }
        .padding(.top, node.padding.top)
        .padding(.bottom, node.padding.bottom)
        .padding(.leading, node.padding.leading)
        .padding(.trailing, node.padding.trailing)
    }

    @ViewBuilder
    private func renderChild(_ child: RenderNode) -> some View {
        context.render(child)
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
