//
//  SwiftUINodeRendererTests.swift
//  CLADSTests
//
//  Unit tests for SwiftUI node renderers.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Test Helpers

/// Creates a test ActionContext
@MainActor
func createSwiftUITestActionContext(stateStore: StateStore) -> ActionContext {
    ActionContext(
        stateStore: stateStore,
        actionDefinitions: [:],
        registry: ActionRegistry()
    )
}

/// Creates a test SwiftUIRenderContext with all built-in renderers
@MainActor
func createFullSwiftUITestContext() -> SwiftUIRenderContext {
    let registry = SwiftUINodeRendererRegistry()
    
    let stateStore = StateStore()
    let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
    let renderTree = RenderTree(
        root: RootNode(children: []),
        stateStore: stateStore,
        actions: [:]
    )
    return SwiftUIRenderContext(
        tree: renderTree,
        actionContext: actionContext,
        rendererRegistry: registry
    )
}

/// Creates a RenderTree for testing
@MainActor
func createTestRenderTree(children: [RenderNode] = []) -> RenderTree {
    let stateStore = StateStore()
    return RenderTree(
        root: RootNode(children: children),
        stateStore: stateStore,
        actions: [:]
    )
}

// MARK: - SwiftUI Renderer Tests

struct SwiftUIRendererTests {
    
    @Test @MainActor func createsRendererWithDependencies() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        
        let renderer = SwiftUIRenderer(
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        // Verify renderer was created (no crash = success)
        _ = renderer
    }
    
    @Test @MainActor func rendersEmptyTree() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        
        let renderer = SwiftUIRenderer(
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        let tree = createTestRenderTree()
        let view = renderer.render(tree)
        
        // Verify view was created (no crash = success)
        _ = view
    }
    
    @Test @MainActor func rendersTreeWithChildren() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        
        let renderer = SwiftUIRenderer(
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        let tree = createTestRenderTree(children: [
            .text(TextNode(content: "Test", style: IR.Style(), padding: .zero))
        ])
        let view = renderer.render(tree)
        
        _ = view
    }
}

// MARK: - SwiftUI Render Context Tests

struct SwiftUIRenderContextTests {
    
    @Test @MainActor func contextProvidesTree() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        let tree = createTestRenderTree()
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        #expect(context.tree.root.children.isEmpty)
    }
    
    @Test @MainActor func contextProvidesActionContext() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        let tree = createTestRenderTree()
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        // Should have access to action context
        _ = context.actionContext
    }
    
    @Test @MainActor func contextProvidesRendererRegistry() {
        let registry = SwiftUINodeRendererRegistry()
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        let tree = createTestRenderTree()
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        // Should have access to renderer registry
        _ = context.rendererRegistry
    }
    
    @Test @MainActor func contextRenderReturnsEmptyViewForUnregisteredKind() {
        let registry = SwiftUINodeRendererRegistry()
        // Don't register any renderers
        
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        let tree = createTestRenderTree()
        
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
        
        // Should return AnyView wrapping EmptyView
        let view = context.render(node)
        _ = view
    }
}

// MARK: - RootNode Tests

struct RootNodeTests {
    
    @Test func createsWithDefaults() {
        let root = RootNode()
        
        #expect(root.backgroundColor == nil)
        #expect(root.edgeInsets == nil)
        #expect(root.colorScheme == .system)
        #expect(root.children.isEmpty)
    }
    
    @Test func createsWithChildren() {
        let textNode = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        
        let root = RootNode(children: [textNode])
        
        #expect(root.children.count == 1)
    }
    
    @Test func createsWithBackgroundColor() {
        let root = RootNode(backgroundColor: Color.blue)
        
        #expect(root.backgroundColor == Color.blue)
    }
    
    @Test func createsWithColorScheme() {
        let lightRoot = RootNode(colorScheme: .light)
        let darkRoot = RootNode(colorScheme: .dark)
        
        #expect(lightRoot.colorScheme == .light)
        #expect(darkRoot.colorScheme == .dark)
    }
}

// MARK: - RenderTree Tests

@Suite(.disabled("Investigating test hang"))
struct RenderTreeTests {
    
    @Test @MainActor func createsWithComponents() {
        let stateStore = StateStore()
        let root = RootNode(children: [])
        
        let tree = RenderTree(
            root: root,
            stateStore: stateStore,
            actions: [:]
        )
        
        #expect(tree.root.children.isEmpty)
        #expect(tree.actions.isEmpty)
    }
    
    @Test @MainActor func createsWithActions() {
        let stateStore = StateStore()
        let root = RootNode()
        let dismissAction = ActionDefinition.dismiss
        
        let tree = RenderTree(
            root: root,
            stateStore: stateStore,
            actions: ["close": dismissAction]
        )
        
        #expect(tree.actions.count == 1)
        #expect(tree.actions["close"] != nil)
    }
    
