//
//  ImageNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for ImageNode.
//

import CLADS
import SwiftUI

// MARK: - Image Node SwiftUI Renderer

public struct ImageNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.image

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .image(let imageNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(ImageNodeView(node: imageNode))
    }
}

// MARK: - Image Node View

struct ImageNodeView: View {
    let node: ImageNode

    var body: some View {
        Group {
            switch node.source {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .url(let url):
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
        }
        .frame(width: node.style.width, height: node.style.height)
        .frame(maxWidth: node.style.width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: node.style.cornerRadius ?? 0))
    }
}

// MARK: - Tint Modifier

/// Applies tint color to an image if specified
struct TintModifier: ViewModifier {
    let tintColor: Color?

    func body(content: Content) -> some View {
        if let tintColor {
            content.foregroundStyle(tintColor)
        } else {
            content
        }
    }
}
