//
//  DataSourceTests.swift
//  CLADSTests
//
//  Unit tests for Document.DataSource JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Static DataSource Tests

struct DataSourceStaticTests {
    
    @Test func decodesStaticDataSource() throws {
        let json = """
        {
            "type": "static",
            "value": "Hello World"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .static)
        #expect(dataSource.value == "Hello World")
    }
    
    @Test func decodesStaticWithEmptyValue() throws {
        let json = """
        {
            "type": "static",
            "value": ""
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .static)
        #expect(dataSource.value == "")
    }
    
    @Test func decodesStaticWithoutValue() throws {
        let json = """
        {
            "type": "static"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .static)
        #expect(dataSource.value == nil)
    }
}

// MARK: - Binding DataSource Tests

struct DataSourceBindingTests {
    
    @Test func decodesBindingWithPath() throws {
        let json = """
        {
            "type": "binding",
            "path": "user.name"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .binding)
        #expect(dataSource.path == "user.name")
    }
    
    @Test func decodesBindingWithSimplePath() throws {
        let json = """
        {
            "type": "binding",
            "path": "counter"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .binding)
        #expect(dataSource.path == "counter")
    }
    
    @Test func decodesBindingWithDeepPath() throws {
        let json = """
        {
            "type": "binding",
            "path": "app.settings.notifications.enabled"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.path == "app.settings.notifications.enabled")
    }
    
    @Test func decodesBindingWithTemplate() throws {
        let json = """
        {
            "type": "binding",
            "template": "Hello ${name}!"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .binding)
        #expect(dataSource.template == "Hello ${name}!")
    }
    
    @Test func decodesBindingWithPathAndTemplate() throws {
        let json = """
        {
            "type": "binding",
            "path": "user.name",
            "template": "Welcome, ${user.name}!"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .binding)
        #expect(dataSource.path == "user.name")
        #expect(dataSource.template == "Welcome, ${user.name}!")
    }
    
    @Test func decodesBindingWithComplexTemplate() throws {
        let json = """
        {
            "type": "binding",
            "template": "Count: ${count} of ${total} (${percentage}%)"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.template == "Count: ${count} of ${total} (${percentage}%)")
    }
}

// MARK: - DataSource Kind Tests

struct DataSourceKindTests {
    
    @Test func kindRawValues() {
        #expect(Document.DataSource.Kind.static.rawValue == "static")
        #expect(Document.DataSource.Kind.binding.rawValue == "binding")
    }
    
    @Test func decodesStaticKind() throws {
        let json = "\"static\""
        let data = json.data(using: .utf8)!
        let kind = try JSONDecoder().decode(Document.DataSource.Kind.self, from: data)
        #expect(kind == .static)
    }
    
    @Test func decodesBindingKind() throws {
        let json = "\"binding\""
        let data = json.data(using: .utf8)!
        let kind = try JSONDecoder().decode(Document.DataSource.Kind.self, from: data)
        #expect(kind == .binding)
    }
}

// MARK: - DataSources Dictionary Tests

struct DataSourcesDictionaryTests {
    
    @Test func decodesDataSourcesDictionary() throws {
        let json = """
        {
            "titleText": {
                "type": "static",
                "value": "Welcome"
            },
            "userName": {
                "type": "binding",
                "path": "user.name"
            },
            "greeting": {
                "type": "binding",
                "template": "Hello, ${user.name}!"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let dataSources = try JSONDecoder().decode([String: Document.DataSource].self, from: data)
        
        #expect(dataSources.count == 3)
        
        #expect(dataSources["titleText"]?.type == .static)
        #expect(dataSources["titleText"]?.value == "Welcome")
        
        #expect(dataSources["userName"]?.type == .binding)
        #expect(dataSources["userName"]?.path == "user.name")
        
        #expect(dataSources["greeting"]?.type == .binding)
        #expect(dataSources["greeting"]?.template == "Hello, ${user.name}!")
    }
    
    @Test func decodesEmptyDataSourcesDictionary() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let dataSources = try JSONDecoder().decode([String: Document.DataSource].self, from: data)
        
        #expect(dataSources.isEmpty)
    }
    
    @Test func decodesMixedDataSources() throws {
        let json = """
        {
            "static1": { "type": "static", "value": "A" },
            "static2": { "type": "static", "value": "B" },
            "binding1": { "type": "binding", "path": "x" },
            "binding2": { "type": "binding", "template": "${y}" }
        }
        """
        let data = json.data(using: .utf8)!
        let dataSources = try JSONDecoder().decode([String: Document.DataSource].self, from: data)
        
        #expect(dataSources.count == 4)
        #expect(dataSources["static1"]?.type == .static)
        #expect(dataSources["static2"]?.type == .static)
        #expect(dataSources["binding1"]?.type == .binding)
        #expect(dataSources["binding2"]?.type == .binding)
    }
}

// MARK: - DataSource in Document Tests

struct DataSourceInDocumentTests {
    
