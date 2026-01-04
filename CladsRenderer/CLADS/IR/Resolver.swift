//
//  Resolver.swift
//  CladsRendererFramework
//
//  Resolves a Document (AST) into a RenderTree (IR).
//  Orchestrates resolution by delegating to specialized resolvers.
//

import Foundation
import SwiftUI

// MARK: - Resolution Result

/// Result of resolving a document, including both render tree and view tree
public struct ResolutionResult {
    public let renderTree: RenderTree
    public let viewTreeRoot: ViewNode
    public let treeUpdater: ViewTreeUpdater

    public init(renderTree: RenderTree, viewTreeRoot: ViewNode, treeUpdater: ViewTreeUpdater) {
        self.renderTree = renderTree
        self.viewTreeRoot = viewTreeRoot
        self.treeUpdater = treeUpdater
    }
}

// MARK: - Resolver

/// Resolves a Document into a RenderTree.
///
/// The Resolver orchestrates the resolution process by delegating to specialized resolvers:
/// - `ComponentResolverRegistry` for component resolution
/// - `LayoutResolver` for container layouts
/// - `SectionLayoutResolver` for section-based layouts
/// - `ActionResolver` for action definitions
///
/// Example:
/// ```swift
/// let resolver = Resolver(document: document)
/// let renderTree = try resolver.resolve()
///
/// // For testing, inject a pre-configured StateStore:
/// let stateStore = StateStore()
/// stateStore.set("testValue", value: 42)
/// let renderTree = try resolver.resolve(into: stateStore)
/// ```
public struct Resolver {
    private let document: Document.Definition
    private let componentRegistry: ComponentResolverRegistry
    private let actionResolver: ActionResolver

    // MARK: - Initialization

    public init(
        document: Document.Definition,
        componentRegistry: ComponentResolverRegistry
    ) {
        self.document = document
        self.componentRegistry = componentRegistry
        self.actionResolver = ActionResolver()
    }

    // MARK: - Public API

    /// Resolve the document into a render tree (without dependency tracking)
    ///
    /// Creates a new StateStore and initializes it from the document state.
    @MainActor
    public func resolve() throws -> RenderTree {
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        return try resolve(into: stateStore)
    }

    /// Resolve the document into a render tree using a provided StateStore.
    ///
    /// This allows injecting a pre-configured StateStore for testing,
    /// or reusing an existing StateStore.
    ///
    /// - Parameter stateStore: The state store to use. Document state will be
    ///   merged into this store (existing values are preserved, document values added).
    /// - Parameter initializeFromDocument: Whether to initialize state from the document.
    ///   Set to `false` if the store is already configured. Default is `true`.
    /// - Returns: The resolved render tree.
    ///
    /// Example:
    /// ```swift
    /// // For testing with pre-set state:
    /// let stateStore = StateStore()
    /// stateStore.set("count", value: 10)
    /// let tree = try resolver.resolve(into: stateStore, initializeFromDocument: false)
    ///
    /// // The tree uses the injected state, not the document's initial state
    /// XCTAssertEqual(tree.stateStore.get("count") as? Int, 10)
    /// ```
    @MainActor
    public func resolve(
        into stateStore: StateStore,
        initializeFromDocument: Bool = true
    ) throws -> RenderTree {
        if initializeFromDocument {
            stateStore.initialize(from: document.state)
        }

        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )

        let actions = actionResolver.resolveAll(document.actions)
        let rootNode = try resolveRoot(document.root, context: context)

