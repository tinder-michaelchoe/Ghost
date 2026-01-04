//
//  SpacerNodeView.swift
//  CladsModules
//
//  SwiftUI renderer for Spacer.
//

import CLADS
import SwiftUI

// MARK: - Spacer Node SwiftUI Renderer

public struct SpacerNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.spacer

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .spacer = node else {
            return AnyView(EmptyView())
        }
        return AnyView(Spacer())
    }
}