    @Test func decodesDocumentWithDataSources() throws {
        let json = """
        {
            "id": "test-doc",
            "dataSources": {
                "welcomeMessage": {
                    "type": "static",
                    "value": "Welcome to our app!"
                },
                "userCount": {
                    "type": "binding",
                    "template": "${users.count} users online"
                }
            },
            "root": { "children": [] }
        }
        """
        
        let definition = try Document.Definition(jsonString: json)
        
        #expect(definition.dataSources?.count == 2)
        #expect(definition.dataSources?["welcomeMessage"]?.type == .static)
        #expect(definition.dataSources?["welcomeMessage"]?.value == "Welcome to our app!")
        #expect(definition.dataSources?["userCount"]?.type == .binding)
        #expect(definition.dataSources?["userCount"]?.template == "${users.count} users online")
    }
}

// MARK: - Round Trip Tests

struct DataSourceRoundTripTests {
    
    @Test func roundTripsStaticDataSource() throws {
        let original = Document.DataSource(
            type: .static,
            value: "Test Value"
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(decoded.type == .static)
        #expect(decoded.value == "Test Value")
    }
    
    @Test func roundTripsBindingDataSource() throws {
        let original = Document.DataSource(
            type: .binding,
            path: "user.name",
            template: "Hello ${user.name}!"
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(decoded.type == .binding)
        #expect(decoded.path == "user.name")
        #expect(decoded.template == "Hello ${user.name}!")
    }
    
    @Test func roundTripsMinimalBinding() throws {
        let original = Document.DataSource(
            type: .binding,
            path: "counter"
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(decoded.type == .binding)
        #expect(decoded.path == "counter")
        #expect(decoded.value == nil)
        #expect(decoded.template == nil)
    }
}

// MARK: - Edge Cases Tests

struct DataSourceEdgeCasesTests {
    
    @Test func decodesDataSourceWithAllFields() throws {
        let json = """
        {
            "type": "binding",
            "value": "fallback",
            "path": "data.value",
            "template": "${data.value}"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.type == .binding)
        #expect(dataSource.value == "fallback")
        #expect(dataSource.path == "data.value")
        #expect(dataSource.template == "${data.value}")
    }
    
    @Test func decodesDataSourceWithSpecialCharactersInTemplate() throws {
        let json = """
        {
            "type": "binding",
            "template": "Price: $${price} (${discount}% off)"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.template == "Price: $${price} (${discount}% off)")
    }
    
    @Test func decodesDataSourceWithUnicodeInValue() throws {
        let json = """
        {
            "type": "static",
            "value": "Welcome 👋 مرحبا 你好"
        }
        """
        let data = json.data(using: .utf8)!
        let dataSource = try JSONDecoder().decode(Document.DataSource.self, from: data)
        
        #expect(dataSource.value == "Welcome 👋 مرحبا 你好")
    }
}
