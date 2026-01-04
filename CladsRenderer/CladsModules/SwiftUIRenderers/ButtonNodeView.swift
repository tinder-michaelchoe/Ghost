//
//  ButtonNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for ButtonNode.
//

import CLADS
import SwiftUI

// MARK: - Button Node SwiftUI Renderer

public struct ButtonNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.button

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .button(let buttonNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ButtonNodeView(node: buttonNode, actionContext: context.actionContext)
                .environmentObject(context.tree.stateStore)
        )
    }
}

// MARK: - Button Node View

struct ButtonNodeView: View {
    let node: ButtonNode
    let actionContext: ActionContext
    @EnvironmentObject var stateStore: StateStore

    /// Check if button is selected based on state binding
    private var isSelected: Bool {
        guard let bindingPath = node.isSelectedBinding else { return false }
        return stateStore.get(bindingPath) as? Bool ?? false
    }

    /// Get the current style based on selection state
    private var currentStyle: IR.Style {
        node.styles.style(isSelected: isSelected)
    }

    var body: some View {
        Button(action: handleTap) {
            Text(node.label)
                .applyTextStyle(currentStyle)
                .padding(.top, currentStyle.paddingTop ?? 0)
                .padding(.bottom, currentStyle.paddingBottom ?? 0)
                .padding(.leading, currentStyle.paddingLeading ?? 0)
                .padding(.trailing, currentStyle.paddingTrailing ?? 0)
                .frame(maxWidth: node.fillWidth ? .infinity : nil)
                .frame(height: currentStyle.height)
                .background(currentStyle.backgroundColor ?? .clear)
                .cornerRadius(currentStyle.cornerRadius ?? 0)
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        guard let binding = node.onTap else { return }
        Task { @MainActor in
            switch binding {
            case .reference(let actionId):
                await actionContext.executeAction(id: actionId)
            case .inline(let action):
                await actionContext.executeAction(action)
            }
        }
    }
}
