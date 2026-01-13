//
//  UIKitNodeRendererRegistryTests.swift
//  CLADSTests
//
//  Unit tests for UIKitNodeRendererRegistry - registration and resolution of UIKit node renderers.
//

import Foundation
import Testing
import UIKit
@testable import CLADS

// MARK: - Test Mock Renderers

/// Mock renderer for testing text node rendering
struct MockTextNodeRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .text
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let label = UILabel()
        label.accessibilityIdentifier = "mock_text_renderer"
        return label
    }
}

/// Mock renderer for testing button node rendering
struct MockButtonNodeRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .button
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let button = UIButton()
        button.accessibilityIdentifier = "mock_button_renderer"
        return button
    }
}

/// Mock renderer for testing container node rendering
struct MockContainerNodeRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .container
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let stackView = UIStackView()
        stackView.accessibilityIdentifier = "mock_container_renderer"
        return stackView
    }
}

/// Mock renderer for testing custom node kind
extension RenderNodeKind {
    static let testCustom = RenderNodeKind(rawValue: "testCustom")
}

struct MockCustomNodeRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .testCustom
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        let view = UIView()
        view.accessibilityIdentifier = "mock_custom_renderer"
        return view
    }
}

// MARK: - Test Helpers

/// Creates a test UIKitRenderContext
@MainActor
func createTestContext(registry: UIKitNodeRendererRegistry) -> UIKitRenderContext {
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

// MARK: - Registration Tests

struct UIKitNodeRendererRegistryRegistrationTests {
    
    @Test func registersRenderer() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        
        #expect(registry.hasRenderer(for: .text))
    }
    
    @Test func registersMultipleRenderers() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        registry.register(MockButtonNodeRenderer())
        registry.register(MockContainerNodeRenderer())
        
        #expect(registry.hasRenderer(for: .text))
        #expect(registry.hasRenderer(for: .button))
        #expect(registry.hasRenderer(for: .container))
    }
    
    @Test func registersCustomNodeKindRenderer() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockCustomNodeRenderer())
        
        #expect(registry.hasRenderer(for: .testCustom))
    }
    
    @Test func replacesExistingRenderer() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        registry.register(MockTextNodeRenderer()) // Re-register
        
        // Should still have the renderer (replaced)
        #expect(registry.hasRenderer(for: .text))
    }
    
    @Test func unregistersRenderer() async throws {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        
        #expect(registry.hasRenderer(for: .text))
        
        registry.unregister(.text)
        
        // Need to wait for async barrier to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(!registry.hasRenderer(for: .text))
    }
}

// MARK: - Lookup Tests

struct UIKitNodeRendererRegistryLookupTests {
    
    @Test func hasRendererReturnsFalseForUnregistered() {
        let registry = UIKitNodeRendererRegistry()
        
        #expect(!registry.hasRenderer(for: .text))
        #expect(!registry.hasRenderer(for: .button))
        #expect(!registry.hasRenderer(for: .container))
    }
    
    @Test func hasRendererReturnsTrueForRegistered() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        
        #expect(registry.hasRenderer(for: .text))
        #expect(!registry.hasRenderer(for: .button))
    }
    
    @Test func hasRendererWorksWithCustomKinds() {
        let registry = UIKitNodeRendererRegistry()
        
        #expect(!registry.hasRenderer(for: .testCustom))
        
        registry.register(MockCustomNodeRenderer())
        
        #expect(registry.hasRenderer(for: .testCustom))
    }
}

// MARK: - Rendering Tests

struct UIKitNodeRendererRegistryRenderingTests {
    
    @Test @MainActor func rendersTextNode() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        
        let context = createTestContext(registry: registry)
        let textNode = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = registry.render(textNode, context: context)
        
