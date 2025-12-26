//
//  CladsRendererView.swift
//  CladsRendererFramework
//
//  Main entry point for rendering a document using the LLVM-inspired pipeline:
//  Document (AST) → Resolver → RenderTree (IR) → SwiftUIRenderer → View
//

import SwiftUI

/// Main entry point for rendering a document
public struct CladsRendererView: View {
    private let renderTree: RenderTree
    @StateObject private var actionContext: ActionContext

    @Environment(\.dismiss) private var dismiss

    public init(document: Document, registry: ActionRegistry = .shared) {
        // Resolve Document (AST) into RenderTree (IR)
        let resolver = Resolver(document: document)
        let tree: RenderTree
        do {
            tree = try resolver.resolve()
        } catch {
            // Fallback to empty tree on resolution error
            print("CladsRendererView: Resolution failed - \(error)")
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
            registry: registry
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

// MARK: - JSON Parsing

public struct Parser {
    /// Whether to print debug output when parsing
    public var debugMode: Bool

    public init(debugMode: Bool = false) {
        self.debugMode = debugMode
    }

    /// Parse a JSON string into a Document
    public func parse(_ jsonString: String) throws -> Document {
        guard let data = jsonString.data(using: .utf8) else {
            throw ParserError.invalidEncoding
        }
        return try parse(data)
    }

    /// Parse JSON data into a Document
    public func parse(_ data: Data) throws -> Document {
        let decoder = JSONDecoder()
        do {
            let document = try decoder.decode(Document.self, from: data)
            if debugMode {
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print(document.debugDescription)
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            }
            return document
        } catch let error as DecodingError {
            throw ParserError.decodingError(error)
        }
    }
}

public enum ParserError: Error, LocalizedError {
    case invalidEncoding
    case decodingError(DecodingError)

    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Invalid string encoding"
        case .decodingError(let error):
            return "JSON decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Initializers

extension CladsRendererView {
    /// Initialize from a JSON string
    /// - Parameters:
    ///   - jsonString: The JSON string to parse
    ///   - registry: The action registry to use
    ///   - debugMode: Whether to print debug output when parsing
    public init?(jsonString: String, registry: ActionRegistry = .shared, debugMode: Bool = false) {
        let parser = Parser(debugMode: debugMode)
        guard let document = try? parser.parse(jsonString) else {
            return nil
        }
        self.init(document: document, registry: registry, debugMode: debugMode)
    }

    /// Initialize from a Document with optional debug output
    public init(document: Document, registry: ActionRegistry = .shared, debugMode: Bool) {
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

        // Create ActionContext with the resolved state store
        let ctx = ActionContext(
            stateStore: tree.stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: registry
        )
        _actionContext = StateObject(wrappedValue: ctx)
    }
}

// MARK: - Edge Insets Modifier

struct EdgeInsetsModifier: ViewModifier {
    let insets: EdgeInsets?

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.top, insets?.top?.padding ?? 0)
            .safeAreaPadding(.bottom, insets?.bottom?.padding ?? 0)
            .safeAreaPadding(.leading, insets?.leading?.padding ?? 0)
            .safeAreaPadding(.trailing, insets?.trailing?.padding ?? 0)
            .ignoresSafeArea(edges: absoluteEdges())
    }

    /// Determine which edges should ignore safe area (absolute mode)
    private func absoluteEdges() -> Edge.Set {
        guard let insets = insets else { return [] }

        var edges: Edge.Set = []
        if insets.top?.isAbsolute == true { edges.insert(.top) }
        if insets.bottom?.isAbsolute == true { edges.insert(.bottom) }
        if insets.leading?.isAbsolute == true { edges.insert(.leading) }
        if insets.trailing?.isAbsolute == true { edges.insert(.trailing) }
        return edges
    }
}
