//
//  ButtonNodeRenderer.swift
//  CladsModules
//
//  Renders ButtonNode to UIButton.
//

import CLADS
import UIKit

/// Renders button nodes to ActionButton (UIButton subclass)
public struct ButtonNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .button

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .button(let buttonNode) = node else {
            return UIView()
        }

        let button = ActionButton(
            actionBinding: buttonNode.onTap,
            actionContext: context.actionContext
        )
        button.setTitle(buttonNode.label, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applyStyle(buttonNode.style)

        if buttonNode.fillWidth {
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        if let height = buttonNode.style.height {
            button.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return button
    }
}

// MARK: - Action Button

/// UIButton subclass that executes an action on tap
public final class ActionButton: UIButton {
    private let actionBinding: Document.Component.ActionBinding?
    private let actionContext: ActionContext

    public init(actionBinding: Document.Component.ActionBinding?, actionContext: ActionContext) {
        self.actionBinding = actionBinding
        self.actionContext = actionContext
        super.init(frame: .zero)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        guard let binding = actionBinding else { return }
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
