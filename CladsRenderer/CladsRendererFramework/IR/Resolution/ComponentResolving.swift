//
//  ComponentResolving.swift
//  CladsRendererFramework
//
//  Protocol for component-specific resolvers.
//

import Foundation
import SwiftUI

// MARK: - Resolution Result

/// Result of resolving a component.
/// ViewNode is populated only when tracking is enabled.
public struct ComponentResolutionResult {
    /// The resolved render node for rendering
    public let renderNode: RenderNode

    /// The view node for dependency tracking (nil when not tracking)
    public let viewNode: ViewNode?

    public init(renderNode: RenderNode, viewNode: ViewNode? = nil) {
        self.renderNode = renderNode
        self.viewNode = viewNode
    }

    /// Creates a result without tracking
    public static func renderOnly(_ node: RenderNode) -> ComponentResolutionResult {
        ComponentResolutionResult(renderNode: node, viewNode: nil)
    }

    /// Creates a result with both render and view nodes
    public static func withTracking(_ renderNode: RenderNode, viewNode: ViewNode) -> ComponentResolutionResult {
        ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }
}

/// Result of resolving a node (component, layout, or spacer)
public struct NodeResolutionResult {
    public let renderNode: RenderNode
    public let viewNode: ViewNode?

    public init(renderNode: RenderNode, viewNode: ViewNode? = nil) {
        self.renderNode = renderNode
        self.viewNode = viewNode
    }
}

// MARK: - Component Resolving Protocol

/// Protocol for resolvers that handle specific component types.
///
/// Each implementation handles one `Document.Component.Kind` and knows how to:
/// 1. Build the appropriate `RenderNode`
/// 2. Build a `ViewNode` for dependency tracking (when enabled)
/// 3. Track state dependencies
///
/// Example:
/// ```swift
/// struct TextComponentResolver: ComponentResolving {
///     static let componentKind: Document.Component.Kind = .label
///
///     func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
///         // Build TextNode and optionally ViewNode
///     }
/// }
/// ```
public protocol ComponentResolving {
    /// The component kind this resolver handles
    static var componentKind: Document.Component.Kind { get }

    /// Resolves a component into render and view nodes
    /// - Parameters:
    ///   - component: The component to resolve
    ///   - context: The shared resolution context
    /// - Returns: Resolution result containing render node and optional view node
    @MainActor
    func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult
}

// MARK: - Layout Resolving Protocol

/// Protocol for resolvers that handle layout containers.
public protocol LayoutResolving {
    /// Resolves a layout into render and view nodes
    @MainActor
    func resolve(_ layout: Document.Layout, context: ResolutionContext) throws -> NodeResolutionResult
}

// MARK: - Section Resolving Protocol

/// Protocol for resolvers that handle section layouts.
public protocol SectionLayoutResolving {
    /// Resolves a section layout into render and view nodes
    @MainActor
    func resolve(_ sectionLayout: Document.SectionLayout, context: ResolutionContext) throws -> NodeResolutionResult
}
