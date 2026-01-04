//
//  ImageComponentResolver.swift
//  CladsModules
//
//  Resolves image components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `image` components into ImageNode
public struct ImageComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .image

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString
        let source = resolveImageSource(component)

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .image(ImageNodeData(source: source, style: style))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.image(ImageNode(
            id: component.id,
            source: source,
            style: style
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    // MARK: - Private Helpers

    private func resolveImageSource(_ component: Document.Component) -> ImageNode.Source {
        // Check for image property (preferred)
        if let image = component.image {
            if let systemName = image.system {
                return .system(name: systemName)
            }
            if let urlString = image.url, let url = URL(string: urlString) {
                return .url(url)
            }
        }

        // Fallback: Check the data property for image source (legacy support)
        if let data = component.data {
            switch data.type {
            case .static:
                if let value = data.value {
                    // Check for system: prefix for SF Symbols
                    if value.hasPrefix("system:") {
                        return .system(name: String(value.dropFirst(7)))
                    }
                    // Check for url: prefix
                    if value.hasPrefix("url:"), let url = URL(string: String(value.dropFirst(4))) {
                        return .url(url)
                    }
                    // Default to asset
                    return .asset(name: value)
                }
            case .binding:
                break  // Dynamic images not supported yet
            case .localBinding:
                break  // Local binding images not supported yet
            }
        }
        return .system(name: "questionmark")
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
