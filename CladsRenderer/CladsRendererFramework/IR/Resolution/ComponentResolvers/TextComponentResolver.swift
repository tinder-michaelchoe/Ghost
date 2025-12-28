//
//  TextComponentResolver.swift
//  CladsRendererFramework
//
//  Resolves label/text components.
//

import Foundation
import SwiftUI

/// Resolves `label` components into TextNode
public struct TextComponentResolver: ComponentResolving {

    public static let componentKind: Document.Component.Kind = .label

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .text(TextNodeData(content: "", style: style))
            )
            viewNode?.parent = context.parentViewNode

            // Track dependencies during content resolution
            context.tracker?.beginTracking(for: viewNode!)
        } else {
            viewNode = nil
        }

        // Resolve content (may record dependencies)
        let content = ContentResolver.resolve(component, context: context, viewNode: viewNode)

        if context.isTracking {
            context.tracker?.endTracking()
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.text(TextNode(
            id: component.id,
            content: content,
            style: style
        ))

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
