//
//  DividerNodeView.swift
//  CladsModules
//
//  SwiftUI renderer for Divider.
//

import CLADS
import SwiftUI

// MARK: - Divider Node SwiftUI Renderer

public struct DividerNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.divider

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .divider(let dividerNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(DividerNodeView(node: dividerNode))
    }
}

// MARK: - Divider Node View

struct DividerNodeView: View {
    let node: DividerNode

    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }

    private var height: CGFloat {
        node.style.height ?? 1
    }

    private var backgroundColor: Color {
        if let color = node.style.backgroundColor {
            return color
        }
        return Color(UIColor.separator)
    }
}