        #expect(view.accessibilityIdentifier == "mock_text_renderer")
        #expect(view is UILabel)
    }
    
    @Test @MainActor func rendersButtonNode() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockButtonNodeRenderer())
        
        let context = createTestContext(registry: registry)
        let buttonNode = RenderNode.button(ButtonNode(
            label: "Tap Me",
            styles: ButtonStyles()
        ))
        
        let view = registry.render(buttonNode, context: context)
        
        #expect(view.accessibilityIdentifier == "mock_button_renderer")
        #expect(view is UIButton)
    }
    
    @Test @MainActor func rendersContainerNode() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockContainerNodeRenderer())
        
        let context = createTestContext(registry: registry)
        let containerNode = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            children: []
        ))
        
        let view = registry.render(containerNode, context: context)
        
        #expect(view.accessibilityIdentifier == "mock_container_renderer")
        #expect(view is UIStackView)
    }
    
    @Test @MainActor func dispatchesToCorrectRenderer() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(MockTextNodeRenderer())
        registry.register(MockButtonNodeRenderer())
        registry.register(MockContainerNodeRenderer())
        
        let context = createTestContext(registry: registry)
        
        // Test text node goes to text renderer
        let textNode = RenderNode.text(TextNode(content: "Test", style: IR.Style(), padding: .zero))
        let textView = registry.render(textNode, context: context)
        #expect(textView.accessibilityIdentifier == "mock_text_renderer")
        
        // Test button node goes to button renderer
        let buttonNode = RenderNode.button(ButtonNode(label: "Test", styles: ButtonStyles()))
        let buttonView = registry.render(buttonNode, context: context)
        #expect(buttonView.accessibilityIdentifier == "mock_button_renderer")
        
        // Test container node goes to container renderer
        let containerNode = RenderNode.container(ContainerNode(layoutType: .vstack, children: []))
        let containerView = registry.render(containerNode, context: context)
        #expect(containerView.accessibilityIdentifier == "mock_container_renderer")
    }
}

// MARK: - Mock Protocol Conformance Tests

struct MockUIKitNodeRenderingProtocolTests {
    
    @Test func mockRendererProvidesNodeKind() {
        #expect(MockTextNodeRenderer.nodeKind == .text)
        #expect(MockButtonNodeRenderer.nodeKind == .button)
        #expect(MockContainerNodeRenderer.nodeKind == .container)
    }
    
    @Test func mockRendererCanBeInitialized() {
        let textRenderer = MockTextNodeRenderer()
        let buttonRenderer = MockButtonNodeRenderer()
        let containerRenderer = MockContainerNodeRenderer()
        
        // Verify they conform to protocol (no crash = success)
        #expect(type(of: textRenderer).nodeKind == .text)
        #expect(type(of: buttonRenderer).nodeKind == .button)
        #expect(type(of: containerRenderer).nodeKind == .container)
    }
}

// MARK: - Edge Case Tests

struct UIKitNodeRendererRegistryEdgeCaseTests {
    
    @Test func emptyRegistryHasNoRenderers() {
        let registry = UIKitNodeRendererRegistry()
        
        #expect(!registry.hasRenderer(for: .text))
        #expect(!registry.hasRenderer(for: .button))
        #expect(!registry.hasRenderer(for: .container))
        #expect(!registry.hasRenderer(for: .sectionLayout))
        #expect(!registry.hasRenderer(for: .textField))
        #expect(!registry.hasRenderer(for: .toggle))
        #expect(!registry.hasRenderer(for: .slider))
        #expect(!registry.hasRenderer(for: .image))
        #expect(!registry.hasRenderer(for: .gradient))
        #expect(!registry.hasRenderer(for: .spacer))
        #expect(!registry.hasRenderer(for: .divider))
    }
    
    @Test func registerSameKindMultipleTimes() {
        let registry = UIKitNodeRendererRegistry()
        
        // Register multiple times
        registry.register(MockTextNodeRenderer())
        registry.register(MockTextNodeRenderer())
        registry.register(MockTextNodeRenderer())
        
        // Should still work
        #expect(registry.hasRenderer(for: .text))
    }
    
    @Test func unregisterNonExistentKind() {
        let registry = UIKitNodeRendererRegistry()
        
        // Should not crash
        registry.unregister(.text)
        registry.unregister(.button)
        
        #expect(!registry.hasRenderer(for: .text))
    }
}
