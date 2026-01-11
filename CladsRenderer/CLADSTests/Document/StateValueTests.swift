//
//  StateValueTests.swift
//  CLADSTests
//
//  Unit tests for Document.StateValue JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Primitive Type Tests

struct StateValuePrimitiveTests {
    
    @Test func decodesIntValue() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .intValue(42))
    }
    
    @Test func decodesNegativeInt() throws {
        let json = "-100"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .intValue(-100))
    }
    
    @Test func decodesZero() throws {
        let json = "0"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .intValue(0))
    }
    
    @Test func decodesDoubleValue() throws {
        let json = "3.14"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .doubleValue(3.14))
    }
    
    @Test func decodesNegativeDouble() throws {
        let json = "-2.5"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .doubleValue(-2.5))
    }
    
    @Test func decodesStringValue() throws {
        let json = "\"hello world\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .stringValue("hello world"))
    }
    
    @Test func decodesEmptyString() throws {
        let json = "\"\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .stringValue(""))
    }
    
    @Test func decodesStringWithSpecialChars() throws {
        let json = "\"hello\\nworld\\t!\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .stringValue("hello\nworld\t!"))
    }
    
    @Test func decodesBoolTrue() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .boolValue(true))
    }
    
    @Test func decodesBoolFalse() throws {
        let json = "false"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .boolValue(false))
    }
    
    @Test func decodesNullValue() throws {
        let json = "null"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .nullValue)
    }
}

// MARK: - Collection Type Tests

struct StateValueCollectionTests {
    
    @Test func decodesEmptyArray() throws {
        let json = "[]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .arrayValue([]))
    }
    
    @Test func decodesArrayOfInts() throws {
        let json = "[1, 2, 3]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .arrayValue([.intValue(1), .intValue(2), .intValue(3)]))
    }
    
    @Test func decodesArrayOfStrings() throws {
        let json = "[\"a\", \"b\", \"c\"]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .arrayValue([.stringValue("a"), .stringValue("b"), .stringValue("c")]))
    }
    
