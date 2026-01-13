//
//  UIKitNodeRendererTests.swift
//  CLADSTests
//
//  Unit tests for UIKit node renderer protocol and registry behavior using mock implementations.
//  Concrete renderer tests should be in CladsRendererFrameworkTests.
//

import Foundation
import Testing
import UIKit
import SwiftUI
@testable import CLADS

// MARK: - Mock Renderers for Testing

/// Mock text node renderer for testing
struct MockTextRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .text
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .text(let textNode) = node else {
            return UIView()
        }
        let label = UILabel()
        label.text = textNode.content
        label.accessibilityIdentifier = "mock_text"
        return label
    }
}

/// Mock button node renderer for testing
struct MockButtonRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .button
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .button(let buttonNode) = node else {
            return UIView()
        }
        let button = UIButton()
        button.setTitle(buttonNode.label, for: .normal)
        button.accessibilityIdentifier = "mock_button"
        return button
    }
}

/// Mock container node renderer for testing
struct MockContainerRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .container
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .container(let containerNode) = node else {
            return UIView()
        }
        let stackView = UIStackView()
        stackView.axis = containerNode.layoutType == .vstack ? .vertical : .horizontal
        stackView.spacing = containerNode.spacing
        stackView.accessibilityIdentifier = "mock_container"
        
        for child in containerNode.children {
            let childView = context.render(child)
            stackView.addArrangedSubview(childView)
        }
        
        return stackView
    }
}

/// Mock text field node renderer for testing
struct MockTextFieldRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .textField
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .textField(let textFieldNode) = node else {
            return UIView()
        }
        let textField = UITextField()
        textField.placeholder = textFieldNode.placeholder
        textField.accessibilityIdentifier = "mock_textfield"
        return textField
    }
}

/// Mock image node renderer for testing
struct MockImageRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .image
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "mock_image"
        return imageView
    }
}

/// Mock spacer node renderer for testing
struct MockSpacerRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .spacer
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.accessibilityIdentifier = "mock_spacer"
        return view
    }
}

/// Mock gradient node renderer for testing
struct MockGradientRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .gradient
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let view = UIView()
        view.accessibilityIdentifier = "mock_gradient"
        return view
    }
}

/// Mock section layout node renderer for testing
struct MockSectionLayoutRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .sectionLayout
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let scrollView = UIScrollView()
        scrollView.accessibilityIdentifier = "mock_section_layout"
        return scrollView
    }
}

// MARK: - Test Helpers

/// Creates a test UIKitRenderContext with mock renderers
@MainActor
func createMockUIKitContext() -> UIKitRenderContext {
    let registry = UIKitNodeRendererRegistry()
    registry.register(MockTextRenderer())
    registry.register(MockButtonRenderer())
    registry.register(MockContainerRenderer())
    registry.register(MockTextFieldRenderer())
    registry.register(MockImageRenderer())
    registry.register(MockSpacerRenderer())
    registry.register(MockGradientRenderer())
    registry.register(MockSectionLayoutRenderer())
    
    let stateStore = StateStore()
    let actionContext = ActionContext(
        stateStore: stateStore,
        actionDefinitions: [:],
        registry: ActionRegistry()
    )
    return UIKitRenderContext(
        actionContext: actionContext,
        stateStore: stateStore,
        colorScheme: .light,
        registry: registry
    )
}

// MARK: - Text Node Rendering Tests

struct TextNodeRenderingTests {
    
    @Test @MainActor func rendersTextNodeToUILabel() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.text(TextNode(
            content: "Hello World",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = context.render(node)
        
        #expect(view is UILabel)
        #expect((view as? UILabel)?.text == "Hello World")
    }
    
    @Test @MainActor func textNodeHasCorrectAccessibilityId() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = context.render(node)
        
        #expect(view.accessibilityIdentifier == "mock_text")
    }
}

// MARK: - Button Node Rendering Tests

struct ButtonNodeRenderingTests {
    
    @Test @MainActor func rendersButtonNodeToUIButton() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.button(ButtonNode(
            label: "Tap Me",
            styles: ButtonStyles()
        ))
        
