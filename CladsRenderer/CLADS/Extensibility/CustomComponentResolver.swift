//
//  CustomComponentResolver.swift
//  CLADS
//
//  Resolver for custom components registered via CustomComponentRegistry.
//

import Foundation
import SwiftUI

/// Resolver for custom components.
///
/// This resolver handles any component type that is registered in the `CustomComponentRegistry`.
/// It creates a `CustomComponentRenderNode` that defers actual rendering to the registered
/// `CustomComponent` implementation.
///
/// Unlike built-in component resolvers which handle a single fixed type, this resolver
/// dynamically handles any registered custom component type.
public struct CustomComponentResolver {

    private let registry: CustomComponentRegistry

    public init(registry: CustomComponentRegistry) {
        self.registry = registry
    }

    /// Check if this resolver can handle the given component type
    public func canResolve(_ componentKind: Document.ComponentKind) -> Bool {
        registry.isRegistered(componentKind.rawValue)
    }

    /// Resolve a custom component
    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let typeName = component.type.rawValue

        guard registry.isRegistered(typeName) else {
            throw CustomComponentResolutionError.notRegistered(typeName)
        }

        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .customComponent(CustomComponentNodeData(typeName: typeName, style: style))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let customNode = CustomComponentRenderNode(
            typeName: typeName,
            component: component,
            style: style
        )

        let renderNode = RenderNode.custom(kind: .customComponent, node: customNode)

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}

// MARK: - Errors

/// Errors that can occur during custom component resolution
public enum CustomComponentResolutionError: Error, LocalizedError {
    case notRegistered(String)

    public var errorDescription: String? {
        switch self {
        case .notRegistered(let typeName):
            return "Custom component '\(typeName)' is not registered. Register it using CustomComponentRegistry."
        }
    }
}