    @Test func decodesMixedArray() throws {
        let json = "[1, \"two\", true, null]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .arrayValue([
            .intValue(1),
            .stringValue("two"),
            .boolValue(true),
            .nullValue
        ]))
    }
    
    @Test func decodesNestedArray() throws {
        let json = "[[1, 2], [3, 4]]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .arrayValue([
            .arrayValue([.intValue(1), .intValue(2)]),
            .arrayValue([.intValue(3), .intValue(4)])
        ]))
    }
    
    @Test func decodesEmptyObject() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(value == .objectValue([:]))
    }
    
    @Test func decodesSimpleObject() throws {
        let json = "{\"name\": \"John\", \"age\": 30}"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        if case .objectValue(let dict) = value {
            #expect(dict["name"] == .stringValue("John"))
            #expect(dict["age"] == .intValue(30))
        } else {
            Issue.record("Expected object value")
        }
    }
    
    @Test func decodesNestedObject() throws {
        let json = """
        {
            "user": {
                "name": "Jane",
                "address": {
                    "city": "NYC"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        
        if case .objectValue(let dict) = value,
           case .objectValue(let user) = dict["user"],
           case .objectValue(let address) = user["address"] {
            #expect(user["name"] == .stringValue("Jane"))
            #expect(address["city"] == .stringValue("NYC"))
        } else {
            Issue.record("Expected nested object value")
        }
    }
    
    @Test func decodesObjectWithArray() throws {
        let json = "{\"tags\": [\"swift\", \"ios\"]}"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(Document.StateValue.self, from: data)
        
        if case .objectValue(let dict) = value {
            #expect(dict["tags"] == .arrayValue([.stringValue("swift"), .stringValue("ios")]))
        } else {
            Issue.record("Expected object value")
        }
    }
}

// MARK: - Accessor Tests

struct StateValueAccessorTests {
    
    @Test func intValueAccessor() throws {
        let value = Document.StateValue.intValue(42)
        #expect(value.intValue == 42)
        #expect(value.doubleValue == nil)
        #expect(value.stringValue == nil)
        #expect(value.boolValue == nil)
    }
    
    @Test func doubleValueAccessor() throws {
        let value = Document.StateValue.doubleValue(3.14)
        #expect(value.doubleValue == 3.14)
        #expect(value.intValue == nil)
        #expect(value.stringValue == nil)
    }
    
    @Test func stringValueAccessor() throws {
        let value = Document.StateValue.stringValue("test")
        #expect(value.stringValue == "test")
        #expect(value.intValue == nil)
    }
    
    @Test func boolValueAccessor() throws {
        let trueValue = Document.StateValue.boolValue(true)
        let falseValue = Document.StateValue.boolValue(false)
        #expect(trueValue.boolValue == true)
        #expect(falseValue.boolValue == false)
    }
    
    @Test func arrayValueAccessor() throws {
        let value = Document.StateValue.arrayValue([.intValue(1), .intValue(2)])
        #expect(value.arrayValue?.count == 2)
        #expect(value.objectValue == nil)
    }
    
    @Test func objectValueAccessor() throws {
        let value = Document.StateValue.objectValue(["key": .stringValue("value")])
        #expect(value.objectValue?["key"] == .stringValue("value"))
        #expect(value.arrayValue == nil)
    }
    
    @Test func isNullAccessor() throws {
        let nullValue = Document.StateValue.nullValue
        let intValue = Document.StateValue.intValue(0)
        #expect(nullValue.isNull == true)
        #expect(intValue.isNull == false)
    }
    
    @Test func countAccessor() throws {
        let emptyArray = Document.StateValue.arrayValue([])
        let threeItems = Document.StateValue.arrayValue([.intValue(1), .intValue(2), .intValue(3)])
        let notArray = Document.StateValue.intValue(5)
        
        #expect(emptyArray.count == 0)
        #expect(threeItems.count == 3)
        #expect(notArray.count == nil)
    }
    
    @Test func isEmptyAccessor() throws {
        let emptyArray = Document.StateValue.arrayValue([])
        let nonEmptyArray = Document.StateValue.arrayValue([.intValue(1)])
        let notArray = Document.StateValue.stringValue("test")
        
        #expect(emptyArray.isEmpty == true)
        #expect(nonEmptyArray.isEmpty == false)
        #expect(notArray.isEmpty == nil)
    }
}

// MARK: - Encoding Tests

struct StateValueEncodingTests {
    
    @Test func roundTripsIntValue() throws {
        let original = Document.StateValue.intValue(42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsDoubleValue() throws {
        let original = Document.StateValue.doubleValue(3.14)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsStringValue() throws {
        let original = Document.StateValue.stringValue("test string")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsBoolValue() throws {
        let original = Document.StateValue.boolValue(true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsNullValue() throws {
        let original = Document.StateValue.nullValue
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsArrayValue() throws {
        let original = Document.StateValue.arrayValue([
            .intValue(1),
            .stringValue("two"),
            .boolValue(true)
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsObjectValue() throws {
        let original = Document.StateValue.objectValue([
            "name": .stringValue("Test"),
            "count": .intValue(5)
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
    
    @Test func roundTripsComplexNestedValue() throws {
        let original = Document.StateValue.objectValue([
            "users": .arrayValue([
                .objectValue([
                    "name": .stringValue("Alice"),
                    "active": .boolValue(true)
                ]),
                .objectValue([
                    "name": .stringValue("Bob"),
                    "active": .boolValue(false)
                ])
            ]),
            "count": .intValue(2)
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.StateValue.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - State Dictionary Tests

struct StateValueDictionaryTests {
    
    @Test func decodesStateDictionary() throws {
        let json = """
        {
            "counter": 0,
            "name": "Test",
            "isActive": true,
            "items": ["a", "b", "c"]
        }
        """
        let data = json.data(using: .utf8)!
        let state = try JSONDecoder().decode([String: Document.StateValue].self, from: data)
        
        #expect(state["counter"] == .intValue(0))
        #expect(state["name"] == .stringValue("Test"))
        #expect(state["isActive"] == .boolValue(true))
        #expect(state["items"] == .arrayValue([
            .stringValue("a"),
            .stringValue("b"),
            .stringValue("c")
        ]))
    }
}
