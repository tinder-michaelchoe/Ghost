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

    /// Initialize with a document and optional custom action handlers.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - registry: The global action registry (default: `.shared`)
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// CladsRendererView(
    ///     document: document,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             let orderId = context.stateStore.get("order.id") as? String
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ]
    /// )
    /// ```
    public init(
        document: Document.Definition,
        registry: ActionRegistry = .shared,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        // Resolve Document (AST) into RenderTree (IR)
        let resolver = Resolver(document: document)
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

        // Create ActionContext with the resolved state store and custom actions
        let ctx = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: registry,
            customActions: customActions,
            actionDelegate: actionDelegate
        )
        _actionContext = StateObject(wrappedValue: ctx)
    }

    public var body: some View {
        // Use SwiftUIRenderer to render the RenderTree
        let renderer = SwiftUIRenderer(actionContext: actionContext)
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
    /// - Parameters:
    ///   - jsonString: The JSON string to parse
    ///   - registry: The action registry to use
    ///   - customActions: View-specific action closures
    ///   - actionDelegate: Delegate for handling custom actions
    ///   - debugMode: Whether to print debug output when parsing
    public init?(
        jsonString: String,
        registry: ActionRegistry = .shared,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(
            document: document,
            registry: registry,
            customActions: customActions,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }

    /// Initialize from a Document with optional debug output
    public init(
        document: Document.Definition,
        registry: ActionRegistry = .shared,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool
    ) {
        // Resolve Document (AST) into RenderTree (IR)
        let resolver = Resolver(document: document)
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

        // Create ActionContext with the resolved state store and custom actions
        let ctx = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: registry,
            customActions: customActions,
            actionDelegate: actionDelegate
        )
        _actionContext = StateObject(wrappedValue: ctx)
    }
}

// MARK: - Binding-based API

/// Configuration for CladsRendererView with external state binding
public struct CladsRendererConfiguration<State: Codable> {
    /// Initial typed state (will be merged with document state)
    public var initialState: State?

    /// Called when state changes (for analytics, persistence, etc.)
    public var onStateChange: ((_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void)?

    /// Called when an action is executed
    public var onAction: ((_ actionId: String, _ parameters: [String: Any]) -> Void)?

    /// Custom action registry
    public var actionRegistry: ActionRegistry

    /// View-specific action closures
    public var customActions: [String: ActionClosure]

    /// Delegate for handling custom actions
    public weak var actionDelegate: CladsActionDelegate?

    /// Enable debug mode
    public var debugMode: Bool

    public init(
        initialState: State? = nil,
        onStateChange: ((_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void)? = nil,
        onAction: ((_ actionId: String, _ parameters: [String: Any]) -> Void)? = nil,
        actionRegistry: ActionRegistry = .shared,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        self.initialState = initialState
        self.onStateChange = onStateChange
        self.onAction = onAction
        self.actionRegistry = actionRegistry
        self.customActions = customActions
        self.actionDelegate = actionDelegate
        self.debugMode = debugMode
    }
}

/// View wrapper that syncs state with an external Binding
public struct CladsRendererBindingView<State: Codable & Equatable>: View {
    private let document: Document.Definition
    private let configuration: CladsRendererConfiguration<State>
    @Binding private var state: State

    @StateObject private var renderContext: BindingRenderContext<State>
    @Environment(\.dismiss) private var dismiss

    public init(
        document: Document.Definition,
        state: Binding<State>,
        configuration: CladsRendererConfiguration<State> = CladsRendererConfiguration()
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
                let renderer = SwiftUIRenderer(actionContext: renderContext.actionContext)
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
    private let configuration: CladsRendererConfiguration<State>

    @MainActor
    init(document: Document.Definition, configuration: CladsRendererConfiguration<State>) {
        self.configuration = configuration

        // Resolve document
        let resolver = Resolver(document: document)
        let tree: RenderTree
        do {
            tree = try resolver.resolve()
        } catch {
            print("BindingRenderContext: Resolution failed - \(error)")
            tree = RenderTree(root: RootNode(), stateStore: StateStore(), actions: [:])
        }

        self.renderTree = tree
        self.stateStore = tree.stateStore

        // Create action context with custom actions
        self._actionContext = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: configuration.actionRegistry,
            customActions: configuration.customActions,
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
        configuration: CladsRendererConfiguration<State> = CladsRendererConfiguration()
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

