//
//  CustomComponentSwiftUIRenderer.swift
//  CLADS
//
//  SwiftUI renderer for custom components.
//

import Foundation
import SwiftUI

/// SwiftUI renderer for custom components.
///
/// This renderer handles `CustomComponentRenderNode` by looking up the registered
/// `CustomComponent` implementation and delegating rendering to it.
public struct CustomComponentSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind: RenderNodeKind = .customComponent

    private let customComponentRegistry: CustomComponentRegistry

    public init(customComponentRegistry: CustomComponentRegistry) {
        self.customComponentRegistry = customComponentRegistry
    }

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        // Extract the CustomComponentRenderNode
        guard case .custom(_, let customNode) = node,
              let componentNode = customNode as? CustomComponentRenderNode else {
            return AnyView(
                Text("Invalid custom component node")
                    .foregroundColor(.red)
            )
        }

        // Look up the registered CustomComponent type
        guard let componentType = customComponentRegistry.componentType(for: componentNode.typeName) else {
            return AnyView(
                Text("Unknown custom component: \(componentNode.typeName)")
                    .foregroundColor(.red)
            )
        }

        // Create the context for the custom component
        let customContext = CustomComponentContext(
            style: componentNode.style,
            stateStore: context.tree.stateStore,
            actionContext: context.actionContext,
            tree: context.tree,
            component: componentNode.component
        )

        // Call the static makeView method on the registered component type
        return componentType.makeView(context: customContext)
    }
}

