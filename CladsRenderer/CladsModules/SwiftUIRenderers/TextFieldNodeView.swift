//
//  TextFieldNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for TextFieldNode.
//

import CLADS
import SwiftUI

// MARK: - TextField Node SwiftUI Renderer

public struct TextFieldNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.textField

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .textField(let textFieldNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            TextFieldNodeView(node: textFieldNode)
                .environmentObject(context.tree.stateStore)
        )
    }
}

// MARK: - TextField Node View

struct TextFieldNodeView: View {
    let node: TextFieldNode
    @EnvironmentObject var stateStore: StateStore
    @State private var text: String = ""

    var body: some View {
        TextField(node.placeholder, text: $text)
            .applyTextStyle(node.style)
            .onAppear {
                if let path = node.bindingPath {
                    text = stateStore.get(path) as? String ?? ""
                }
            }
            .onChange(of: text) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}
