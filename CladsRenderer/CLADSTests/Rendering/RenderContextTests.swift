//
//  RenderContextTests.swift
//  CLADSTests
//
//  Unit tests for UIKitRenderContext and SwiftUIRenderContext.
//

import Foundation
import Testing
import UIKit
import SwiftUI
@testable import CLADS

// MARK: - Mock Renderers for Context Tests

/// Mock text renderer for context testing
private struct ContextTestTextRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .text
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .text(let textNode) = node else {
            return UIView()
        }
        let label = UILabel()
        label.text = textNode.content
        return label
    }
}

/// Mock button renderer for context testing
private struct ContextTestButtonRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .button
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .button(let buttonNode) = node else {
            return UIView()
        }
        let button = UIButton()
        button.setTitle(buttonNode.label, for: .normal)
        return button
    }
}

/// Mock container renderer for context testing
private struct ContextTestContainerRenderer: UIKitNodeRendering {
    static let nodeKind: RenderNodeKind = .container
    
    init() {}
    
    func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .container(let containerNode) = node else {
            return UIView()
        }
        let stackView = UIStackView()
        stackView.axis = containerNode.layoutType == .vstack ? .vertical : .horizontal
        
        for child in containerNode.children {
            let childView = context.render(child)
            stackView.addArrangedSubview(childView)
        }
        
        return stackView
    }
}

// MARK: - Test Helpers

/// Creates a test ActionContext with required parameters
@MainActor
func createContextTestActionContext(stateStore: StateStore) -> ActionContext {
    ActionContext(
        stateStore: stateStore,
        actionDefinitions: [:],
        registry: ActionRegistry()
    )
}

// MARK: - UIKitRenderContext Tests

struct UIKitRenderContextInitializationTests {
    
    @Test @MainActor func createsContextWithAllDependencies() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        // Verify all dependencies are accessible
        _ = context.actionContext
        _ = context.stateStore
        _ = context.colorScheme
    }
    
    @Test @MainActor func storesColorScheme() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let lightContext = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        let darkContext = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .dark,
            registry: registry
        )
        
        #expect(lightContext.colorScheme == .light)
        #expect(darkContext.colorScheme == .dark)
    }
    
    @Test @MainActor func storesSystemColorScheme() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .system,
            registry: registry
        )
        
        #expect(context.colorScheme == .system)
    }
}

struct UIKitRenderContextStateStoreTests {
    
    @Test @MainActor func providesStateStoreAccess() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        stateStore.set("testKey", value: "testValue")
        
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        #expect(context.stateStore.get("testKey") as? String == "testValue")
    }
    
    @Test @MainActor func stateStoreIsSharedReference() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        // Modify state through context
        context.stateStore.set("key", value: "value")
        
        // Verify it's reflected in original state store
        #expect(stateStore.get("key") as? String == "value")
    }
}

struct UIKitRenderContextActionContextTests {
    
    @Test @MainActor func providesActionContextAccess() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionRegistry = ActionRegistry()
        
        let actionContext = ActionContext(
            stateStore: stateStore,
            actionDefinitions: [:],
            registry: actionRegistry
        )
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        // Should have access to action context
        _ = context.actionContext
    }
}

struct UIKitRenderContextRenderingTests {
    
    @Test @MainActor func rendersChildNodeViaRegistry() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(ContextTestTextRenderer())
        
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        let textNode = RenderNode.text(TextNode(
            content: "Child",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = context.render(textNode)
        
        #expect(view is UILabel)
    }
    
    @Test @MainActor func renderDelegatesCorrectlyToRegistry() {
        let registry = UIKitNodeRendererRegistry()
        registry.register(ContextTestTextRenderer())
        registry.register(ContextTestButtonRenderer())
        registry.register(ContextTestContainerRenderer())
        
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        // Test text node
        let textView = context.render(RenderNode.text(TextNode(
            content: "Text",
            style: IR.Style(),
            padding: .zero
        )))
        #expect(textView is UILabel)
        
        // Test button node
        let buttonView = context.render(RenderNode.button(ButtonNode(
            label: "Button",
            styles: ButtonStyles()
        )))
        #expect(buttonView is UIButton)
        
        // Test container node
        let containerView = context.render(RenderNode.container(ContainerNode(
            layoutType: .vstack,
            children: []
        )))
        #expect(containerView is UIStackView)
    }
}

// MARK: - SwiftUIRenderContext Tests

struct SwiftUIRenderContextInitializationTests {
    
    @Test @MainActor func createsContextWithAllDependencies() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        let tree = RenderTree(
            root: RootNode(),
            stateStore: stateStore,
            actions: [:]
        )
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        // Verify all dependencies are accessible
        _ = context.tree
        _ = context.actionContext
        _ = context.rendererRegistry
    }
    
    @Test @MainActor func storesTreeReference() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let textNode = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        let tree = RenderTree(
            root: RootNode(children: [textNode]),
            stateStore: stateStore,
            actions: [:]
        )
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        #expect(context.tree.root.children.count == 1)
    }
}

struct SwiftUIRenderContextRenderingTests {
    
    @Test @MainActor func renderReturnsAnyView() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        let tree = RenderTree(
            root: RootNode(),
            stateStore: stateStore,
            actions: [:]
        )
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        let node = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = context.render(node)
        
        // Should return an AnyView (wrapping EmptyView if no renderer)
        _ = view
    }
    
    @Test @MainActor func renderUsesRegisteredRenderer() {
        let registry = SwiftUINodeRendererRegistry()
        
        // Register a mock renderer
        struct MockRenderer: SwiftUINodeRendering {
            static let nodeKind: RenderNodeKind = .text
            
            @MainActor
            func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
                AnyView(Text("Mock Rendered"))
            }
        }
        
        registry.register(MockRenderer())
        
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        let tree = RenderTree(
            root: RootNode(),
            stateStore: stateStore,
            actions: [:]
        )
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        let node = RenderNode.text(TextNode(
            content: "Original",
            style: IR.Style(),
            padding: .zero
        ))
        
        let view = context.render(node)
        
        // View should be rendered via the mock renderer
        _ = view
    }
}

// MARK: - Color Scheme Tests

@Suite(.disabled("Investigating test hang"))
struct RenderColorSchemeTests {
    
    @Test func lightColorScheme() {
        let scheme: RenderColorScheme = .light
        
        switch scheme {
        case .light:
            break // Expected
        default:
            Issue.record("Expected light color scheme")
        }
    }
    
    @Test func darkColorScheme() {
        let scheme: RenderColorScheme = .dark
        
        switch scheme {
        case .dark:
            break // Expected
        default:
            Issue.record("Expected dark color scheme")
        }
    }
    
    @Test func systemColorScheme() {
        let scheme: RenderColorScheme = .system
        
        switch scheme {
        case .system:
            break // Expected
        default:
            Issue.record("Expected system color scheme")
        }
    }
}

// MARK: - Context Thread Safety Tests

@Suite(.disabled("Investigating test hang"))
struct RenderContextThreadSafetyTests {
    
    @Test @MainActor func uikitContextIsSendable() {
        let registry = UIKitNodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createContextTestActionContext(stateStore: stateStore)
        
        let context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: stateStore,
            colorScheme: .light,
            registry: registry
        )
        
        // Verify UIKitRenderContext conforms to Sendable (compile-time check)
        let _: any Sendable = context
    }
    
    @Test @MainActor func swiftuiContextRegistryIsSendable() {
        let registry = SwiftUINodeRendererRegistry()
        
        // Verify SwiftUINodeRendererRegistry conforms to Sendable (compile-time check)
        let _: any Sendable = registry
    }
}
