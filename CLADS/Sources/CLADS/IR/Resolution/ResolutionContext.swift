//
//  ResolutionContext.swift
//  CladsRendererFramework
//
//  Shared context passed to all resolvers during document resolution.
//

import Foundation
import SwiftUI

/// Context shared across all resolvers during document resolution.
/// Encapsulates all dependencies needed for resolution, eliminating parameter threading.
public final class ResolutionContext {

    // MARK: - Document & Styles

    /// The source document being resolved
    public let document: Document.Definition

    /// Resolver for style inheritance
    public let styleResolver: StyleResolver

    // MARK: - State

    /// The state store for data binding
    public let stateStore: StateStore

    // MARK: - Dependency Tracking (Optional)

    /// Dependency tracker for reactive updates. Nil when tracking is disabled.
    public let tracker: DependencyTracker?

    /// Whether dependency tracking is enabled
    public var isTracking: Bool { tracker != nil }

    // MARK: - Tree Building

    /// Current parent view node (used when building ViewNode tree)
    public weak var parentViewNode: ViewNode?

    // MARK: - Initialization

    public init(
        document: Document.Definition,
        styleResolver: StyleResolver,
        stateStore: StateStore,
        tracker: DependencyTracker? = nil,
        parentViewNode: ViewNode? = nil
    ) {
        self.document = document
        self.styleResolver = styleResolver
        self.stateStore = stateStore
        self.tracker = tracker
        self.parentViewNode = parentViewNode
    }

    // MARK: - Convenience Factory

    /// Creates a context for resolving without dependency tracking
    public static func withoutTracking(
        document: Document.Definition,
        stateStore: StateStore
    ) -> ResolutionContext {
        ResolutionContext(
            document: document,
            styleResolver: StyleResolver(styles: document.styles),
            stateStore: stateStore,
            tracker: nil
        )
    }

    /// Creates a context for resolving with dependency tracking
    public static func withTracking(
        document: Document.Definition,
        stateStore: StateStore,
        tracker: DependencyTracker
    ) -> ResolutionContext {
        ResolutionContext(
            document: document,
            styleResolver: StyleResolver(styles: document.styles),
            stateStore: stateStore,
            tracker: tracker
        )
    }

    // MARK: - Child Context

    /// Creates a child context with a new parent view node
    public func withParent(_ viewNode: ViewNode) -> ResolutionContext {
        ResolutionContext(
            document: document,
            styleResolver: styleResolver,
            stateStore: stateStore,
            tracker: tracker,
            parentViewNode: viewNode
        )
    }
}
