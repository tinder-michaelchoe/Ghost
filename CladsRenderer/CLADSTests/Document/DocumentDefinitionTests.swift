//
//  DocumentDefinitionTests.swift
//  CLADSTests
//
//  Unit tests for Document.Definition JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Minimal Document Tests

struct DocumentDefinitionMinimalTests {
    
    @Test func parsesMinimalDocument() throws {
        let json = """
        {
            "id": "test-doc",
            "root": {
                "children": []
            }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "test-doc")
        #expect(definition.version == nil)
        #expect(definition.state == nil)
        #expect(definition.styles == nil)
        #expect(definition.dataSources == nil)
        #expect(definition.actions == nil)
        #expect(definition.root.children.isEmpty)
    }
    
    @Test func parsesDocumentWithVersion() throws {
        let json = """
        {
            "id": "test-doc",
            "version": "1.0.0",
            "root": {
                "children": []
            }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "test-doc")
        #expect(definition.version == "1.0.0")
    }
}

// MARK: - Full Document Tests

struct DocumentDefinitionFullTests {
    
    @Test func parsesFullDocument() throws {
        let json = """
        {
            "id": "full-doc",
            "version": "2.0",
            "state": {
                "counter": 0,
                "name": "Test"
            },
            "styles": {
                "titleStyle": {
                    "fontSize": 24,
                    "fontWeight": "bold"
                }
            },
            "dataSources": {
                "greeting": {
                    "type": "static",
                    "value": "Hello"
                }
            },
            "actions": {
                "dismiss": {
                    "type": "dismiss"
                }
            },
            "root": {
                "backgroundColor": "#FFFFFF",
                "children": [
                    {
                        "type": "label",
                        "text": "Hello World"
                    }
                ]
            }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "full-doc")
        #expect(definition.version == "2.0")
        #expect(definition.state?.count == 2)
        #expect(definition.styles?.count == 1)
        #expect(definition.dataSources?.count == 1)
        #expect(definition.actions?.count == 1)
        #expect(definition.root.backgroundColor == "#FFFFFF")
        #expect(definition.root.children.count == 1)
    }
    
    @Test func parsesDocumentWithMultipleStyles() throws {
        let json = """
        {
            "id": "multi-style-doc",
            "styles": {
                "style1": { "fontSize": 12 },
                "style2": { "fontSize": 14 },
                "style3": { "fontSize": 16 }
            },
            "root": { "children": [] }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.styles?.count == 3)
        #expect(definition.styles?["style1"]?.fontSize == 12)
        #expect(definition.styles?["style2"]?.fontSize == 14)
        #expect(definition.styles?["style3"]?.fontSize == 16)
    }
    
    @Test func parsesDocumentWithMultipleActions() throws {
        let json = """
        {
            "id": "multi-action-doc",
            "actions": {
                "dismiss": { "type": "dismiss" },
                "navigate": { "type": "navigate", "destination": "home" },
                "toggle": { "type": "toggleState", "path": "isActive" }
            },
            "root": { "children": [] }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.actions?.count == 3)
    }
}

// MARK: - JSON Initializer Tests

struct DocumentDefinitionInitializerTests {
    
    @Test func initializesFromJsonString() throws {
        let json = """
        {"id": "string-init", "root": {"children": []}}
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "string-init")
    }
    
    @Test func initializesFromJsonData() throws {
        let json = """
        {"id": "data-init", "root": {"children": []}}
        """
        let data = json.data(using: .utf8)!
        
        let definition = try Document.Definition(jsonData: data)
        #expect(definition.id == "data-init")
    }
    
    @Test func initializesFromCompactJson() throws {
        let json = "{\"id\":\"compact\",\"root\":{\"children\":[]}}"
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "compact")
    }
    
    @Test func initializesFromPrettyPrintedJson() throws {
        let json = """
        {
            "id": "pretty",
            "root": {
                "children": [
                ]
            }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        #expect(definition.id == "pretty")
    }
}

// MARK: - Error Cases Tests

struct DocumentDefinitionErrorTests {
    
    @Test func throwsForMissingId() throws {
        let json = """
        {
            "root": { "children": [] }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForMissingRoot() throws {
        let json = """
        {
            "id": "no-root"
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForMalformedJson() throws {
        let json = "{ not valid json }"
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForEmptyString() throws {
        let json = ""
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForNullRoot() throws {
        let json = """
        {
            "id": "null-root",
            "root": null
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForInvalidIdType() throws {
        let json = """
        {
            "id": 123,
            "root": { "children": [] }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
}

// MARK: - Round Trip Tests

struct DocumentDefinitionRoundTripTests {
    
    @Test func roundTripsMinimalDocument() throws {
        let original = Document.Definition(
            id: "round-trip",
            root: Document.RootComponent(children: [])
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoded = try Document.Definition(jsonData: data)
        #expect(decoded.id == original.id)
    }
    
    @Test func roundTripsDocumentWithState() throws {
        let original = Document.Definition(
            id: "state-round-trip",
            state: [
                "count": .intValue(42),
                "name": .stringValue("Test")
            ],
            root: Document.RootComponent(children: [])
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoded = try Document.Definition(jsonData: data)
        #expect(decoded.state?["count"]?.intValue == 42)
        #expect(decoded.state?["name"]?.stringValue == "Test")
    }
}
