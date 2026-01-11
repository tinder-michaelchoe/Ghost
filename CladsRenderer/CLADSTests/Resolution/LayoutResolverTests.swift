//
//  LayoutResolverTests.swift
//  CLADSTests
//
//  Unit tests for LayoutResolver - container and forEach resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Test Helpers

/// Creates a minimal resolution context for testing
@MainActor
func createTestContext(
    state: [String: Document.StateValue] = [:],
    styles: [String: Document.Style] = [:]
) -> ResolutionContext {
    let document = Document.Definition(
        id: "test",
        state: state,
        styles: styles,
        root: Document.RootComponent(children: [])
    )
    let stateStore = StateStore()
    stateStore.initialize(from: document.state)
    return ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
}

// MARK: - VStack Resolution Tests

struct LayoutResolverVStackTests {
    
    @Test @MainActor func resolvesBasicVStack() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            children: [.spacer]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.layoutType == .vstack)
            #expect(container.children.count == 1)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesVStackWithSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            spacing: 16,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.spacing == 16)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesVStackWithDefaultSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.spacing == 0)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesVStackWithLeadingAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            horizontalAlignment: .leading,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.alignment.horizontal == .leading)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesVStackWithCenterAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            horizontalAlignment: .center,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.alignment.horizontal == .center)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesVStackWithTrailingAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            horizontalAlignment: .trailing,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.alignment.horizontal == .trailing)
        } else {
            Issue.record("Expected container node")
        }
    }
}

// MARK: - HStack Resolution Tests

struct LayoutResolverHStackTests {
    
    @Test @MainActor func resolvesBasicHStack() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .hstack,
            children: [.spacer, .spacer]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.layoutType == .hstack)
            #expect(container.children.count == 2)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesHStackWithSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .hstack,
            spacing: 8,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.spacing == 8)
        } else {
            Issue.record("Expected container node")
        }
    }
}

// MARK: - ZStack Resolution Tests

struct LayoutResolverZStackTests {
    
    @Test @MainActor func resolvesBasicZStack() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .zstack,
            children: [.spacer]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.layoutType == .zstack)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesZStackWith2DAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .zstack,
            alignment: Document.Alignment(horizontal: .trailing, vertical: .bottom),
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.alignment.horizontal == .trailing)
            #expect(container.alignment.vertical == .bottom)
        } else {
            Issue.record("Expected container node")
        }
    }
}

// MARK: - Padding Resolution Tests

struct LayoutResolverPaddingTests {
    
    @Test @MainActor func resolvesLayoutWithPadding() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            padding: Document.Padding(top: 10, bottom: 20, leading: 5, trailing: 15),
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.padding.top == 10)
            #expect(container.padding.bottom == 20)
            #expect(container.padding.leading == 5)
            #expect(container.padding.trailing == 15)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesLayoutWithHorizontalVerticalPadding() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            padding: Document.Padding(horizontal: 20, vertical: 10),
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.padding.leading == 20)
            #expect(container.padding.trailing == 20)
            #expect(container.padding.top == 10)
            #expect(container.padding.bottom == 10)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func resolvesLayoutWithNoPadding() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            children: []
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.padding.isEmpty)
        } else {
            Issue.record("Expected container node")
        }
    }
}

// MARK: - Nested Layout Tests

struct LayoutResolverNestedTests {
    
    @Test @MainActor func resolvesNestedLayouts() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            children: [
                .layout(Document.Layout(type: .hstack, children: [.spacer])),
                .layout(Document.Layout(type: .hstack, children: [.spacer, .spacer]))
            ]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let vstack) = result.renderNode {
            #expect(vstack.children.count == 2)
            
            if case .container(let hstack1) = vstack.children[0] {
                #expect(hstack1.layoutType == .hstack)
                #expect(hstack1.children.count == 1)
            } else {
                Issue.record("Expected first hstack")
            }
            
            if case .container(let hstack2) = vstack.children[1] {
                #expect(hstack2.layoutType == .hstack)
                #expect(hstack2.children.count == 2)
            } else {
                Issue.record("Expected second hstack")
            }
        } else {
            Issue.record("Expected vstack container")
        }
    }
    
    @Test @MainActor func resolvesDeeplyNestedLayouts() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .vstack,
            children: [
                .layout(Document.Layout(
                    type: .hstack,
                    children: [
                        .layout(Document.Layout(
                            type: .zstack,
                            children: [.spacer]
                        ))
                    ]
                ))
            ]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let vstack) = result.renderNode {
            if case .container(let hstack) = vstack.children[0] {
                if case .container(let zstack) = hstack.children[0] {
                    #expect(zstack.layoutType == .zstack)
                    #expect(zstack.children.count == 1)
                } else {
                    Issue.record("Expected zstack")
                }
            } else {
                Issue.record("Expected hstack")
            }
        } else {
            Issue.record("Expected vstack")
        }
    }
}