        let view = context.render(node)
        
        #expect(view is UIButton)
    }
    
    @Test @MainActor func buttonNodeSetsTitle() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.button(ButtonNode(
            label: "Click Here",
            styles: ButtonStyles()
        ))
        
        let view = context.render(node)
        let button = view as? UIButton
        
        #expect(button?.title(for: .normal) == "Click Here")
    }
}

// MARK: - Container Node Rendering Tests

@Suite(.disabled("Investigating test hang"))
struct ContainerNodeRenderingTests {
    
    @Test @MainActor func rendersVStackToVerticalStackView() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            alignment: .center,
            spacing: 8,
            children: []
        ))
        
        let view = context.render(node)
        let stackView = view as? UIStackView
        
        #expect(stackView?.axis == .vertical)
    }
    
    @Test @MainActor func rendersHStackToHorizontalStackView() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .hstack,
            alignment: .center,
            spacing: 8,
            children: []
        ))
        
        let view = context.render(node)
        let stackView = view as? UIStackView
        
        #expect(stackView?.axis == .horizontal)
    }
    
    @Test @MainActor func containerSetsSpacing() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            alignment: .center,
            spacing: 16,
            children: []
        ))
        
        let view = context.render(node)
        let stackView = view as? UIStackView
        
        #expect(stackView?.spacing == 16)
    }
    
    @Test @MainActor func containerRendersChildren() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            alignment: .center,
            spacing: 8,
            children: [
                .text(TextNode(content: "Child 1", style: IR.Style(), padding: .zero)),
                .text(TextNode(content: "Child 2", style: IR.Style(), padding: .zero))
            ]
        ))
        
        let view = context.render(node)
        let stackView = view as? UIStackView
        
        #expect(stackView?.arrangedSubviews.count == 2)
    }
}

// MARK: - TextField Node Rendering Tests

struct TextFieldNodeRenderingTests {
    
    @Test @MainActor func rendersTextFieldNodeToUITextField() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.textField(TextFieldNode(
            placeholder: "Enter text",
            style: IR.Style(),
            bindingPath: nil
        ))
        
        let view = context.render(node)
        
        #expect(view is UITextField)
    }
    
    @Test @MainActor func textFieldSetsPlaceholder() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.textField(TextFieldNode(
            placeholder: "Type here...",
            style: IR.Style(),
            bindingPath: nil
        ))
        
        let view = context.render(node)
        let textField = view as? UITextField
        
        #expect(textField?.placeholder == "Type here...")
    }
}

// MARK: - Image Node Rendering Tests

@Suite(.disabled("Investigating test hang"))
struct ImageNodeRenderingTests {
    
    @Test @MainActor func rendersImageNodeToUIImageView() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.image(ImageNode(
            source: .system(name: "star"),
            style: IR.Style()
        ))
        
        let view = context.render(node)
        
        #expect(view is UIImageView)
    }
}

// MARK: - Spacer Node Rendering Tests

@Suite(.disabled("Investigating test hang"))
struct SpacerNodeRenderingTests {
    
    @Test @MainActor func rendersSpacerToUIView() {
        let context = createMockUIKitContext()
        
        let view = context.render(RenderNode.spacer)
        
        // Spacer renders to a basic UIView (not a subclass)
        #expect(view.accessibilityIdentifier == "mock_spacer")
    }
    
    @Test @MainActor func spacerHasLowContentHuggingPriority() {
        let context = createMockUIKitContext()
        
        let view = context.render(RenderNode.spacer)
        
        #expect(view.contentHuggingPriority(for: .vertical) == .defaultLow)
        #expect(view.contentHuggingPriority(for: .horizontal) == .defaultLow)
    }
}

// MARK: - Gradient Node Rendering Tests

@Suite(.disabled("Investigating test hang"))
struct GradientNodeRenderingTests {
    
    @Test @MainActor func rendersGradientNodeToUIView() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.gradient(GradientNode(
            colors: [
                GradientNode.ColorStop(color: .fixed(Color.red), location: 0),
                GradientNode.ColorStop(color: .fixed(Color.blue), location: 1)
            ],
            startPoint: UnitPoint.top,
            endPoint: UnitPoint.bottom,
            style: IR.Style()
        ))
        
