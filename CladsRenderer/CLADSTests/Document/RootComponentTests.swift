//
//  RootComponentTests.swift
//  CLADSTests
//
//  Unit tests for Document.RootComponent JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Basic Properties Tests

struct RootComponentBasicTests {
    
    @Test func decodesMinimalRoot() throws {
        let json = """
        {
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.children.isEmpty)
        #expect(root.backgroundColor == nil)
        #expect(root.styleId == nil)
        #expect(root.colorScheme == nil)
    }
    
    @Test func decodesBackgroundColor() throws {
        let json = """
        {
            "backgroundColor": "#FFFFFF",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.backgroundColor == "#FFFFFF")
    }
    
    @Test func decodesStyleId() throws {
        let json = """
        {
            "styleId": "rootStyle",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.styleId == "rootStyle")
    }
    
    @Test func decodesColorSchemeLight() throws {
        let json = """
        {
            "colorScheme": "light",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.colorScheme == "light")
    }
    
    @Test func decodesColorSchemeDark() throws {
        let json = """
        {
            "colorScheme": "dark",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.colorScheme == "dark")
    }
    
    @Test func decodesColorSchemeSystem() throws {
        let json = """
        {
            "colorScheme": "system",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.colorScheme == "system")
    }
}

// MARK: - EdgeInsets Tests

struct RootComponentEdgeInsetsTests {
    
