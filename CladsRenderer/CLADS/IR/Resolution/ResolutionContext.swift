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

    // MARK: - Iteration Variables

    /// Variables from forEach loops (e.g., "item", "index")
    public let iterationVariables: [String: Any]

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
        parentViewNode: ViewNode? = nil,
        iterationVariables: [String: Any] = [:]
    ) {
        self.document = document
        self.styleResolver = styleResolver
        self.stateStore = stateStore
        self.tracker = tracker
        self.parentViewNode = parentViewNode
        self.iterationVariables = iterationVariables
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
            parentViewNode: viewNode,
            iterationVariables: iterationVariables
        )
    }

    /// Creates a child context with iteration variables (for forEach loops)
    public func withIterationVariables(_ variables: [String: Any]) -> ResolutionContext {
        // Merge with existing variables (new ones take precedence)
        var merged = iterationVariables
        for (key, value) in variables {
            merged[key] = value
        }
        return ResolutionContext(
            document: document,
            styleResolver: styleResolver,
            stateStore: stateStore,
            tracker: tracker,
            parentViewNode: parentViewNode,
            iterationVariables: merged
        )
    }

    /// Get a value, checking iteration variables first, then state store
    @MainActor
    public func getValue(_ keypath: String) -> Any? {
        // Check iteration variables first
        if let value = iterationVariables[keypath] {
            return value
        }
        // Then check state store
        return stateStore.get(keypath)
    }

    /// Interpolate a template string, using iteration variables and state
    @MainActor
    public func interpolate(_ template: String) -> String {
        var result = template
        let pattern = #"\$\{([^}]+)\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return template
        }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range, in: template),
                  let keypathRange = Range(match.range(at: 1), in: template) else {
                continue
            }

            let expression = String(template[keypathRange])

            // Check iteration variables first
            let value: Any?
            if let iterValue = iterationVariables[expression] {
                value = iterValue
            } else if let arrayResult = stateStore.evaluate(expression: expression) as? Bool {
                // Handle boolean results from array expressions like contains()
                value = arrayResult
            } else {
                value = stateStore.get(expression) ?? stateStore.evaluate(expression: expression)
            }

            let replacement = stringValue(from: value)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }

    private func stringValue(from value: Any?) -> String {
        switch value {
        case let int as Int: return String(int)
        case let double as Double: return String(double)
        case let string as String: return string
        case let bool as Bool: return String(bool)
        case nil: return ""
        default: return String(describing: value)
        }
    }
}
