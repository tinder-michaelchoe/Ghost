//
//  TextComponentResolver.swift
//  CladsModules
//
//  Resolves label/text components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `label` components into TextNode
public struct TextComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .label

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
        let contentResult = ContentResolver.resolve(component, context: context, viewNode: viewNode)

        if context.isTracking {
            context.tracker?.endTracking()
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.text(TextNode(
            id: component.id,
            content: contentResult.content,
            style: style,
            padding: PaddingConverter.convert(component.padding),
            bindingPath: contentResult.bindingPath,
            bindingTemplate: contentResult.bindingTemplate
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
