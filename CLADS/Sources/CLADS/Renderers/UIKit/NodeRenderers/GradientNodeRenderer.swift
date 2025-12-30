//
//  GradientNodeRenderer.swift
//  CladsRendererFramework
//
//  Renders GradientNode to GradientView.
//

import UIKit
import SwiftUI

/// Renders gradient nodes to GradientView
public struct GradientNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNode.Kind = .gradient

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .gradient(let gradientNode) = node else {
            return UIView()
        }

        let gradientView = GradientView(
            node: gradientNode,
            colorScheme: context.colorScheme
        )
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        if let width = gradientNode.style.width {
            gradientView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = gradientNode.style.height {
            gradientView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return gradientView
    }
}

// MARK: - Gradient View

/// UIView that renders a gradient using CAGradientLayer
public final class GradientView: UIView {
    private let node: GradientNode
    private let colorScheme: RenderColorScheme

    override public class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    public init(node: GradientNode, colorScheme: RenderColorScheme) {
        self.node = node
        self.colorScheme = colorScheme
        super.init(frame: .zero)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateColors()
        }
    }

    private func setupGradient() {
        updateColors()
        gradientLayer.startPoint = node.startPoint.cgPoint
        gradientLayer.endPoint = node.endPoint.cgPoint
        gradientLayer.locations = node.colors.map { NSNumber(value: Double($0.location)) }
    }

    private func updateColors() {
        let isDark = effectiveIsDarkMode
        gradientLayer.colors = node.colors.map { stop -> CGColor in
            switch stop.color {
            case .fixed(let color):
                return UIColor(color).cgColor
            case .adaptive(let light, let dark):
                return UIColor(isDark ? dark : light).cgColor
            }
        }
    }

    private var effectiveIsDarkMode: Bool {
        switch colorScheme {
        case .light: return false
        case .dark: return true
        case .system: return traitCollection.userInterfaceStyle == .dark
        }
    }
}

// MARK: - UnitPoint Extension

extension UnitPoint {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
