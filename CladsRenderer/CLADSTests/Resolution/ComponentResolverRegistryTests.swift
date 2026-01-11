//
//  ComponentResolverRegistryTests.swift
//  CLADSTests
//
//  Unit tests for ComponentResolverRegistry - registration, lookup, and resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Test Component Kinds

/// Predefined component kinds for testing
private enum TestComponentKind {
    static let label = Document.ComponentKind(rawValue: "label")
    static let button = Document.ComponentKind(rawValue: "button")
    static let customWidget = Document.ComponentKind(rawValue: "customWidget")
}

// MARK: - Test Resolver Implementations

/// A simple test resolver for testing registration
struct TestLabelResolver: ComponentResolving {
    static let componentKind = TestComponentKind.label
    
    @MainActor
    func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let node = TextNode(id: component.id, content: component.text ?? "")
        return .renderOnly(.text(node))
    }
}

/// Another test resolver for buttons
struct TestButtonResolver: ComponentResolving {
    static let componentKind = TestComponentKind.button
    
    @MainActor
    func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let node = ButtonNode(id: component.id, label: component.text ?? "")
        return .renderOnly(.button(node))
    }
}

/// Test resolver for custom component types
struct TestCustomTypeResolver: ComponentResolving {
    static let componentKind = TestComponentKind.customWidget
    
    @MainActor
    func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let node = TextNode(id: component.id, content: "custom")
        return .renderOnly(.text(node))
    }
}

// MARK: - Registration Tests

struct ComponentResolverRegistryRegistrationTests {
    
    @Test func registersResolver() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        
        #expect(registry.hasResolver(for: TestComponentKind.label))
    }
    
    @Test func registersMultipleResolvers() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        registry.register(TestButtonResolver())
        
        #expect(registry.hasResolver(for: TestComponentKind.label))
        #expect(registry.hasResolver(for: TestComponentKind.button))
    }
    
    @Test func registersCustomComponentKind() {
        let registry = ComponentResolverRegistry()
        registry.register(TestCustomTypeResolver())
        
        #expect(registry.hasResolver(for: TestComponentKind.customWidget))
    }
    
    @Test func unregistersResolver() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        
        #expect(registry.hasResolver(for: TestComponentKind.label))
        
        registry.unregister(TestComponentKind.label)
        
        #expect(!registry.hasResolver(for: TestComponentKind.label))
    }
    
    @Test func returnsRegisteredKinds() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        registry.register(TestButtonResolver())
        
        let kinds = registry.registeredKinds
        
        #expect(kinds.contains(TestComponentKind.label))
        #expect(kinds.contains(TestComponentKind.button))
        #expect(kinds.count == 2)
    }
    
    @Test func replacesExistingResolver() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        registry.register(TestLabelResolver()) // Re-register same kind
        
        let kinds = registry.registeredKinds
        #expect(kinds.filter { $0 == TestComponentKind.label }.count == 1)
    }
}

// MARK: - Lookup Tests

struct ComponentResolverRegistryLookupTests {
    
    @Test func hasResolverReturnsFalseForUnregistered() {
        let registry = ComponentResolverRegistry()
        
        #expect(!registry.hasResolver(for: TestComponentKind.label))
        #expect(!registry.hasResolver(for: TestComponentKind.button))
    }
    
    @Test func hasResolverReturnsTrueForRegistered() {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        
        #expect(registry.hasResolver(for: TestComponentKind.label))
    }
    
    @Test func registeredKindsIsEmptyInitially() {
        let registry = ComponentResolverRegistry()
        
        #expect(registry.registeredKinds.isEmpty)
    }
}

// MARK: - Resolution Tests

struct ComponentResolverRegistryResolutionTests {
    
    @Test @MainActor func resolvesRegisteredComponent() throws {
        let registry = ComponentResolverRegistry()
        registry.register(TestLabelResolver())
        
        let component = Document.Component(type: TestComponentKind.label, text: "Hello")
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let result = try registry.resolve(component, context: context)
        
        if case .text(let textNode) = result.renderNode {
            #expect(textNode.content == "Hello")
        } else {
            Issue.record("Expected text node")
        }
    }
    
    @Test @MainActor func resolvesButtonComponent() throws {
        let registry = ComponentResolverRegistry()
        registry.register(TestButtonResolver())
        
        let component = Document.Component(type: TestComponentKind.button, text: "Click Me")
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        let result = try registry.resolve(component, context: context)
        
        if case .button(let buttonNode) = result.renderNode {
            #expect(buttonNode.label == "Click Me")
        } else {
            Issue.record("Expected button node")
        }
    }
    
    @Test @MainActor func throwsForUnknownComponentKind() throws {
        let registry = ComponentResolverRegistry()
        // Don't register any resolvers
        
        let component = Document.Component(type: TestComponentKind.label)
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        #expect(throws: ComponentResolutionError.self) {
            _ = try registry.resolve(component, context: context)
        }
    }
    
    @Test @MainActor func throwsCorrectErrorForUnknownKind() throws {
        let registry = ComponentResolverRegistry()
        
        let unknownKind = Document.ComponentKind(rawValue: "unknownWidget")
        let component = Document.Component(type: unknownKind)
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        let context = ResolutionContext.withoutTracking(
            document: document,
            stateStore: StateStore()
        )
        
        do {
            _ = try registry.resolve(component, context: context)
            Issue.record("Should have thrown")
        } catch let error as ComponentResolutionError {
            if case .unknownKind(let kind) = error {
                #expect(kind.rawValue == "unknownWidget")
            } else {
                Issue.record("Expected unknownKind error")
            }
        }
    }
}

// MARK: - Error Description Tests

struct ComponentResolutionErrorTests {
    
    @Test func errorDescriptionContainsKindName() {
        let error = ComponentResolutionError.unknownKind(Document.ComponentKind(rawValue: "myWidget"))
        
        #expect(error.errorDescription?.contains("myWidget") == true)
    }
    
    @Test func errorDescriptionMentionsNoResolver() {
        let error = ComponentResolutionError.unknownKind(TestComponentKind.label)
        
        #expect(error.errorDescription?.lowercased().contains("no resolver") == true)
    }
}

// MARK: - Custom Component Registry Integration Tests

struct ComponentResolverRegistryCustomComponentTests {
    
    @Test func hasResolverReturnsFalseWithoutCustomRegistry() {
        let registry = ComponentResolverRegistry()
        
        // No custom registry set
        #expect(!registry.hasResolver(for: Document.ComponentKind(rawValue: "customType")))
    }
}
