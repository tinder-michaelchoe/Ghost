//
//  ButtonComponentResolver.swift
//  CladsModules
//
//  Resolves button components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `button` components into ButtonNode
public struct ButtonComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .button

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        // Resolve button styles
        let buttonStyles = resolveButtonStyles(component, context: context)
        let nodeId = component.id ?? UUID().uuidString

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .button(ButtonNodeData(
                    label: component.text ?? "",
                    style: buttonStyles.normal,
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
        let contentResult = ContentResolver.resolve(component, context: context, viewNode: viewNode)

        if context.isTracking {
            context.tracker?.endTracking()
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.button(ButtonNode(
            id: component.id,
            label: component.text ?? contentResult.content,
            styles: buttonStyles,
            isSelectedBinding: component.isSelectedBinding,
            fillWidth: component.fillWidth ?? false,
            onTap: component.actions?.onTap
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    private func resolveButtonStyles(_ component: Document.Component, context: ResolutionContext) -> ButtonStyles {
        // If component has styles dictionary, resolve each state
        if let componentStyles = component.styles {
            let normalStyle = context.styleResolver.resolve(componentStyles.normal ?? component.styleId)
            let selectedStyle = componentStyles.selected.map { context.styleResolver.resolve($0) }
            let disabledStyle = componentStyles.disabled.map { context.styleResolver.resolve($0) }

            return ButtonStyles(
                normal: normalStyle,
                selected: selectedStyle,
                disabled: disabledStyle
            )
        }

        // Fall back to single styleId
        let style = context.styleResolver.resolve(component.styleId)
        return ButtonStyles(normal: style)
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
