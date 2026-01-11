//
//  ResolutionContextTests.swift
//  CLADSTests
//
//  Unit tests for ResolutionContext - context creation and value resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Context Creation Tests

struct ResolutionContextCreationTests {
    
    @Test @MainActor func createsContextWithoutTracking() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let stateStore = StateStore()
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        #expect(context.document.id == "test")
        #expect(context.stateStore === stateStore)
    }
    
    @Test @MainActor func createsContextWithTracking() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let stateStore = StateStore()
        let tracker = DependencyTracker()
        
        let context = ResolutionContext.withTracking(
            document: document,
            stateStore: stateStore,
            tracker: tracker
        )
        
        #expect(context.tracker != nil)
        #expect(context.isTracking == true)
    }
    
    @Test @MainActor func contextWithoutTrackingHasNilTracker() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        #expect(context.tracker == nil)
        #expect(context.isTracking == false)
        #expect(context.parentViewNode == nil)
    }
    
    @Test @MainActor func contextAccessesDocument() throws {
        let document = Document.Definition(
            id: "myDoc",
            version: "1.5",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        #expect(context.document.id == "myDoc")
        #expect(context.document.version == "1.5")
    }
}

// MARK: - Style Resolution Tests

struct ResolutionContextStyleTests {
    
    @Test @MainActor func resolvesNamedStyle() throws {
        let document = Document.Definition(
            id: "test",
            styles: [
                "titleStyle": Document.Style(
                    fontSize: 24,
                    fontWeight: .bold
                )
            ],
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let resolved = context.styleResolver.resolve("titleStyle")
        
        #expect(resolved.fontSize == 24)
        #expect(resolved.fontWeight == .bold)
    }
    
    @Test @MainActor func returnsEmptyStyleForNilName() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let resolved = context.styleResolver.resolve(nil)
        
        // Should return default/empty style
        #expect(resolved.fontSize == nil)
        #expect(resolved.fontWeight == nil)
    }
    
    @Test @MainActor func resolvesStyleWithInheritance() throws {
        let document = Document.Definition(
            id: "test",
            styles: [
                "baseStyle": Document.Style(
                    fontSize: 16,
                    textColor: "#000000"
                ),
                "titleStyle": Document.Style(
                    inherits: "baseStyle",
                    fontSize: 24,
                    fontWeight: .bold
                )
            ],
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let resolved = context.styleResolver.resolve("titleStyle")
        
        // Overridden property
        #expect(resolved.fontSize == 24)
        // Own property
        #expect(resolved.fontWeight == .bold)
        // Inherited from parent (textColor gets converted to Color)
        #expect(resolved.textColor != nil)
    }
    
    @Test @MainActor func returnsDefaultStyleForUnknownName() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let resolved = context.styleResolver.resolve("nonExistentStyle")
        
        // Should return default/empty style
        #expect(resolved.fontSize == nil)
        #expect(resolved.fontWeight == nil)
    }
}

// MARK: - State Value Resolution Tests

struct ResolutionContextStateTests {
    
    @Test @MainActor func resolvesStringFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["name": .stringValue("John")],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("name") as? String
        #expect(value == "John")
    }
    
    @Test @MainActor func resolvesIntFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["count": .intValue(42)],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("count") as? Int
        #expect(value == 42)
    }
    
    @Test @MainActor func resolvesBoolFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["isActive": .boolValue(true)],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("isActive") as? Bool
        #expect(value == true)
    }
    
    @Test @MainActor func resolvesDoubleFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["progress": .doubleValue(0.75)],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("progress") as? Double
        #expect(value == 0.75)
    }
    
    @Test @MainActor func resolvesNestedPathFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: [
                "user": .objectValue([
                    "profile": .objectValue([
                        "name": .stringValue("Alice")
                    ])
                ])
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("user.profile.name") as? String
        #expect(value == "Alice")
    }
    
    @Test @MainActor func returnsNilForMissingPath() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let value = context.stateStore.get("nonExistent")
        #expect(value == nil)
    }
    
    @Test @MainActor func resolvesArrayFromState() throws {
        let document = Document.Definition(
            id: "test",
            state: [
                "items": .arrayValue([
                    .stringValue("one"),
                    .stringValue("two"),
                    .stringValue("three")
                ])
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let value = context.stateStore.get("items") as? [Any]
        #expect(value?.count == 3)
    }
}

// MARK: - Iteration Variables Tests

struct ResolutionContextIterationTests {
    
    @Test @MainActor func accessesIterationVariable() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        var context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        // Add iteration variables as a dictionary
        context = context.withIterationVariables([
            "currentItem": ["name": "Item One", "id": 1],
            "currentIndex": 0
        ])
        
        // Access via getValue which checks iteration variables first
        let name = context.getValue("currentItem") as? [String: Any]
        let index = context.getValue("currentIndex") as? Int
        
        #expect(name?["name"] as? String == "Item One")
        #expect(index == 0)
    }
    
    @Test @MainActor func accessesMultipleIterationVariables() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        var context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        // First iteration level
        context = context.withIterationVariables([
            "section": ["title": "Section 1"],
            "sectionIndex": 0
        ])
        
        // Second iteration level (nested) - merges with existing
        context = context.withIterationVariables([
            "item": "Nested Item",
            "itemIndex": 2
        ])
        
        let section = context.getValue("section") as? [String: Any]
        let sectionIndex = context.getValue("sectionIndex") as? Int
        let item = context.getValue("item") as? String
        let itemIndex = context.getValue("itemIndex") as? Int
        
        #expect(section?["title"] as? String == "Section 1")
        #expect(sectionIndex == 0)
        #expect(item == "Nested Item")
        #expect(itemIndex == 2)
    }
    
    @Test @MainActor func iterationVariablesTakePrecedenceOverState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["value": .stringValue("from state")],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        var context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        // Add iteration variable with same name as state
        context = context.withIterationVariables(["value": "from iteration"])
        
        // getValue should return iteration variable
        let value = context.getValue("value") as? String
        #expect(value == "from iteration")
    }
}

