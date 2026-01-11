//
//  ForEachTests.swift
//  CLADSTests
//
//  Unit tests for Document.ForEach JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Required Fields Tests

struct ForEachRequiredFieldsTests {
    
    @Test func decodesMinimalForEach() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": {
                "type": "label",
                "text": "${item}"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.type == "forEach")
            #expect(forEach.items == "items")
            if case .component(let template) = forEach.template {
                #expect(template.type.rawValue == "label")
            }
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func decodesForEachWithNestedPath() throws {
        let json = """
        {
            "type": "forEach",
            "items": "user.favorites",
            "template": {
                "type": "label",
                "text": "${item.name}"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.items == "user.favorites")
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Default Values Tests

struct ForEachDefaultValuesTests {
    
    @Test func defaultItemVariable() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.itemVariable == "item")
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func defaultIndexVariable() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.indexVariable == "index")
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func defaultLayout() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.layout == .vstack)
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Custom Variables Tests

struct ForEachCustomVariablesTests {
    
    @Test func customItemVariable() throws {
        let json = """
        {
            "type": "forEach",
            "items": "products",
            "itemVariable": "product",
            "template": {
                "type": "label",
                "text": "${product.name}"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.itemVariable == "product")
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func customIndexVariable() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "indexVariable": "idx",
            "template": {
                "type": "label",
                "text": "Item ${idx}"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.indexVariable == "idx")
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func bothCustomVariables() throws {
        let json = """
        {
            "type": "forEach",
            "items": "users",
            "itemVariable": "user",
            "indexVariable": "userIndex",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.itemVariable == "user")
            #expect(forEach.indexVariable == "userIndex")
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Layout Options Tests

struct ForEachLayoutOptionsTests {
    
    @Test func vstackLayout() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "layout": "vstack",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.layout == .vstack)
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func hstackLayout() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "layout": "hstack",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.layout == .hstack)
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func zstackLayout() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "layout": "zstack",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.layout == .zstack)
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Optional Fields Tests

struct ForEachOptionalFieldsTests {
    
    @Test func decodesSpacing() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "spacing": 12,
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.spacing == 12)
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func decodesAlignment() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "alignment": "center",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.alignment == .center)
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func decodesPadding() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "padding": { "horizontal": 16, "vertical": 8 },
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.padding?.horizontal == 16)
            #expect(forEach.padding?.vertical == 8)
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func decodesEmptyView() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label", "text": "${item}" },
            "emptyView": {
                "type": "label",
                "text": "No items found"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            if case .component(let emptyView) = forEach.emptyView {
                #expect(emptyView.text == "No items found")
            } else {
                Issue.record("Expected emptyView component")
            }
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func noEmptyViewByDefault() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label" }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.emptyView == nil)
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Complex Template Tests

struct ForEachComplexTemplateTests {
    
    @Test func decodesLayoutTemplate() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": {
                "type": "hstack",
                "spacing": 8,
                "children": [
                    { "type": "label", "text": "${item.name}" },
                    { "type": "spacer" },
                    { "type": "label", "text": "${item.value}" }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            if case .layout(let template) = forEach.template {
                #expect(template.type == .hstack)
                #expect(template.children.count == 3)
            } else {
                Issue.record("Expected layout template")
            }
        } else {
            Issue.record("Expected forEach")
        }
    }
    
    @Test func decodesComplexEmptyView() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": { "type": "label" },
            "emptyView": {
                "type": "vstack",
                "alignment": "center",
                "spacing": 16,
                "children": [
                    { "type": "image", "image": { "system": "tray" } },
                    { "type": "label", "text": "No items" },
                    { "type": "button", "text": "Add Item" }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            if case .layout(let emptyView) = forEach.emptyView {
                #expect(emptyView.type == .vstack)
                #expect(emptyView.children.count == 3)
            } else {
                Issue.record("Expected layout emptyView")
            }
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Full ForEach Tests

struct ForEachFullTests {
    
    @Test func decodesFullForEach() throws {
        let json = """
        {
            "type": "forEach",
            "items": "interests",
            "itemVariable": "interest",
            "indexVariable": "idx",
            "layout": "hstack",
            "spacing": 8,
            "alignment": "center",
            "padding": { "horizontal": 20 },
            "template": {
                "type": "button",
                "text": "${interest}",
                "styleId": "pillButton",
                "actions": {
                    "onTap": { "type": "toggleState", "path": "selected.${interest}" }
                }
            },
            "emptyView": {
                "type": "label",
                "text": "Select your interests"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.items == "interests")
            #expect(forEach.itemVariable == "interest")
            #expect(forEach.indexVariable == "idx")
            #expect(forEach.layout == .hstack)
            #expect(forEach.spacing == 8)
            #expect(forEach.alignment == .center)
            #expect(forEach.padding?.horizontal == 20)
            
            if case .component(let template) = forEach.template {
                #expect(template.type.rawValue == "button")
                #expect(template.text == "${interest}")
            }
            
            if case .component(let emptyView) = forEach.emptyView {
                #expect(emptyView.text == "Select your interests")
            }
        } else {
            Issue.record("Expected forEach")
        }
    }
}

// MARK: - Round Trip Tests

struct ForEachRoundTripTests {
    
    @Test func roundTripsForEach() throws {
        let original = Document.ForEach(
            items: "testItems",
            itemVariable: "item",
            indexVariable: "index",
            layout: .hstack,
            spacing: 12,
            alignment: .center,
            padding: Document.Padding(horizontal: 16),
            template: .component(Document.Component(
                type: Document.ComponentKind(rawValue: "label"),
                text: "Test"
            )),
            emptyView: nil
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.ForEach.self, from: data)
        
        #expect(decoded.items == "testItems")
        #expect(decoded.itemVariable == "item")
        #expect(decoded.indexVariable == "index")
        #expect(decoded.layout == .hstack)
        #expect(decoded.spacing == 12)
        #expect(decoded.alignment == .center)
        #expect(decoded.padding?.horizontal == 16)
    }
}
