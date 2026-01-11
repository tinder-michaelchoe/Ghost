//
//  DividerNodeRenderer.swift
//  CladsModules
//
//  Renders divider nodes to UIView.
//

import CLADS
import SwiftUI
import UIKit

/// Renders divider nodes to a UIView
public struct DividerNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .divider

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .divider(let dividerNode) = node else {
            return UIView()
        }

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Set background color
        if let color = dividerNode.style.backgroundColor {
            divider.backgroundColor = UIColor(color)
        } else {
            divider.backgroundColor = .separator
        }

        // Set height constraint
        let height = dividerNode.style.height ?? 1
        divider.heightAnchor.constraint(equalToConstant: height).isActive = true

        return divider
    }
}
