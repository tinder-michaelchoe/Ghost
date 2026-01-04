//
//  UIKitNodeRendererRegistry.swift
//  CladsRendererFramework
//
//  Registry for UIKit node renderers.
//

import UIKit

/// Registry that maps RenderNodeKind to UIKitNodeRendering implementations.
///
/// The registry dispatches render calls to the appropriate renderer based on node type.
///
/// Example:
/// ```swift
/// let registry = UIKitNodeRendererRegistry()
/// registry.register(TextNodeRenderer())
/// registry.register(ButtonNodeRenderer())
/// // ... register other renderers
/// let context = UIKitRenderContext(...)
/// let view = registry.render(node, context: context)
/// ```
public final class UIKitNodeRendererRegistry: @unchecked Sendable {

    // MARK: - Storage

    private var renderers: [RenderNodeKind: any UIKitNodeRendering] = [:]
    private let queue = DispatchQueue(label: "com.clads.uikitNodeRendererRegistry", attributes: .concurrent)

    // MARK: - Initialization

    public init() {}

    // MARK: - Registration

    /// Register a renderer for its node kind
    public func register(_ renderer: any UIKitNodeRendering) {
        queue.async(flags: .barrier) {
            self.renderers[type(of: renderer).nodeKind] = renderer
        }
    }

    /// Unregister a renderer for a node kind
    public func unregister(_ kind: RenderNodeKind) {
        queue.async(flags: .barrier) {
            self.renderers.removeValue(forKey: kind)
        }
    }

    // MARK: - Rendering

    /// Render a node using the appropriate registered renderer
    /// - Parameters:
    ///   - node: The RenderNode to render
    ///   - context: The rendering context
    /// - Returns: The rendered UIView
    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        var renderer: (any UIKitNodeRendering)?
        queue.sync {
            renderer = renderers[node.kind]
        }
        guard let renderer = renderer else {
            assertionFailure("No renderer registered for node kind: \(node.kind)")
            return UIView()
        }
        return renderer.render(node, context: context)
    }

    /// Check if a renderer is registered for a node kind
    public func hasRenderer(for kind: RenderNodeKind) -> Bool {
        var result = false
        queue.sync {
            result = renderers[kind] != nil
        }
        return result
    }

}
