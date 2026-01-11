//
//  ResolverTests.swift
//  CLADSTests
//
//  Unit tests for the main Resolver that orchestrates Document-to-IR resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Basic Resolution Tests

struct ResolverBasicTests {
    
    @Test @MainActor func resolvesMinimalDocument() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.children.isEmpty)
        #expect(renderTree.actions.isEmpty)
    }
    
    @Test @MainActor func resolvesDocumentWithVersion() throws {
        let document = Document.Definition(
            id: "test-doc",
            version: "1.0",
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.children.isEmpty)
    }
    
    @Test @MainActor func initializesStateFromDocument() throws {
        let document = Document.Definition(
            id: "test-doc",
            state: [
                "count": .intValue(42),
                "name": .stringValue("Test"),
                "active": .boolValue(true)
            ],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.stateStore.get("count") as? Int == 42)
        #expect(renderTree.stateStore.get("name") as? String == "Test")
        #expect(renderTree.stateStore.get("active") as? Bool == true)
    }
    
    @Test @MainActor func usesInjectedStateStore() throws {
        let document = Document.Definition(
            id: "test-doc",
            state: ["count": .intValue(0)],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let stateStore = StateStore()
        stateStore.set("count", value: 100)
        
        let renderTree = try resolver.resolve(into: stateStore, initializeFromDocument: false)
        
        // Should use injected value, not document's initial value
        #expect(renderTree.stateStore.get("count") as? Int == 100)
    }
    
    @Test @MainActor func mergesStateWhenInitializingFromDocument() throws {
        let document = Document.Definition(
            id: "test-doc",
            state: [
                "docValue": .stringValue("from document"),
                "shared": .intValue(10)
            ],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let stateStore = StateStore()
        stateStore.set("existingValue", value: "pre-existing")
        
        let renderTree = try resolver.resolve(into: stateStore, initializeFromDocument: true)
        
        #expect(renderTree.stateStore.get("existingValue") as? String == "pre-existing")
        #expect(renderTree.stateStore.get("docValue") as? String == "from document")
    }
}

// MARK: - Root Node Resolution Tests

struct ResolverRootNodeTests {
    
    @Test @MainActor func resolvesRootBackgroundColor() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                backgroundColor: "#FF0000",
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.backgroundColor != nil)
    }
    
    @Test @MainActor func resolvesRootColorSchemeLight() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                colorScheme: "light",
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.colorScheme == .light)
    }
    
    @Test @MainActor func resolvesRootColorSchemeDark() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                colorScheme: "dark",
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.colorScheme == .dark)
    }
    
    @Test @MainActor func resolvesRootColorSchemeSystem() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                colorScheme: "system",
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.colorScheme == .system)
    }
    
    @Test @MainActor func resolvesRootEdgeInsets() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                edgeInsets: Document.EdgeInsets(
                    top: Document.EdgeInset(positioning: .safeArea, value: 20),
                    bottom: Document.EdgeInset(positioning: .absolute, value: 10)
                ),
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.edgeInsets?.top?.value == 20)
        #expect(renderTree.root.edgeInsets?.top?.positioning == .safeArea)
        #expect(renderTree.root.edgeInsets?.bottom?.value == 10)
        #expect(renderTree.root.edgeInsets?.bottom?.positioning == .absolute)
    }
}

// MARK: - Action Resolution Tests

struct ResolverActionTests {
    
    @Test @MainActor func resolvesNamedActions() throws {
        let document = Document.Definition(
            id: "test-doc",
            actions: [
                "dismissAction": .dismiss,
                "toggleAction": .toggleState(Document.ToggleStateAction(path: "isActive"))
            ],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.actions.count == 2)
        
        if case .dismiss = renderTree.actions["dismissAction"] {
            // Success
        } else {
            Issue.record("Expected dismiss action")
        }
        
        if case .toggleState(let path) = renderTree.actions["toggleAction"] {
            #expect(path == "isActive")
        } else {
            Issue.record("Expected toggleState action")
        }
    }
    
    @Test @MainActor func resolvesRootActions() throws {
        let document = Document.Definition(
            id: "test-doc",
            actions: ["onLoadAction": .dismiss],
            root: Document.RootComponent(
                actions: Document.RootActions(
                    onAppear: .reference("onLoadAction")
                ),
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.actions.action(for: .onAppear) != nil)
    }
}

// MARK: - Child Resolution Tests

struct ResolverChildResolutionTests {
    
    @Test @MainActor func resolvesSpacerChild() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                children: [.spacer]
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.children.count == 1)
        if case .spacer = renderTree.root.children[0] {
            // Success
        } else {
            Issue.record("Expected spacer node")
        }
    }
    
    @Test @MainActor func resolvesLayoutChild() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                children: [
                    .layout(Document.Layout(
                        type: .vstack,
                        children: [.spacer]
                    ))
                ]
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        #expect(renderTree.root.children.count == 1)
        if case .container(let container) = renderTree.root.children[0] {
            #expect(container.layoutType == .vstack)
            #expect(container.children.count == 1)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesNestedLayouts() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                children: [
                    .layout(Document.Layout(
                        type: .vstack,
                        children: [
                            .layout(Document.Layout(
                                type: .hstack,
                                children: [.spacer, .spacer]
                            ))
                        ]
                    ))
                ]
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let renderTree = try resolver.resolve()
        
        if case .container(let vstack) = renderTree.root.children[0] {
            #expect(vstack.layoutType == .vstack)
            if case .container(let hstack) = vstack.children[0] {
                #expect(hstack.layoutType == .hstack)
                #expect(hstack.children.count == 2)
            } else {
                Issue.record("Expected nested hstack")
            }
        } else {
            Issue.record("Expected vstack container")
        }
    }
}

// MARK: - Resolution With Tracking Tests

struct ResolverTrackingTests {
    
    @Test @MainActor func resolveWithTrackingReturnsViewTree() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(children: [.spacer])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let result = try resolver.resolveWithTracking()
        
        #expect(result.renderTree.root.children.count == 1)
        #expect(result.viewTreeRoot.children.count == 1)
    }
    
    @Test @MainActor func resolveWithTrackingUsesInjectedStateStore() throws {
        let document = Document.Definition(
            id: "test-doc",
            state: ["value": .intValue(0)],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        let stateStore = StateStore()
        stateStore.set("value", value: 999)
        
        let result = try resolver.resolveWithTracking(into: stateStore, initializeFromDocument: false)
        
        #expect(result.renderTree.stateStore.get("value") as? Int == 999)
    }
}

// MARK: - Error Handling Tests

struct ResolverErrorTests {
    
    @Test @MainActor func throwsForUnknownComponentKind() throws {
        let document = Document.Definition(
            id: "test-doc",
            root: Document.RootComponent(
                children: [
                    .component(Document.Component(
                        type: Document.ComponentKind(rawValue: "unknownType")
                    ))
                ]
            )
        )
        
        let registry = ComponentResolverRegistry()
        // Don't register any resolvers
        let resolver = Resolver(document: document, componentRegistry: registry)
        
        #expect(throws: ComponentResolutionError.self) {
            _ = try resolver.resolve()
        }
    }
}
