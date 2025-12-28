//
//  ButtonComponentResolver.swift
//  CladsRendererFramework
//
//  Resolves button components.
//

import Foundation
import SwiftUI

/// Resolves `button` components into ButtonNode
public struct ButtonComponentResolver: ComponentResolving {

    public static let componentKind: Document.Component.Kind = .button

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
                nodeType: .button(ButtonNodeData(
                    label: component.label ?? "",
                    style: style,
                    fillWidth: component.fillWidth ?? false,
                    onTapAction: component.actions?.onTap
                ))
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

        let renderNode = RenderNode.button(ButtonNode(
            id: component.id,
            label: component.label ?? content,
            style: style,
            fillWidth: component.fillWidth ?? false,
            onTap: component.actions?.onTap
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
