//
//  TextFieldNodeRenderer.swift
//  CladsModules
//
//  Renders TextFieldNode to UITextField.
//

import CLADS
import Combine
import UIKit

/// Renders text field nodes to BoundTextField
public struct TextFieldNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .textField

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .textField(let textFieldNode) = node else {
            return UIView()
        }

        let field = BoundTextField(
            bindingPath: textFieldNode.bindingPath,
            stateStore: context.stateStore
        )
        field.placeholder = textFieldNode.placeholder
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.applyStyle(textFieldNode.style)

        return field
    }
}

// MARK: - Bound TextField

/// UITextField that binds to a StateStore path
public final class BoundTextField: UITextField, UITextFieldDelegate {
    private let bindingPath: String?
    private let stateStore: StateStore
    private var cancellable: AnyCancellable?

    public init(bindingPath: String?, stateStore: StateStore) {
        self.bindingPath = bindingPath
        self.stateStore = stateStore
        super.init(frame: .zero)
        delegate = self
        setupBinding()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBinding() {
        guard let path = bindingPath else { return }

        // Initial value
        Task { @MainActor in
            if let value = stateStore.get(path) as? String {
                text = value
            }
        }

        // Observe changes
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc private func textChanged() {
        guard let path = bindingPath else { return }
        Task { @MainActor in
            stateStore.set(path, value: text ?? "")
        }
    }
}