    @Test func decodesEdgeInsetsWithNumberShorthand() throws {
        let json = """
        {
            "edgeInsets": {
                "top": 16,
                "bottom": 20
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.edgeInsets?.top?.value == 16)
        #expect(root.edgeInsets?.top?.positioning == .safeArea)  // Default
        #expect(root.edgeInsets?.bottom?.value == 20)
        #expect(root.edgeInsets?.bottom?.positioning == .safeArea)
    }
    
    @Test func decodesEdgeInsetsWithExplicitPositioning() throws {
        let json = """
        {
            "edgeInsets": {
                "top": { "positioning": "safeArea", "value": 16 },
                "bottom": { "positioning": "absolute", "value": 0 }
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.edgeInsets?.top?.positioning == .safeArea)
        #expect(root.edgeInsets?.top?.value == 16)
        #expect(root.edgeInsets?.bottom?.positioning == .absolute)
        #expect(root.edgeInsets?.bottom?.value == 0)
    }
    
    @Test func decodesAllEdgeInsets() throws {
        let json = """
        {
            "edgeInsets": {
                "top": 10,
                "bottom": 20,
                "leading": 16,
                "trailing": 16
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.edgeInsets?.top?.value == 10)
        #expect(root.edgeInsets?.bottom?.value == 20)
        #expect(root.edgeInsets?.leading?.value == 16)
        #expect(root.edgeInsets?.trailing?.value == 16)
    }
    
    @Test func decodesMixedEdgeInsets() throws {
        let json = """
        {
            "edgeInsets": {
                "top": 16,
                "bottom": { "positioning": "absolute", "value": 0 }
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.edgeInsets?.top?.positioning == .safeArea)
        #expect(root.edgeInsets?.top?.value == 16)
        #expect(root.edgeInsets?.bottom?.positioning == .absolute)
        #expect(root.edgeInsets?.bottom?.value == 0)
    }
}

// MARK: - EdgeInset Tests

struct EdgeInsetTests {
    
    @Test func decodesNumberAsSafeArea() throws {
        let json = "20"
        let data = json.data(using: .utf8)!
        let inset = try JSONDecoder().decode(Document.EdgeInset.self, from: data)
        
        #expect(inset.value == 20)
        #expect(inset.positioning == .safeArea)
    }
    
    @Test func decodesSafeAreaPositioning() throws {
        let json = """
        { "positioning": "safeArea", "value": 16 }
        """
        let data = json.data(using: .utf8)!
        let inset = try JSONDecoder().decode(Document.EdgeInset.self, from: data)
        
        #expect(inset.positioning == .safeArea)
        #expect(inset.value == 16)
    }
    
    @Test func decodesAbsolutePositioning() throws {
        let json = """
        { "positioning": "absolute", "value": 0 }
        """
        let data = json.data(using: .utf8)!
        let inset = try JSONDecoder().decode(Document.EdgeInset.self, from: data)
        
        #expect(inset.positioning == .absolute)
        #expect(inset.value == 0)
    }
    
    @Test func decodesDefaultPositioning() throws {
        let json = """
        { "value": 24 }
        """
        let data = json.data(using: .utf8)!
        let inset = try JSONDecoder().decode(Document.EdgeInset.self, from: data)
        
        #expect(inset.positioning == .safeArea)  // Default
        #expect(inset.value == 24)
    }
    
    @Test func edgeInsetEquality() {
        let inset1 = Document.EdgeInset(positioning: .safeArea, value: 16)
        let inset2 = Document.EdgeInset(positioning: .safeArea, value: 16)
        let inset3 = Document.EdgeInset(positioning: .absolute, value: 16)
        let inset4 = Document.EdgeInset(positioning: .safeArea, value: 20)
        
        #expect(inset1 == inset2)
        #expect(inset1 != inset3)
        #expect(inset1 != inset4)
    }
}

// MARK: - Positioning Tests

struct PositioningTests {
    
    @Test func positioningRawValues() {
        #expect(Document.Positioning.safeArea.rawValue == "safeArea")
        #expect(Document.Positioning.absolute.rawValue == "absolute")
    }
}

// MARK: - RootActions Tests

struct RootActionsTests {
    
    @Test func decodesOnAppearReference() throws {
        let json = """
        {
            "actions": {
                "onAppear": "loadData"
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .reference(let ref) = root.actions?.onAppear {
            #expect(ref == "loadData")
        } else {
            Issue.record("Expected reference action binding")
        }
    }
    
    @Test func decodesOnAppearInline() throws {
        let json = """
        {
            "actions": {
                "onAppear": {
                    "type": "setState",
                    "path": "isLoaded",
                    "value": true
                }
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .inline(let action) = root.actions?.onAppear {
            if case .setState = action {
                // Success
            } else {
                Issue.record("Expected setState action")
            }
        } else {
            Issue.record("Expected inline action binding")
        }
    }
    
    @Test func decodesOnDisappearReference() throws {
        let json = """
        {
            "actions": {
                "onDisappear": "cleanup"
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .reference(let ref) = root.actions?.onDisappear {
            #expect(ref == "cleanup")
        } else {
            Issue.record("Expected reference action binding")
        }
    }
    
    @Test func decodesOnDisappearInline() throws {
        let json = """
        {
            "actions": {
                "onDisappear": { "type": "dismiss" }
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .inline(let action) = root.actions?.onDisappear {
            if case .dismiss = action {
                // Success
            } else {
                Issue.record("Expected dismiss action")
            }
        } else {
            Issue.record("Expected inline action binding")
        }
    }
    
    @Test func decodesBothRootActions() throws {
        let json = """
        {
            "actions": {
                "onAppear": "initialize",
                "onDisappear": "cleanup"
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .reference(let appearRef) = root.actions?.onAppear {
            #expect(appearRef == "initialize")
        }
        
        if case .reference(let disappearRef) = root.actions?.onDisappear {
            #expect(disappearRef == "cleanup")
        }
    }
    
    @Test func noActionsDefault() throws {
        let json = """
        { "children": [] }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.actions == nil)
    }
}

// MARK: - Children Tests

struct RootComponentChildrenTests {
    
    @Test func decodesEmptyChildren() throws {
        let json = """
        { "children": [] }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.children.isEmpty)
    }
    
    @Test func decodesSingleChild() throws {
        let json = """
        {
            "children": [
                { "type": "label", "text": "Hello" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.children.count == 1)
        if case .component(let label) = root.children[0] {
            #expect(label.text == "Hello")
        }
    }
    
    @Test func decodesMultipleChildren() throws {
        let json = """
        {
            "children": [
                { "type": "label", "text": "First" },
                { "type": "button", "text": "Second" },
                { "type": "spacer" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.children.count == 3)
    }
    
    @Test func decodesLayoutChild() throws {
        let json = """
        {
            "children": [
                {
                    "type": "vstack",
                    "spacing": 16,
                    "children": [
                        { "type": "label", "text": "Nested" }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .layout(let vstack) = root.children[0] {
            #expect(vstack.type == .vstack)
            #expect(vstack.spacing == 16)
        } else {
            Issue.record("Expected layout child")
        }
    }
    
    @Test func decodesSectionLayoutChild() throws {
        let json = """
        {
            "children": [
                {
                    "type": "sectionLayout",
                    "sections": [
                        {
                            "layout": { "type": "list" }
                        }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        if case .sectionLayout = root.children[0] {
            // Success
        } else {
            Issue.record("Expected sectionLayout child")
        }
    }
}

// MARK: - Full Root Tests

struct RootComponentFullTests {
    
    @Test func decodesFullRoot() throws {
        let json = """
        {
            "backgroundColor": "#F5F5F5",
            "styleId": "mainRoot",
            "colorScheme": "light",
            "edgeInsets": {
                "top": 16,
                "bottom": { "positioning": "absolute", "value": 0 }
            },
            "actions": {
                "onAppear": "initialize",
                "onDisappear": { "type": "dismiss" }
            },
            "children": [
                {
                    "type": "vstack",
                    "children": [
                        { "type": "label", "text": "Title" },
                        { "type": "spacer" },
                        { "type": "button", "text": "Action" }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let root = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(root.backgroundColor == "#F5F5F5")
        #expect(root.styleId == "mainRoot")
        #expect(root.colorScheme == "light")
        #expect(root.edgeInsets?.top?.value == 16)
        #expect(root.edgeInsets?.bottom?.positioning == .absolute)
        
        if case .reference(let ref) = root.actions?.onAppear {
            #expect(ref == "initialize")
        }
        
        if case .inline(let action) = root.actions?.onDisappear {
            if case .dismiss = action {
                // Success
            }
        }
        
        #expect(root.children.count == 1)
        if case .layout(let vstack) = root.children[0] {
            #expect(vstack.children.count == 3)
        }
    }
}

// MARK: - Round Trip Tests

struct RootComponentRoundTripTests {
    
    @Test func roundTripsRootComponent() throws {
        let original = Document.RootComponent(
            backgroundColor: "#FFFFFF",
            edgeInsets: Document.EdgeInsets(
                top: Document.EdgeInset(value: 16),
                bottom: Document.EdgeInset(positioning: .absolute, value: 0)
            ),
            styleId: "rootStyle",
            colorScheme: "dark",
            children: [.spacer]
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.RootComponent.self, from: data)
        
        #expect(decoded.backgroundColor == "#FFFFFF")
        #expect(decoded.styleId == "rootStyle")
        #expect(decoded.colorScheme == "dark")
        #expect(decoded.edgeInsets?.top?.value == 16)
        #expect(decoded.children.count == 1)
    }
    
    @Test func roundTripsEdgeInset() throws {
        // Safe area positioning encodes as just the number
        let safeArea = Document.EdgeInset(positioning: .safeArea, value: 20)
        let safeAreaData = try JSONEncoder().encode(safeArea)
        let decodedSafeArea = try JSONDecoder().decode(Document.EdgeInset.self, from: safeAreaData)
        #expect(decodedSafeArea.positioning == .safeArea)
        #expect(decodedSafeArea.value == 20)
        
        // Absolute positioning encodes as object
        let absolute = Document.EdgeInset(positioning: .absolute, value: 0)
        let absoluteData = try JSONEncoder().encode(absolute)
        let decodedAbsolute = try JSONDecoder().decode(Document.EdgeInset.self, from: absoluteData)
        #expect(decodedAbsolute.positioning == .absolute)
        #expect(decodedAbsolute.value == 0)
    }
    
    @Test func roundTripsRootActions() throws {
        let original = Document.RootActions(
            onAppear: .reference("loadData"),
            onDisappear: .inline(.dismiss)
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.RootActions.self, from: data)
        
        if case .reference(let ref) = decoded.onAppear {
            #expect(ref == "loadData")
        }
        
        if case .inline(let action) = decoded.onDisappear {
            if case .dismiss = action {
                // Success
            } else {
                Issue.record("Expected dismiss action")
            }
        }
    }
}
