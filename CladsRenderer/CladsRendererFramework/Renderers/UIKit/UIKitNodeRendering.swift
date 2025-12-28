//
//  UIKitNodeRendering.swift
//  CladsRendererFramework
//
//  Protocol and context for UIKit node rendering.
//

import UIKit

// MARK: - Render Context

/// Context for UIKit node rendering, providing shared dependencies
public final class UIKitRenderContext {
    public let actionContext: ActionContext
    public let stateStore: StateStore
    public let colorScheme: RenderColorScheme

    private let registry: UIKitNodeRendererRegistry

    public init(
        actionContext: ActionContext,
        stateStore: StateStore,
        colorScheme: RenderColorScheme,
        registry: UIKitNodeRendererRegistry
    ) {
        self.actionContext = actionContext
        self.stateStore = stateStore
        self.colorScheme = colorScheme
        self.registry = registry
    }

    /// Render a child node (for recursive rendering)
    public func render(_ node: RenderNode) -> UIView {
        registry.render(node, context: self)
    }
}

// MARK: - Node Rendering Protocol

/// Protocol for rendering specific RenderNode types to UIKit views.
///
/// Implement this protocol to create a renderer for a specific node type.
/// Each implementation handles one `RenderNode.Kind`.
///
/// Example:
/// ```swift
/// public struct TextNodeRenderer: UIKitNodeRendering {
///     public static let nodeKind: RenderNode.Kind = .text
///
///     public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
///         guard case .text(let textNode) = node else {
///             return UIView()
///         }
///         // ... render the text node
///     }
/// }
/// ```
public protocol UIKitNodeRendering {
    /// The RenderNode.Kind this renderer handles
    static var nodeKind: RenderNode.Kind { get }

    /// Initialize the renderer
    init()

    /// Render the node to a UIView
    /// - Parameters:
    ///   - node: The RenderNode to render (will match `nodeKind`)
    ///   - context: The rendering context with shared dependencies
    /// - Returns: The rendered UIView
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView
}
