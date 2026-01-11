//
//  ContentResolverTests.swift
//  CLADSTests
//
//  Unit tests for ContentResolver - resolving content from components.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Static Content Tests

struct ContentResolverStaticTests {
    
    @Test @MainActor func resolvesStaticTextFromComponent() throws {
        let context = createTestContext()
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            text: "Hello, World!"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Hello, World!")
        #expect(result.bindingPath == nil)
        #expect(result.bindingTemplate == nil)
        #expect(result.isDynamic == false)
    }
    
    @Test @MainActor func resolvesEmptyTextFromComponent() throws {
        let context = createTestContext()
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            text: ""
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "")
        #expect(result.isDynamic == false)
    }
    
    @Test @MainActor func resolvesNilTextAsEmpty() throws {
        let context = createTestContext()
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label")
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "")
    }
}

// MARK: - DataSource Resolution Tests

struct ContentResolverDataSourceTests {
    
    @Test @MainActor func resolvesStaticDataSource() throws {
        let document = Document.Definition(
            id: "test",
            dataSources: [
                "greeting": Document.DataSource(type: .static, value: "Hello from data source")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "greeting"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Hello from data source")
        #expect(result.isDynamic == false)
    }
    
    @Test @MainActor func resolvesBindingDataSourceWithPath() throws {
        let document = Document.Definition(
            id: "test",
            state: ["username": .stringValue("Alice")],
            dataSources: [
                "userName": Document.DataSource(type: .binding, path: "username")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "userName"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Alice")
        #expect(result.bindingPath == "username")
        #expect(result.isDynamic == true)
    }
    
    @Test @MainActor func resolvesBindingDataSourceWithTemplate() throws {
        let document = Document.Definition(
            id: "test",
            state: ["name": .stringValue("Bob")],
            dataSources: [
                "greetingTemplate": Document.DataSource(type: .binding, template: "Hello, ${name}!")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "greetingTemplate"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Hello, Bob!")
        #expect(result.bindingTemplate == "Hello, ${name}!")
        #expect(result.isDynamic == true)
    }
    
    @Test @MainActor func returnsFallbackForMissingDataSource() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(document: document, stateStore: StateStore())
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "nonExistent",
            text: "Fallback text"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        // Should fall back to text property
        #expect(result.content == "Fallback text")
    }
}

// MARK: - Inline Data Resolution Tests

struct ContentResolverInlineDataTests {
    
    @Test @MainActor func resolvesStaticInlineData() throws {
        let context = createTestContext()
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            data: ["value": Document.DataReference(type: .static, value: "Inline static value")]
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Inline static value")
        #expect(result.isDynamic == false)
    }
    
    @Test @MainActor func resolvesBindingInlineData() throws {
        let document = Document.Definition(
            id: "test",
            state: ["count": .intValue(42)],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            data: ["value": Document.DataReference(type: .binding, path: "count")]
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.bindingPath == "count")
        #expect(result.isDynamic == true)
    }
    
    @Test @MainActor func resolvesTemplateInlineData() throws {
        let document = Document.Definition(
            id: "test",
            state: [
                "firstName": .stringValue("John"),
                "lastName": .stringValue("Doe")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            data: ["value": Document.DataReference(type: .binding, template: "${firstName} ${lastName}")]
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "John Doe")
        #expect(result.bindingTemplate == "${firstName} ${lastName}")
        #expect(result.isDynamic == true)
    }
}

// MARK: - Dependency Tracking Tests

struct ContentResolverTrackingTests {
    
    @Test @MainActor func tracksBindingDependency() throws {
        let document = Document.Definition(
            id: "test",
            state: ["value": .stringValue("test")],
            dataSources: [
                "boundValue": Document.DataSource(type: .binding, path: "value")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let tracker = DependencyTracker()
        let context = ResolutionContext.withTracking(document: document, stateStore: stateStore, tracker: tracker)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "boundValue"
        )
        
        // Create a mock view node for tracking
        let viewNode = ViewNode(id: "testNode", nodeType: .spacer)
        tracker.beginTracking(for: viewNode)
        
        _ = ContentResolver.resolve(component, context: context, viewNode: viewNode)
        
        tracker.endTracking()
        
        // After tracking, the viewNode should have the read paths recorded
        #expect(viewNode.readPaths.contains("value"))
    }
    
    @Test @MainActor func tracksTemplateDependencies() throws {
        let document = Document.Definition(
            id: "test",
            state: [
                "first": .stringValue("A"),
                "second": .stringValue("B")
            ],
            dataSources: [
                "template": Document.DataSource(type: .binding, template: "${first} and ${second}")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let tracker = DependencyTracker()
        let context = ResolutionContext.withTracking(document: document, stateStore: stateStore, tracker: tracker)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "template"
        )
        
        let viewNode = ViewNode(id: "testNode", nodeType: .spacer)
        tracker.beginTracking(for: viewNode)
        
        _ = ContentResolver.resolve(component, context: context, viewNode: viewNode)
        
        tracker.endTracking()
        
        // Should track both paths from the template
        #expect(viewNode.readPaths.contains("first"))
        #expect(viewNode.readPaths.contains("second"))
    }
    
    @Test @MainActor func staticContentDoesNotTrackDependency() throws {
        let document = Document.Definition(
            id: "test",
            dataSources: [
                "staticValue": Document.DataSource(type: .static, value: "Static text")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let tracker = DependencyTracker()
        let context = ResolutionContext.withTracking(document: document, stateStore: StateStore(), tracker: tracker)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "staticValue"
        )
        
        let viewNode = ViewNode(id: "testNode", nodeType: .spacer)
        tracker.beginTracking(for: viewNode)
        
        _ = ContentResolver.resolve(component, context: context, viewNode: viewNode)
        
        tracker.endTracking()
        
        // Static content should not add read paths
        #expect(viewNode.readPaths.isEmpty)
    }
}

// MARK: - ContentResolutionResult Tests

struct ContentResolutionResultTests {
    
    @Test func staticResultIsNotDynamic() {
        let result = ContentResolutionResult(content: "Static")
        
        #expect(result.isDynamic == false)
        #expect(result.bindingPath == nil)
        #expect(result.bindingTemplate == nil)
    }
    
    @Test func resultWithBindingPathIsDynamic() {
        let result = ContentResolutionResult(content: "Value", bindingPath: "path.to.value")
        
        #expect(result.isDynamic == true)
        #expect(result.bindingPath == "path.to.value")
    }
    
    @Test func resultWithBindingTemplateIsDynamic() {
        let result = ContentResolutionResult(content: "Hello World", bindingTemplate: "Hello ${name}")
        
        #expect(result.isDynamic == true)
        #expect(result.bindingTemplate == "Hello ${name}")
    }
    
    @Test func staticFactoryCreatesNonDynamicResult() {
        let result = ContentResolutionResult.static("Static content")
        
        #expect(result.content == "Static content")
        #expect(result.isDynamic == false)
    }
}

// MARK: - Iteration Variable Tests

struct ContentResolverIterationTests {
    
    @Test @MainActor func resolvesIterationVariableInTemplate() throws {
        let document = Document.Definition(
            id: "test",
            dataSources: [
                "itemTemplate": Document.DataSource(type: .binding, template: "Item: ${item}")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        var context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        // Add iteration variable
        context = context.withIterationVariables(["item": "First Item"])
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "itemTemplate"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Item: First Item")
    }
    
    @Test @MainActor func resolvesNestedIterationVariables() throws {
        let document = Document.Definition(
            id: "test",
            dataSources: [
                "nestedTemplate": Document.DataSource(type: .binding, template: "${section} > ${item}")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        var context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        // Outer iteration
        context = context.withIterationVariables(["section": "Section A"])
        // Inner iteration
        context = context.withIterationVariables(["item": "Item 1"])
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "nestedTemplate"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "Section A > Item 1")
    }
    
    @Test @MainActor func iterationVariablesTakePrecedenceOverState() throws {
        let document = Document.Definition(
            id: "test",
            state: ["value": .stringValue("from state")],
            dataSources: [
                "valueTemplate": Document.DataSource(type: .binding, template: "${value}")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        var context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        // Add iteration variable with same name
        context = context.withIterationVariables(["value": "from iteration"])
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "valueTemplate"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        // Iteration variable should take precedence
        #expect(result.content == "from iteration")
    }
}

// MARK: - Missing/Invalid State Tests

struct ContentResolverMissingStateTests {
    
    @Test @MainActor func resolvesEmptyForMissingBindingPath() throws {
        let document = Document.Definition(
            id: "test",
            dataSources: [
                "missingBinding": Document.DataSource(type: .binding, path: "nonExistent")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let context = ResolutionContext.withoutTracking(document: document, stateStore: StateStore())
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "missingBinding"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        #expect(result.content == "")
        #expect(result.bindingPath == "nonExistent")
    }
    
    @Test @MainActor func resolvesTemplateWithMissingVariables() throws {
        let document = Document.Definition(
            id: "test",
            state: ["existing": .stringValue("exists")],
            dataSources: [
                "partialTemplate": Document.DataSource(type: .binding, template: "${existing} and ${missing}")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)
        let context = ResolutionContext.withoutTracking(document: document, stateStore: stateStore)
        
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            dataSourceId: "partialTemplate"
        )
        
        let result = ContentResolver.resolve(component, context: context)
        
        // Missing variable should resolve to empty string
        #expect(result.content == "exists and ")
    }
}
