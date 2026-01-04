//
//  GradientNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for GradientNode.
//

import CLADS
import SwiftUI

// MARK: - Gradient Node SwiftUI Renderer

public struct GradientNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.gradient

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .gradient(let gradientNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            GradientNodeView(node: gradientNode, colorScheme: context.tree.root.colorScheme)
        )
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
