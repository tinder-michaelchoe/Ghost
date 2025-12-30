//
//  GradientComponentResolver.swift
//  CladsRendererFramework
//
//  Resolves gradient components.
//

import Foundation
import SwiftUI

/// Resolves `gradient` components into GradientNode
public struct GradientComponentResolver: ComponentResolving {

    public static let componentKind: Document.Component.Kind = .gradient

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString
        let gradientNode = buildGradientNode(from: component, style: style)

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .gradient(GradientNodeData(
                    gradientType: gradientNode.gradientType,
                    colors: gradientNode.colors,
                    startPoint: gradientNode.startPoint,
                    endPoint: gradientNode.endPoint,
                    style: style
                ))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        return ComponentResolutionResult(
            renderNode: .gradient(gradientNode),
            viewNode: viewNode
        )
    }

    // MARK: - Private Helpers

    private func buildGradientNode(from component: Document.Component, style: IR.Style) -> GradientNode {
        let colors = (component.gradientColors ?? []).map { config -> GradientNode.ColorStop in
            let color: GradientColor
            if let lightHex = config.lightColor, let darkHex = config.darkColor {
                color = .adaptive(light: Color(hex: lightHex), dark: Color(hex: darkHex))
            } else if let hex = config.color {
                color = .fixed(Color(hex: hex))
            } else {
                color = .fixed(.clear)
            }
            return GradientNode.ColorStop(color: color, location: config.location)
        }

        let startPoint = GradientPointConverter.convert(component.gradientStart)
        let endPoint = GradientPointConverter.convert(component.gradientEnd)

        return GradientNode(
            id: component.id,
            gradientType: .linear,
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint,
            style: style
        )
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