    @Test @MainActor func storesStateStoreReference() {
        let stateStore = StateStore()
        stateStore.set("testKey", value: "testValue")
        
        let tree = RenderTree(
            root: RootNode(),
            stateStore: stateStore,
            actions: [:]
        )
        
        // State store should be accessible
        #expect(tree.stateStore.get("testKey") as? String == "testValue")
    }
}

// MARK: - Custom SwiftUI Renderer Tests

@Suite(.disabled("Investigating test hang"))
struct CustomSwiftUIRendererTests {
    
    /// A test custom node for custom rendering
    struct TestChartNode: CustomRenderNode {
        static let kind = RenderNodeKind(rawValue: "testChart")
        let dataPoints: [Double]
    }
    
    /// A test renderer for the custom chart node
    struct TestChartRenderer: SwiftUINodeRendering {
        static let nodeKind = RenderNodeKind(rawValue: "testChart")
        
        @MainActor
        func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
            AnyView(Text("Chart"))
        }
    }
    
    @Test @MainActor func registersCustomRenderer() {
        let registry = SwiftUINodeRendererRegistry()
        registry.register(TestChartRenderer())
        
        #expect(registry.hasRenderer(for: RenderNodeKind(rawValue: "testChart")))
    }
    
    @Test @MainActor func customRendererReturnsView() {
        let registry = SwiftUINodeRendererRegistry()
        registry.register(TestChartRenderer())
        
        let stateStore = StateStore()
        let actionContext = createSwiftUITestActionContext(stateStore: stateStore)
        let tree = createTestRenderTree()
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: registry
        )
        
        let chartNode = TestChartNode(dataPoints: [1, 2, 3])
        let node = RenderNode.custom(kind: TestChartNode.kind, node: chartNode)
        
        let view = registry.render(node, context: context)
        
        #expect(view != nil)
    }
}

// MARK: - RenderNode Kind Tests

struct SwiftUIRenderNodeKindTests {
    
    @Test func textNodeReturnsTextKind() {
        let node = RenderNode.text(TextNode(
            content: "Test",
            style: IR.Style(),
            padding: .zero
        ))
        
        #expect(node.kind == .text)
    }
    
    @Test func buttonNodeReturnsButtonKind() {
        let node = RenderNode.button(ButtonNode(
            label: "Test",
            styles: ButtonStyles()
        ))
        
        #expect(node.kind == .button)
    }
    
    @Test func containerNodeReturnsContainerKind() {
        let node = RenderNode.container(ContainerNode(
            layoutType: .vstack,
            children: []
        ))
        
        #expect(node.kind == .container)
    }
    
    @Test func spacerNodeReturnsSpacerKind() {
        let node = RenderNode.spacer
        
        #expect(node.kind == .spacer)
    }
    
    @Test func textFieldNodeReturnsTextFieldKind() {
        let node = RenderNode.textField(TextFieldNode(
            placeholder: "Test",
            style: IR.Style(),
            bindingPath: nil
        ))
        
        #expect(node.kind == .textField)
    }
    
    @Test func toggleNodeReturnsToggleKind() {
        let node = RenderNode.toggle(ToggleNode(
            bindingPath: nil,
            style: IR.Style()
        ))
        
        #expect(node.kind == .toggle)
    }
    
    @Test func sliderNodeReturnsSliderKind() {
        let node = RenderNode.slider(SliderNode(
            bindingPath: nil,
            minValue: 0,
            maxValue: 1
        ))
        
        #expect(node.kind == .slider)
    }
    
    @Test func imageNodeReturnsImageKind() {
        let node = RenderNode.image(ImageNode(
            source: .system(name: "star"),
            style: IR.Style()
        ))
        
        #expect(node.kind == .image)
    }
    
    @Test func gradientNodeReturnsGradientKind() {
        let node = RenderNode.gradient(GradientNode(
            colors: [],
            startPoint: .top,
            endPoint: .bottom,
            style: IR.Style()
        ))
        
        #expect(node.kind == .gradient)
    }
    
    @Test func sectionLayoutNodeReturnsSectionLayoutKind() {
        let node = RenderNode.sectionLayout(SectionLayoutNode(
            sections: []
        ))
        
        #expect(node.kind == .sectionLayout)
    }
    
    @Test func customNodeReturnsCustomKind() {
        struct TestNode: CustomRenderNode {
            static let kind = RenderNodeKind(rawValue: "test")
        }
        
        let node = RenderNode.custom(kind: TestNode.kind, node: TestNode())
        
        #expect(node.kind == TestNode.kind)
    }
}