        return RenderTree(
            root: rootNode,
            stateStore: stateStore,
            actions: actions
        )
    }

    /// Resolve the document with full dependency tracking
    ///
    /// Creates a new StateStore and initializes it from the document state.
    @MainActor
    public func resolveWithTracking() throws -> ResolutionResult {
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        return try resolveWithTracking(into: stateStore)
    }

    /// Resolve the document with full dependency tracking using a provided StateStore.
    ///
    /// This allows injecting a pre-configured StateStore for testing.
    ///
    /// - Parameter stateStore: The state store to use.
    /// - Parameter initializeFromDocument: Whether to initialize state from the document.
    /// - Returns: The resolution result including render tree and view tree.
    @MainActor
    public func resolveWithTracking(
        into stateStore: StateStore,
        initializeFromDocument: Bool = true
    ) throws -> ResolutionResult {
        if initializeFromDocument {
            stateStore.initialize(from: document.state)
        }

        let treeUpdater = ViewTreeUpdater()
        let tracker = treeUpdater.dependencyTracker

        let context = ResolutionContext.withTracking(
            document: document,
            stateStore: stateStore,
            tracker: tracker
        )

        let actions = actionResolver.resolveAll(document.actions)
        let (rootNode, viewNode) = try resolveRootWithTracking(document.root, context: context)

        let renderTree = RenderTree(
            root: rootNode,
            stateStore: stateStore,
            actions: actions
        )

        // Set up the view tree and attach to state store
        treeUpdater.setRoot(viewNode)
        treeUpdater.attach(to: stateStore)

        return ResolutionResult(
            renderTree: renderTree,
            viewTreeRoot: viewNode,
            treeUpdater: treeUpdater
        )
    }

    // MARK: - Root Resolution

    @MainActor
    private func resolveRoot(_ root: Document.RootComponent, context: ResolutionContext) throws -> RootNode {
        let backgroundColor: Color? = root.backgroundColor.map { Color(hex: $0) }
        let colorScheme = ColorSchemeConverter.convert(root.colorScheme)
        let style = context.styleResolver.resolve(root.styleId)

        let layoutResolver = LayoutResolver(componentRegistry: componentRegistry)
        let children = try root.children.map { child -> RenderNode in
            try resolveNode(child, context: context, layoutResolver: layoutResolver).renderNode
        }

        return RootNode(
            backgroundColor: backgroundColor,
            edgeInsets: EdgeInsetsConverter.convert(root.edgeInsets),
            colorScheme: colorScheme,
            style: style,
            actions: RootActions(from: root.actions),
            children: children
        )
    }

    @MainActor
    private func resolveRootWithTracking(
        _ root: Document.RootComponent,
        context: ResolutionContext
    ) throws -> (RootNode, ViewNode) {
        let backgroundColor: Color? = root.backgroundColor.map { Color(hex: $0) }
        let colorScheme = ColorSchemeConverter.convert(root.colorScheme)
        let style = context.styleResolver.resolve(root.styleId)

        // Create view node for root
        let viewNode = ViewNode(
            id: "root",
            nodeType: .root(RootNodeData(
                backgroundColor: root.backgroundColor,
                colorScheme: colorScheme,
                style: style
            ))
        )

        // Update context with root as parent
        let childContext = context.withParent(viewNode)
        let layoutResolver = LayoutResolver(componentRegistry: componentRegistry)

        // Resolve children with tracking
        var renderChildren: [RenderNode] = []
        var viewChildren: [ViewNode] = []

        for child in root.children {
            let result = try resolveNode(child, context: childContext, layoutResolver: layoutResolver)
            renderChildren.append(result.renderNode)
            if let childViewNode = result.viewNode {
                viewChildren.append(childViewNode)
            }
        }

        viewNode.children = viewChildren

        let rootRenderNode = RootNode(
            backgroundColor: backgroundColor,
            edgeInsets: EdgeInsetsConverter.convert(root.edgeInsets),
            colorScheme: colorScheme,
            style: style,
            actions: RootActions(from: root.actions),
            children: renderChildren
        )

        return (rootRenderNode, viewNode)
    }

    // MARK: - Node Resolution

    @MainActor
    private func resolveNode(
        _ node: Document.LayoutNode,
        context: ResolutionContext,
        layoutResolver: LayoutResolver
    ) throws -> NodeResolutionResult {
        switch node {
        case .layout(let layout):
            return try layoutResolver.resolve(layout, context: context)

        case .sectionLayout(let sectionLayout):
            let sectionResolver = SectionLayoutResolver(componentRegistry: componentRegistry)
            return try sectionResolver.resolve(sectionLayout, context: context)

        case .forEach:
            return try layoutResolver.resolveNode(node, context: context)

        case .component(let component):
            let result = try componentRegistry.resolve(component, context: context)
            return NodeResolutionResult(renderNode: result.renderNode, viewNode: result.viewNode)

        case .spacer:
            let viewNode: ViewNode?
            if context.isTracking {
                viewNode = ViewNode(id: UUID().uuidString, nodeType: .spacer)
                viewNode?.parent = context.parentViewNode
            } else {
                viewNode = nil
            }
            return NodeResolutionResult(renderNode: .spacer, viewNode: viewNode)
        }
    }
}

// MARK: - Resolution Errors

public enum ResolutionError: Error, LocalizedError {
    case unknownStyle(String)
    case unknownDataSource(String)
    case unknownAction(String)
    case invalidAction(String)

    public var errorDescription: String? {
        switch self {
        case .unknownStyle(let id):
            return "Unknown style: '\(id)'"
        case .unknownDataSource(let id):
            return "Unknown data source: '\(id)'"
        case .unknownAction(let id):
            return "Unknown action: '\(id)'"
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        }
    }
}

// MARK: - Edge Insets Converter

/// Converts Document.EdgeInsets to IR.EdgeInsets
enum EdgeInsetsConverter {
    static func convert(_ documentInsets: Document.EdgeInsets?) -> IR.EdgeInsets? {
        guard let insets = documentInsets else { return nil }

        let top = insets.top.map { convert($0) }
        let bottom = insets.bottom.map { convert($0) }
        let leading = insets.leading.map { convert($0) }
        let trailing = insets.trailing.map { convert($0) }

        // Return nil if no edges are set
        if top == nil && bottom == nil && leading == nil && trailing == nil {
            return nil
        }

        return IR.EdgeInsets(top: top, bottom: bottom, leading: leading, trailing: trailing)
    }

    private static func convert(_ inset: Document.EdgeInset) -> IR.EdgeInset {
        let positioning: IR.Positioning = switch inset.positioning {
        case .safeArea: .safeArea
        case .absolute: .absolute
        }
        return IR.EdgeInset(positioning: positioning, value: inset.value)
    }
}

