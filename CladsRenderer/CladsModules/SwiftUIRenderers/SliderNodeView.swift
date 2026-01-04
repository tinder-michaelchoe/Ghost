//
//  SliderNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for SliderNode.
//

import CLADS
import SwiftUI

// MARK: - Slider Node SwiftUI Renderer

public struct SliderNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.slider

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .slider(let sliderNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            SliderNodeView(node: sliderNode)
                .environmentObject(context.tree.stateStore)
        )
    }
}

// MARK: - Slider Node View

struct SliderNodeView: View {
    let node: SliderNode
    @EnvironmentObject var stateStore: StateStore
    @State private var value: Double = 0.0

    var body: some View {
        Slider(value: $value, in: node.minValue...node.maxValue)
            .tint(node.style.tintColor)
            .onAppear {
                if let path = node.bindingPath {
                    value = stateStore.get(path) as? Double ?? node.minValue
                }
            }
            .onChange(of: value) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}
