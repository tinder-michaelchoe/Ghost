//
//  CustomComponentRenderNode.swift
//  CLADS
//
//  Render node for custom components.
//

import Foundation
import SwiftUI

/// Render node for custom components.
///
/// This node holds the original component definition and resolved style,
/// deferring the actual rendering to the registered `CustomComponent` implementation.
public struct CustomComponentRenderNode: CustomRenderNode {
    public static let kind = RenderNodeKind(rawValue: "customComponent")

    /// The component type name (matches `CustomComponent.typeName`)
    public let typeName: String

    /// The original component from the document
    public let component: Document.Component

    /// Resolved style for this component
    public let style: IR.Style

    public init(
        typeName: String,
        component: Document.Component,
        style: IR.Style
    ) {
        self.typeName = typeName
        self.component = component
        self.style = style
    }
}

// MARK: - RenderNodeKind Extension

extension RenderNodeKind {
    /// Kind for custom components registered via `CustomComponent` protocol
    public static let customComponent = RenderNodeKind(rawValue: "customComponent")
}

