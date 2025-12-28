//
//  TextNodeRenderer.swift
//  CladsRendererFramework
//
//  Renders TextNode to UILabel.
//

import UIKit

/// Renders text nodes to UILabel
public struct TextNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNode.Kind = .text

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .text(let textNode) = node else {
            return UIView()
        }

        let label = UILabel()
        label.text = textNode.content
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.applyStyle(textNode.style)

        return label
    }
}
