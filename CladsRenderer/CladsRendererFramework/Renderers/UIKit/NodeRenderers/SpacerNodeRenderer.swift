//
//  SpacerNodeRenderer.swift
//  CladsRendererFramework
//
//  Renders spacer nodes to flexible UIView.
//

import UIKit

/// Renders spacer nodes to a flexible UIView
public struct SpacerNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNode.Kind = .spacer

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacer
    }
}
