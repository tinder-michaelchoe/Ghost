//
//  LayoutNodeTests.swift
//  CLADSTests
//
//  Unit tests for Document.LayoutNode JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Type Discrimination Tests

struct LayoutNodeTypeDiscriminationTests {
    
    @Test func decodesVStackAsLayout() throws {
        let json = """
        {
            "type": "vstack",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.type == .vstack)
        } else {
            Issue.record("Expected vstack to be decoded as layout")
        }
    }
    
    @Test func decodesHStackAsLayout() throws {
        let json = """
        {
            "type": "hstack",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.type == .hstack)
        } else {
            Issue.record("Expected hstack to be decoded as layout")
        }
    }
    
    @Test func decodesZStackAsLayout() throws {
        let json = """
        {
            "type": "zstack",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.type == .zstack)
        } else {
            Issue.record("Expected zstack to be decoded as layout")
        }
    }
    
    @Test func decodesSectionLayoutType() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout = node {
            // Success
        } else {
            Issue.record("Expected sectionLayout type")
        }
    }
    
    @Test func decodesForEachType() throws {
        let json = """
        {
            "type": "forEach",
            "items": "items",
            "template": {
                "type": "label",
                "text": "Item"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .forEach(let forEach) = node {
            #expect(forEach.items == "items")
        } else {
            Issue.record("Expected forEach type")
        }
    }
    
    @Test func decodesSpacerType() throws {
        let json = """
        { "type": "spacer" }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .spacer = node {
            // Success
        } else {
            Issue.record("Expected spacer type")
        }
    }
    
    @Test func decodesLabelAsComponent() throws {
        let json = """
        {
            "type": "label",
            "text": "Hello"
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .component(let component) = node {
            #expect(component.type.rawValue == "label")
            #expect(component.text == "Hello")
        } else {
            Issue.record("Expected label to be decoded as component")
        }
    }
    
    @Test func decodesButtonAsComponent() throws {
        let json = """
        {
            "type": "button",
            "text": "Click Me"
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .component(let component) = node {
            #expect(component.type.rawValue == "button")
        } else {
            Issue.record("Expected button to be decoded as component")
        }
    }
    
    @Test func decodesUnknownTypeAsComponent() throws {
        let json = """
        {
            "type": "customWidget",
            "customProp": "value"
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .component(let component) = node {
            #expect(component.type.rawValue == "customWidget")
        } else {
            Issue.record("Expected unknown type to be decoded as component")
        }
    }
}

// MARK: - Layout Tests

struct LayoutTests {
    
    @Test func decodesLayoutWithAlignment() throws {
        let json = """
        {
            "type": "vstack",
            "alignment": "center",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.horizontalAlignment == .center)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithLeadingAlignment() throws {
        let json = """
        {
            "type": "vstack",
            "alignment": "leading",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.horizontalAlignment == .leading)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithTrailingAlignment() throws {
        let json = """
        {
            "type": "vstack",
            "alignment": "trailing",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.horizontalAlignment == .trailing)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesZStackWith2DAlignment() throws {
        let json = """
        {
            "type": "zstack",
            "alignment": {
                "horizontal": "trailing",
                "vertical": "bottom"
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.alignment?.horizontal == .trailing)
            #expect(layout.alignment?.vertical == .bottom)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithSpacing() throws {
        let json = """
        {
            "type": "vstack",
            "spacing": 16,
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.spacing == 16)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithPadding() throws {
        let json = """
        {
            "type": "vstack",
            "padding": {
                "horizontal": 20,
                "vertical": 16
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.padding?.horizontal == 20)
            #expect(layout.padding?.vertical == 16)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithLocalState() throws {
        let json = """
        {
            "type": "vstack",
            "state": {
                "localCounter": 0,
                "localText": "initial"
            },
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.state?.initialValues["localCounter"] == .intValue(0))
            #expect(layout.state?.initialValues["localText"] == .stringValue("initial"))
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithEmptyChildren() throws {
        let json = """
        {
            "type": "hstack",
            "children": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.children.isEmpty)
        } else {
            Issue.record("Expected layout")
        }
    }
    
    @Test func decodesLayoutWithoutChildren() throws {
        let json = """
        {
            "type": "hstack"
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.children.isEmpty)
        } else {
            Issue.record("Expected layout")
        }
    }
}

// MARK: - Nested Layout Tests

struct NestedLayoutTests {
    
    @Test func decodesNestedLayouts() throws {
        let json = """
        {
            "type": "vstack",
            "spacing": 16,
            "children": [
                {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                        { "type": "label", "text": "Left" },
                        { "type": "spacer" },
                        { "type": "label", "text": "Right" }
                    ]
                },
                {
                    "type": "label",
                    "text": "Bottom"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let vstack) = node {
            #expect(vstack.type == .vstack)
            #expect(vstack.children.count == 2)
            
            if case .layout(let hstack) = vstack.children[0] {
                #expect(hstack.type == .hstack)
                #expect(hstack.children.count == 3)
                
                if case .spacer = hstack.children[1] {
                    // Success
                } else {
                    Issue.record("Expected spacer in hstack")
                }
            } else {
                Issue.record("Expected hstack as first child")
            }
            
            if case .component(let label) = vstack.children[1] {
                #expect(label.text == "Bottom")
            } else {
                Issue.record("Expected label as second child")
            }
        } else {
            Issue.record("Expected vstack")
        }
    }
    
    @Test func decodesDeepNestedLayouts() throws {
        let json = """
        {
            "type": "vstack",
            "children": [
                {
                    "type": "hstack",
                    "children": [
                        {
                            "type": "zstack",
                            "children": [
                                { "type": "label", "text": "Deep" }
                            ]
                        }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let vstack) = node {
            if case .layout(let hstack) = vstack.children[0] {
                if case .layout(let zstack) = hstack.children[0] {
                    #expect(zstack.type == .zstack)
                    if case .component(let label) = zstack.children[0] {
                        #expect(label.text == "Deep")
                    }
                }
            }
        }
    }
    
    @Test func decodesLayoutWithMixedChildren() throws {
        let json = """
        {
            "type": "vstack",
            "children": [
                { "type": "label", "text": "Label" },
                { "type": "button", "text": "Button" },
                { "type": "spacer" },
                { "type": "hstack", "children": [] },
                { "type": "image", "image": { "system": "star" } }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = node {
            #expect(layout.children.count == 5)
            
            if case .component(let label) = layout.children[0] {
                #expect(label.type.rawValue == "label")
            }
            
            if case .component(let button) = layout.children[1] {
                #expect(button.type.rawValue == "button")
            }
            
            if case .spacer = layout.children[2] {
                // Success
            }
            
            if case .layout(let hstack) = layout.children[3] {
                #expect(hstack.type == .hstack)
            }
            
            if case .component(let image) = layout.children[4] {
                #expect(image.type.rawValue == "image")
            }
        }
    }
}

// MARK: - Alignment Type Tests

struct AlignmentTypeTests {
    
    @Test func decodesHorizontalAlignment() throws {
        let leading = Document.HorizontalAlignment.leading
        let center = Document.HorizontalAlignment.center
        let trailing = Document.HorizontalAlignment.trailing
        
        #expect(leading.rawValue == "leading")
        #expect(center.rawValue == "center")
        #expect(trailing.rawValue == "trailing")
    }
    
    @Test func decodesVerticalAlignment() throws {
        let top = Document.VerticalAlignment.top
        let center = Document.VerticalAlignment.center
        let bottom = Document.VerticalAlignment.bottom
        
        #expect(top.rawValue == "top")
        #expect(center.rawValue == "center")
        #expect(bottom.rawValue == "bottom")
    }
    
    @Test func decodes2DAlignment() throws {
        let json = """
        {
            "horizontal": "center",
            "vertical": "top"
        }
        """
        let data = json.data(using: .utf8)!
        let alignment = try JSONDecoder().decode(Document.Alignment.self, from: data)
        
        #expect(alignment.horizontal == .center)
        #expect(alignment.vertical == .top)
    }
    
    @Test func decodesPartial2DAlignment() throws {
        let json = """
        { "horizontal": "leading" }
        """
        let data = json.data(using: .utf8)!
        let alignment = try JSONDecoder().decode(Document.Alignment.self, from: data)
        
        #expect(alignment.horizontal == .leading)
        #expect(alignment.vertical == nil)
    }
}

// MARK: - Round Trip Tests

struct LayoutNodeRoundTripTests {
    
    @Test func roundTripsLayout() throws {
        let original = Document.LayoutNode.layout(
            Document.Layout(
                type: .vstack,
                alignment: nil,
                horizontalAlignment: .center,
                spacing: 16,
                padding: Document.Padding(horizontal: 20),
                children: [.spacer]
            )
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .layout(let layout) = decoded {
            #expect(layout.type == .vstack)
            #expect(layout.horizontalAlignment == .center)
            #expect(layout.spacing == 16)
        } else {
            Issue.record("Expected layout after round trip")
        }
    }
    
    @Test func roundTripsSpacer() throws {
        let original = Document.LayoutNode.spacer
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .spacer = decoded {
            // Success
        } else {
            Issue.record("Expected spacer after round trip")
        }
    }
}
