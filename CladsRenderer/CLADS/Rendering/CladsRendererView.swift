//
//  CladsRendererView.swift
//  CladsRendererFramework
//
//  Main entry point for rendering a document using the LLVM-inspired pipeline:
//  Document (AST) → Resolver → RenderTree (IR) → SwiftUIRenderer → View
//

import SwiftUI
import Combine

/// Main entry point for rendering a document
public struct CladsRendererView: View {
    private let renderTree: RenderTree
    @StateObject private var actionContext: ActionContext

    @Environment(\.dismiss) private var dismiss

    private let swiftuiRendererRegistry: SwiftUINodeRendererRegistry

    /// Initialize with a document and registries.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - actionRegistry: Registry for action handlers (may include merged custom actions)
    ///   - componentRegistry: Registry for component resolvers
    ///   - swiftuiRendererRegistry: Registry for SwiftUI renderers
    ///   - actionDelegate: Delegate for handling custom actions
    public init(
        document: Document.Definition,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        swiftuiRendererRegistry: SwiftUINodeRendererRegistry,
        actionDelegate: CladsActionDelegate? = nil
    ) {
        self.swiftuiRendererRegistry = swiftuiRendererRegistry

        // Resolve Document (AST) into RenderTree (IR)
        let resolver = Resolver(document: document, componentRegistry: componentRegistry)
        let tree: RenderTree
        do {
            tree = try resolver.resolve()
        } catch {
            tree = RenderTree(
                root: RootNode(),
                stateStore: StateStore(),
                actions: [:]
            )
        }
        self.renderTree = tree

        // Create ActionContext with the resolved state store
        let ctx = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: actionRegistry,
            actionDelegate: actionDelegate
        )
        _actionContext = StateObject(wrappedValue: ctx)
    }

    public var body: some View {
        // Use SwiftUIRenderer to render the RenderTree
        let renderer = SwiftUIRenderer(
            actionContext: actionContext,
            rendererRegistry: swiftuiRendererRegistry
        )
        renderer.render(renderTree)
            .onAppear {
                setupContext()
            }
    }

    private func setupContext() {
        actionContext.dismissHandler = { [dismiss] in
            dismiss()
        }

        actionContext.alertHandler = { config in
            AlertPresenter.present(config)
        }
    }
}

// MARK: - Convenience Initializers

extension CladsRendererView {
    /// Initialize from a JSON string
    public init?(
        jsonString: String,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        swiftuiRendererRegistry: SwiftUINodeRendererRegistry,
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(
            document: document,
            actionRegistry: actionRegistry,
            componentRegistry: componentRegistry,
            swiftuiRendererRegistry: swiftuiRendererRegistry,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }

    /// Initialize from a Document with optional debug output
    public init(
        document: Document.Definition,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        swiftuiRendererRegistry: SwiftUINodeRendererRegistry,
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool
    ) {
        self.swiftuiRendererRegistry = swiftuiRendererRegistry

        // Resolve Document (AST) into RenderTree (IR)
        let resolver = Resolver(document: document, componentRegistry: componentRegistry)
        let tree: RenderTree
        do {
            tree = try resolver.resolve()
        } catch {
            print("CladsRendererView: Resolution failed - \(error)")
            tree = RenderTree(
                root: RootNode(),
                stateStore: StateStore(),
                actions: [:]
            )
        }
        self.renderTree = tree

        // Print RenderTree debug output if enabled
        if debugMode {
            let debugRenderer = DebugRenderer()
            print(debugRenderer.render(tree))
        }

        // Create ActionContext with the resolved state store
        let ctx = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: actionRegistry,
            actionDelegate: actionDelegate
        )
        _actionContext = StateObject(wrappedValue: ctx)
    }
}

// MARK: - Binding-based API

/// Configuration for CladsRendererBindingView with external state binding
public struct CladsRendererBindingConfiguration<State: Codable> {
    /// Initial typed state (will be merged with document state)
    public var initialState: State?

