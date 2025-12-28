//
//  UIKitNodeRendererRegistry.swift
//  CladsRendererFramework
//
//  Registry for UIKit node renderers.
//

import UIKit

/// Registry that maps RenderNode.Kind to UIKitNodeRendering implementations.
///
/// The registry dispatches render calls to the appropriate renderer based on node type.
///
/// Example:
/// ```swift
/// let registry = UIKitNodeRendererRegistry.default
/// let context = UIKitRenderContext(...)
/// let view = registry.render(node, context: context)
/// ```
public struct UIKitNodeRendererRegistry {

    private var renderers: [RenderNode.Kind: any UIKitNodeRendering]

    // MARK: - Initialization

    public init() {
        self.renderers = [:]
    }

    /// Default registry with all standard node renderers
    public static var `default`: UIKitNodeRendererRegistry {
        var registry = UIKitNodeRendererRegistry()
        registry.register(TextNodeRenderer())
        registry.register(ButtonNodeRenderer())
        registry.register(TextFieldNodeRenderer())
        registry.register(ImageNodeRenderer())
        registry.register(GradientNodeRenderer())
        registry.register(SpacerNodeRenderer())
        registry.register(ContainerNodeRenderer())
        registry.register(SectionLayoutNodeRenderer())
        return registry
    }

    // MARK: - Registration

    /// Register a renderer for its node kind
    public mutating func register(_ renderer: any UIKitNodeRendering) {
        renderers[type(of: renderer).nodeKind] = renderer
    }

    // MARK: - Rendering

    /// Render a node using the appropriate registered renderer
    /// - Parameters:
    ///   - node: The RenderNode to render
    ///   - context: The rendering context
    /// - Returns: The rendered UIView
    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard let renderer = renderers[node.kind] else {
            assertionFailure("No renderer registered for node kind: \(node.kind)")
            return UIView()
        }
        return renderer.render(node, context: context)
    }
}