// MARK: - ForEach Resolution Tests

struct LayoutResolverForEachTests {
    
    @Test @MainActor func resolvesForEachWithItems() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([
                .stringValue("one"),
                .stringValue("two"),
                .stringValue("three")
            ])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.children.count == 3)
        } else {
            Issue.record("Expected container node for forEach")
        }
    }
    
    @Test @MainActor func resolvesForEachWithEmptyArray() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.children.isEmpty)
        } else {
            Issue.record("Expected empty container node")
        }
    }
    
    @Test @MainActor func resolvesForEachWithMissingArray() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext() // No items in state
        
        let forEach = Document.ForEach(
            items: "nonExistentItems",
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.children.isEmpty)
        } else {
            Issue.record("Expected empty container node")
        }
    }
    
    @Test @MainActor func resolvesForEachWithVStackLayout() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([.intValue(1), .intValue(2)])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            layout: .vstack,
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.layoutType == .vstack)
        } else {
            Issue.record("Expected vstack container")
        }
    }
    
    @Test @MainActor func resolvesForEachWithHStackLayout() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([.intValue(1), .intValue(2)])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            layout: .hstack,
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.layoutType == .hstack)
        } else {
            Issue.record("Expected hstack container")
        }
    }
    
    @Test @MainActor func resolvesForEachWithSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([.intValue(1)])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            spacing: 12,
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.spacing == 12)
        } else {
            Issue.record("Expected container with spacing")
        }
    }
    
    @Test @MainActor func resolvesForEachWithEmptyView() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "items": .arrayValue([])
        ])
        
        let forEach = Document.ForEach(
            items: "items",
            template: .spacer,
            emptyView: .layout(Document.Layout(
                type: .vstack,
                children: [.spacer, .spacer]
            ))
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        // When array is empty, should render the emptyView
        if case .container(let container) = result.renderNode {
            #expect(container.children.count == 2)
        } else {
            Issue.record("Expected empty view container")
        }
    }
    
    @Test @MainActor func resolvesForEachContainerId() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext(state: [
            "myList": .arrayValue([.intValue(1)])
        ])
        
        let forEach = Document.ForEach(
            items: "myList",
            template: .spacer
        )
        
        let result = try resolver.resolveNode(.forEach(forEach), context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.id == "forEach_myList")
        } else {
            Issue.record("Expected container with forEach id")
        }
    }
}

// MARK: - Spacer Resolution Tests

struct LayoutResolverSpacerTests {
    
    @Test @MainActor func resolvesSpacerNode() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let result = try resolver.resolveNode(.spacer, context: context)
        
        if case .spacer = result.renderNode {
            // Success
        } else {
            Issue.record("Expected spacer node")
        }
    }
    
    @Test @MainActor func resolvesMixedChildrenWithSpacers() throws {
        let registry = ComponentResolverRegistry()
        let resolver = LayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let layout = Document.Layout(
            type: .hstack,
            children: [
                .spacer,
                .layout(Document.Layout(type: .vstack, children: [])),
                .spacer
            ]
        )
        
        let result = try resolver.resolve(layout, context: context)
        
        if case .container(let container) = result.renderNode {
            #expect(container.children.count == 3)
            if case .spacer = container.children[0] { } else { Issue.record("Expected first spacer") }
            if case .container = container.children[1] { } else { Issue.record("Expected middle container") }
            if case .spacer = container.children[2] { } else { Issue.record("Expected last spacer") }
        } else {
            Issue.record("Expected container node")
        }
    }
}