    /// Called when state changes (for analytics, persistence, etc.)
    public var onStateChange: ((_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void)?

    /// Called when an action is executed
    public var onAction: ((_ actionId: String, _ parameters: [String: Any]) -> Void)?

    /// Registry for action handlers (may include merged custom actions)
    public var actionRegistry: ActionRegistry

    /// Registry for component resolvers
    public var componentRegistry: ComponentResolverRegistry

    /// Registry for SwiftUI renderers
    public var swiftuiRendererRegistry: SwiftUINodeRendererRegistry

    /// Delegate for handling custom actions
    public weak var actionDelegate: CladsActionDelegate?

    /// Enable debug mode
    public var debugMode: Bool

    public init(
        initialState: State? = nil,
        onStateChange: ((_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void)? = nil,
        onAction: ((_ actionId: String, _ parameters: [String: Any]) -> Void)? = nil,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        swiftuiRendererRegistry: SwiftUINodeRendererRegistry,
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        self.initialState = initialState
        self.onStateChange = onStateChange
        self.onAction = onAction
        self.actionRegistry = actionRegistry
        self.componentRegistry = componentRegistry
        self.swiftuiRendererRegistry = swiftuiRendererRegistry
        self.actionDelegate = actionDelegate
        self.debugMode = debugMode
    }
}

/// View wrapper that syncs state with an external Binding
public struct CladsRendererBindingView<State: Codable & Equatable>: View {
    private let document: Document.Definition
    private let configuration: CladsRendererBindingConfiguration<State>
    @Binding private var state: State

    @StateObject private var renderContext: BindingRenderContext<State>
    @Environment(\.dismiss) private var dismiss

    public init(
        document: Document.Definition,
        state: Binding<State>,
        configuration: CladsRendererBindingConfiguration<State>
    ) {
        self.document = document
        self._state = state
        self.configuration = configuration

        // Create render context
        let context = BindingRenderContext<State>(
            document: document,
            configuration: configuration
        )
        _renderContext = StateObject(wrappedValue: context)
    }

    public var body: some View {
        Group {
            if let renderTree = renderContext.renderTree {
                let renderer = SwiftUIRenderer(actionContext: renderContext.actionContext, rendererRegistry: configuration.swiftuiRendererRegistry)
                renderer.render(renderTree)
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            setupContext()
            renderContext.syncFromExternal(state)
        }
        .onChange(of: state) { _, newValue in
            renderContext.syncFromExternal(newValue)
        }
        .onReceive(renderContext.$internalState) { newState in
            if let newState = newState {
                state = newState
            }
        }
    }

    private func setupContext() {
        renderContext.actionContext.dismissHandler = { [dismiss] in
            dismiss()
        }
        renderContext.actionContext.alertHandler = { config in
            AlertPresenter.present(config)
        }
    }
}

/// Internal context for binding-based rendering
class BindingRenderContext<State: Codable>: ObservableObject {
    @Published var internalState: State?
    @Published var renderTree: RenderTree?

    @MainActor
    var actionContext: ActionContext {
        _actionContext
    }
    private var _actionContext: ActionContext!
    private var stateStore: StateStore!
    private var stateCallbackId: UUID?
    private let configuration: CladsRendererBindingConfiguration<State>

    @MainActor
    init(document: Document.Definition, configuration: CladsRendererBindingConfiguration<State>) {
        self.configuration = configuration

        // Resolve document
        let resolver = Resolver(document: document, componentRegistry: configuration.componentRegistry)
        let tree: RenderTree
        do {
            tree = try resolver.resolve()
        } catch {
            print("BindingRenderContext: Resolution failed - \(error)")
            tree = RenderTree(root: RootNode(), stateStore: StateStore(), actions: [:])
        }

        self.renderTree = tree
        self.stateStore = tree.stateStore

        // Create action context
        self._actionContext = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: configuration.actionRegistry,
            actionDelegate: configuration.actionDelegate
        )

        // Set up state change callback
        if let onStateChange = configuration.onStateChange {
            stateCallbackId = stateStore.onStateChange { path, oldValue, newValue in
                onStateChange(path, oldValue, newValue)
            }
        }

        // Also sync internal state on every change
        _ = stateStore.onStateChange { [weak self] _, _, _ in
            Task { @MainActor in
                self?.syncToExternal()
            }
        }

        // Initialize with external state if provided
        if let initialState = configuration.initialState {
            stateStore.setTyped(initialState)
        }

        // Print debug if enabled
        if configuration.debugMode {
            let debugRenderer = DebugRenderer()
            print(debugRenderer.render(tree))
        }
    }

    @MainActor
    func syncFromExternal(_ state: State) {
        stateStore.setTyped(state)
    }

    @MainActor
    func syncToExternal() {
        internalState = stateStore.getTyped(State.self)
    }

    @MainActor
    func cleanup() {
        if let id = stateCallbackId {
            stateStore.removeStateChangeCallback(id)
        }
    }
}

// MARK: - Convenience Extensions for Binding API

extension CladsRendererBindingView where State: Equatable {
    /// Initialize from a JSON string with state binding
    public init?(
        jsonString: String,
        state: Binding<State>,
        configuration: CladsRendererBindingConfiguration<State>
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(document: document, state: state, configuration: configuration)
    }
}

// MARK: - Snapshot API

extension CladsRendererView {
    /// Get a snapshot of the current state
    public var stateSnapshot: [String: Any] {
        return renderTree.stateStore.snapshot()
    }
}

