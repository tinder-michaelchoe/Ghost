//
//  SwiftUINodeRendering.swift
//  CLADS
//
//  Protocol and registry for SwiftUI node renderers.
//  Enables extensible SwiftUI rendering for custom components.
//

import Foundation
import SwiftUI

// MARK: - SwiftUI Render Context

/// Context passed to SwiftUI node renderers
public struct SwiftUIRenderContext {
    public let tree: RenderTree
    public let actionContext: ActionContext
    public let rendererRegistry: SwiftUINodeRendererRegistry

    public init(
        tree: RenderTree,
        actionContext: ActionContext,
        rendererRegistry: SwiftUINodeRendererRegistry
    ) {
        self.tree = tree
        self.actionContext = actionContext
        self.rendererRegistry = rendererRegistry
    }

    /// Render a child node using the registry
    @MainActor
    public func render(_ node: RenderNode) -> AnyView {
        rendererRegistry.render(node, context: self) ?? AnyView(EmptyView())
    }
}

// MARK: - SwiftUI Node Rendering Protocol

/// Protocol for SwiftUI node renderers.
///
/// Each implementation handles one `RenderNodeKind` and knows how to
/// render it to a SwiftUI view.
///
/// Example:
/// ```swift
/// struct ChartSwiftUIRenderer: SwiftUINodeRendering {
///     public static let nodeKind: RenderNodeKind = .chart
///
///     public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
///         guard case .custom(_, let customNode) = node,
///               let chartNode = customNode as? ChartNode else {
///             return AnyView(EmptyView())
///         }
///         return AnyView(ChartView(node: chartNode))
///     }
/// }
/// ```
public protocol SwiftUINodeRendering {
    /// The RenderNodeKind this renderer handles
    static var nodeKind: RenderNodeKind { get }

    /// Renders the node to a SwiftUI view
    /// - Parameters:
    ///   - node: The render node to render
    ///   - context: The rendering context with tree and action context
    /// - Returns: The rendered SwiftUI view wrapped in AnyView
    @MainActor
    func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView
}

// MARK: - SwiftUI Node Renderer Registry

/// Registry for SwiftUI node renderers.
///
/// Allows custom components to register their SwiftUI renderers.
///
/// Example:
/// ```swift
/// let registry = SwiftUINodeRendererRegistry()
/// registry.register(TextNodeSwiftUIRenderer())
/// registry.register(ButtonNodeSwiftUIRenderer())
/// // ... register other renderers
/// ```
public final class SwiftUINodeRendererRegistry: @unchecked Sendable {

    // MARK: - Storage

    private var renderers: [RenderNodeKind: any SwiftUINodeRendering] = [:]
    private let queue = DispatchQueue(label: "com.clads.swiftuiNodeRendererRegistry", attributes: .concurrent)

    // MARK: - Initialization

    public init() {}

    // MARK: - Registration

    /// Registers a SwiftUI node renderer
    public func register<T: SwiftUINodeRendering>(_ renderer: T) {
        queue.async(flags: .barrier) {
            self.renderers[T.nodeKind] = renderer
        }
    }

    /// Unregisters a renderer for a node kind
    public func unregister(_ kind: RenderNodeKind) {
        queue.async(flags: .barrier) {
            self.renderers.removeValue(forKey: kind)
        }
    }

    /// Gets a renderer for a node kind
    public func renderer(for kind: RenderNodeKind) -> (any SwiftUINodeRendering)? {
        var result: (any SwiftUINodeRendering)?
        queue.sync {
            result = renderers[kind]
        }
        return result
    }

    /// Checks if a renderer is registered for a node kind
    public func hasRenderer(for kind: RenderNodeKind) -> Bool {
        var result = false
        queue.sync {
            result = renderers[kind] != nil
        }
        return result
    }

    /// Renders a custom node using the registered renderer
    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView? {
        guard let renderer = renderer(for: node.kind) else {
            return nil
        }
        return renderer.render(node, context: context)
    }

}