        let view = context.render(node)
        
        #expect(view.accessibilityIdentifier == "mock_gradient")
    }
}

// MARK: - Section Layout Node Rendering Tests

struct SectionLayoutNodeRenderingTests {
    
    @Test @MainActor func rendersSectionLayoutToScrollView() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.sectionLayout(SectionLayoutNode(
            sectionSpacing: 16,
            sections: []
        ))
        
        let view = context.render(node)
        
        #expect(view is UIScrollView)
    }
}

// MARK: - Protocol Conformance Tests

struct UIKitMockRenderersProtocolTests {
    
    @Test func allMockRenderersProvideCorrectNodeKind() {
        #expect(MockTextRenderer.nodeKind == .text)
        #expect(MockButtonRenderer.nodeKind == .button)
        #expect(MockContainerRenderer.nodeKind == .container)
        #expect(MockTextFieldRenderer.nodeKind == .textField)
        #expect(MockImageRenderer.nodeKind == .image)
        #expect(MockSpacerRenderer.nodeKind == .spacer)
        #expect(MockGradientRenderer.nodeKind == .gradient)
        #expect(MockSectionLayoutRenderer.nodeKind == .sectionLayout)
    }
    
    @Test @MainActor func registryDispatchesToCorrectRenderer() {
        let context = createMockUIKitContext()
        
        // Each node type should dispatch to its corresponding mock renderer
        let textView = context.render(RenderNode.text(TextNode(content: "Test", style: IR.Style(), padding: .zero)))
        #expect(textView.accessibilityIdentifier == "mock_text")
        
        let buttonView = context.render(RenderNode.button(ButtonNode(label: "Test", styles: ButtonStyles())))
        #expect(buttonView.accessibilityIdentifier == "mock_button")
        
        let containerView = context.render(RenderNode.container(ContainerNode(layoutType: .vstack, children: [])))
        #expect(containerView.accessibilityIdentifier == "mock_container")
        
        let textFieldView = context.render(RenderNode.textField(TextFieldNode(placeholder: "Test", style: IR.Style(), bindingPath: nil)))
        #expect(textFieldView.accessibilityIdentifier == "mock_textfield")
        
        let imageView = context.render(RenderNode.image(ImageNode(source: .system(name: "star"), style: IR.Style())))
        #expect(imageView.accessibilityIdentifier == "mock_image")
        
        let spacerView = context.render(RenderNode.spacer)
        #expect(spacerView.accessibilityIdentifier == "mock_spacer")
    }
}

// MARK: - Nested Structure Tests

@Suite(.disabled("Investigating test hang"))
struct NestedRenderingTests {
    
    @Test @MainActor func rendersNestedContainers() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            children: [
                .container(ContainerNode(
                    layoutType: .hstack,
                    children: [
                        .text(TextNode(content: "Nested", style: IR.Style(), padding: .zero))
                    ]
                ))
            ]
        ))
        
        let view = context.render(node)
        let outerStack = view as? UIStackView
        
        #expect(outerStack?.axis == .vertical)
        #expect(outerStack?.arrangedSubviews.count == 1)
        
        let innerStack = outerStack?.arrangedSubviews.first as? UIStackView
        #expect(innerStack?.axis == .horizontal)
        #expect(innerStack?.arrangedSubviews.count == 1)
        #expect(innerStack?.arrangedSubviews.first is UILabel)
    }
    
    @Test @MainActor func rendersMixedChildTypes() {
        let context = createMockUIKitContext()
        
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            children: [
                .text(TextNode(content: "Text", style: IR.Style(), padding: .zero)),
                .button(ButtonNode(label: "Button", styles: ButtonStyles())),
                .spacer
            ]
        ))
        
        let view = context.render(node)
        let stackView = view as? UIStackView
        
        #expect(stackView?.arrangedSubviews.count == 3)
        #expect(stackView?.arrangedSubviews[0] is UILabel)
        #expect(stackView?.arrangedSubviews[1] is UIButton)
    }
}