// MARK: - Action Resolution Tests

struct ResolutionContextActionTests {
    
    @Test @MainActor func resolvesNamedAction() throws {
        let document = Document.Definition(
            id: "test",
            actions: [
                "submitAction": .dismiss,
                "toggleAction": .toggleState(Document.ToggleStateAction(path: "isOn"))
            ],
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let action = context.document.actions?["submitAction"]
        #expect(action != nil)
        
        if case .dismiss = action {
            // Success
        } else {
            Issue.record("Expected dismiss action")
        }
    }
}

// MARK: - Child Context Creation Tests

struct ResolutionContextChildContextTests {
    
    @Test @MainActor func createsChildContextWithViewNode() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let tracker = DependencyTracker()
        let parentNode = ViewNode(id: "parent", nodeType: .spacer)
        
        let context = ResolutionContext(
            document: document,
            styleResolver: StyleResolver(styles: document.styles),
            stateStore: StateStore(),
            tracker: tracker,
            parentViewNode: parentNode
        )
        
        let childNode = ViewNode(id: "child", nodeType: .spacer)
        let childContext = context.withParent(childNode)
        
        #expect(childContext.parentViewNode?.id == "child")
        #expect(childContext.document.id == "test") // Preserves document
    }
    
    @Test @MainActor func childContextSharesStateStore() throws {
        let document = Document.Definition(
            id: "test",
            state: ["shared": .intValue(100)],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let tracker = DependencyTracker()
        let parentNode = ViewNode(id: "parent", nodeType: .spacer)
        
        let context = ResolutionContext(
            document: document,
            styleResolver: StyleResolver(styles: document.styles),
            stateStore: stateStore,
            tracker: tracker,
            parentViewNode: parentNode
        )
        
        let childNode = ViewNode(id: "child", nodeType: .spacer)
        let childContext = context.withParent(childNode)
        
        let value = childContext.stateStore.get("shared") as? Int
        #expect(value == 100)
        
        // Mutate in child
        childContext.stateStore.set("shared", value: 200)
        
        // Should be reflected in parent's state store (same reference)
        let updatedValue = context.stateStore.get("shared") as? Int
        #expect(updatedValue == 200)
    }
    
    @Test @MainActor func childContextPreservesIterationVariables() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        var context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        // Add iteration variables
        context = context.withIterationVariables(["item": "test value"])
        
        // Create child with new parent
        let childNode = ViewNode(id: "child", nodeType: .spacer)
        let childContext = context.withParent(childNode)
        
        // Iteration variables should be preserved
        let value = childContext.getValue("item") as? String
        #expect(value == "test value")
    }
}

// MARK: - Interpolation Tests

struct ResolutionContextInterpolationTests {
    
    @Test @MainActor func interpolatesStateValues() throws {
        let document = Document.Definition(
            id: "test",
            state: [
                "name": .stringValue("World"),
                "count": .intValue(42)
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: stateStore
        )
        
        let result = context.interpolate("Hello ${name}! Count: ${count}")
        #expect(result == "Hello World! Count: 42")
    }
    
    @Test @MainActor func interpolatesIterationVariables() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        var context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        context = context.withIterationVariables([
            "item": "Test Item",
            "index": 5
        ])
        
        let result = context.interpolate("Item ${index}: ${item}")
        #expect(result == "Item 5: Test Item")
    }
    
    @Test @MainActor func returnsTemplateWithMissingValues() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let result = context.interpolate("Value: ${missing}")
        // Missing values should resolve to empty string
        #expect(result == "Value: ")
    }
}
