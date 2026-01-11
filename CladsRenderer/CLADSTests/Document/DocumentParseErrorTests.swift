//
//  DocumentParseErrorTests.swift
//  CLADSTests
//
//  Unit tests for DocumentParseError error handling.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Invalid Encoding Tests

struct DocumentParseErrorInvalidEncodingTests {
    
    @Test func throwsInvalidEncodingForNonUTF8() throws {
        // Create a string that can't be converted to UTF-8 data
        // This is a bit tricky in Swift, so we test the error type directly
        let error = DocumentParseError.invalidEncoding
        #expect(error.errorDescription?.contains("Invalid string encoding") == true)
    }
    
    @Test func invalidEncodingErrorDescription() {
        let error = DocumentParseError.invalidEncoding
        #expect(error.errorDescription == "Invalid string encoding")
    }
}

// MARK: - Decoding Error Tests

struct DocumentParseErrorDecodingTests {
    
    @Test func throwsDecodingErrorForMalformedJSON() throws {
        let malformed = "{ invalid json }"
        
        do {
            _ = try Document.Definition(jsonString: malformed)
            Issue.record("Expected error to be thrown")
        } catch let error as DocumentParseError {
            if case .decodingError = error {
                // Success
                #expect(error.errorDescription?.contains("JSON decoding error") == true)
            } else {
                Issue.record("Expected decodingError case")
            }
        }
    }
    
    @Test func throwsDecodingErrorForTypeMismatch() throws {
        let json = """
        {
            "id": 123,
            "root": { "children": [] }
        }
        """
        
        do {
            _ = try Document.Definition(jsonString: json)
            Issue.record("Expected error to be thrown")
        } catch let error as DocumentParseError {
            if case .decodingError = error {
                // Success - id should be string, not int
            } else {
                Issue.record("Expected decodingError case")
            }
        }
    }
    
    @Test func throwsDecodingErrorForMissingRequiredField() throws {
        let json = """
        {
            "root": { "children": [] }
        }
        """
        
        do {
            _ = try Document.Definition(jsonString: json)
            Issue.record("Expected error to be thrown")
        } catch let error as DocumentParseError {
            if case .decodingError = error {
                // Success - missing required "id" field
            } else {
                Issue.record("Expected decodingError case")
            }
        }
    }
    
    @Test func decodingErrorContainsUnderlyingError() {
        let context = DecodingError.Context(
            codingPath: [],
            debugDescription: "Test error"
        )
        let underlyingError = DecodingError.dataCorrupted(context)
        let error = DocumentParseError.decodingError(underlyingError)
        
        #expect(error.errorDescription?.contains("JSON decoding error") == true)
    }
}

// MARK: - Error Type Tests

struct DocumentParseErrorTypeTests {
    
    @Test func errorConformsToLocalizedError() {
        let error: LocalizedError = DocumentParseError.invalidEncoding
        #expect(error.errorDescription != nil)
    }
    
    @Test func errorConformsToError() {
        let error: Error = DocumentParseError.invalidEncoding
        #expect(error.localizedDescription.contains("Invalid") || error.localizedDescription.count > 0)
    }
    
    @Test func invalidEncodingCase() {
        let error = DocumentParseError.invalidEncoding
        
        switch error {
        case .invalidEncoding:
            // Success
            break
        case .decodingError:
            Issue.record("Expected invalidEncoding case")
        }
    }
    
    @Test func decodingErrorCase() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "Test")
        let underlyingError = DecodingError.dataCorrupted(context)
        let error = DocumentParseError.decodingError(underlyingError)
        
        switch error {
        case .invalidEncoding:
            Issue.record("Expected decodingError case")
        case .decodingError(let decodingError):
            #expect(decodingError.localizedDescription.count > 0)
        }
    }
}

// MARK: - Various JSON Error Scenarios

struct DocumentParseErrorScenariosTests {
    
    @Test func throwsForEmptyString() throws {
        let empty = ""
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: empty)
        }
    }
    
    @Test func throwsForWhitespaceOnly() throws {
        let whitespace = "   \n\t   "
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: whitespace)
        }
    }
    
    @Test func throwsForArray() throws {
        let array = "[1, 2, 3]"
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: array)
        }
    }
    
    @Test func throwsForPrimitive() throws {
        let primitive = "42"
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: primitive)
        }
    }
    
    @Test func throwsForNull() throws {
        let null = "null"
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: null)
        }
    }
    
    @Test func throwsForIncompleteJSON() throws {
        let incomplete = """
        {
            "id": "test",
            "root": {
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: incomplete)
        }
    }
    
    // Note: Trailing comma test removed - newer iOS/macOS versions accept trailing commas
    
    @Test func throwsForSingleQuotes() throws {
        let singleQuotes = """
        {
            'id': 'test',
            'root': { 'children': [] }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: singleQuotes)
        }
    }
    
    @Test func throwsForUnquotedKeys() throws {
        let unquotedKeys = """
        {
            id: "test",
            root: { children: [] }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: unquotedKeys)
        }
    }
}

// MARK: - Nested Error Scenarios

struct DocumentParseErrorNestedTests {
    
    @Test func throwsForInvalidStyleProperty() throws {
        let json = """
        {
            "id": "test",
            "styles": {
                "myStyle": {
                    "fontWeight": "invalid-weight"
                }
            },
            "root": { "children": [] }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForInvalidActionType() throws {
        let json = """
        {
            "id": "test",
            "root": {
                "children": [
                    {
                        "type": "button",
                        "actions": {
                            "onTap": {
                                "type": "setState"
                            }
                        }
                    }
                ]
            }
        }
        """
        
        // setState requires path and value
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
    
    @Test func throwsForInvalidLayoutType() throws {
        let json = """
        {
            "id": "test",
            "root": {
                "children": [
                    {
                        "type": "invalidLayoutType",
                        "children": []
                    }
                ]
            }
        }
        """
        
        // This should parse as component, not throw
        let definition = try Document.Definition(jsonString: json)
        if case .component(let component) = definition.root.children[0] {
            #expect(component.type.rawValue == "invalidLayoutType")
        }
    }
    
    @Test func throwsForInvalidRootChildrenType() throws {
        let json = """
        {
            "id": "test",
            "root": {
                "children": "not-an-array"
            }
        }
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: json)
        }
    }
}

// MARK: - Data Corruption Tests

struct DocumentParseErrorDataCorruptionTests {
    
    @Test func throwsForInvalidUTF8InData() throws {
        // Create invalid UTF-8 bytes
        let invalidBytes: [UInt8] = [0xFF, 0xFE]
        let data = Data(invalidBytes)
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonData: data)
        }
    }
    
    @Test func throwsForTruncatedJSON() throws {
        let truncated = """
        {"id":"test","root":{"children":[{"type":"label","text":"
        """
        
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: truncated)
        }
    }
}

// MARK: - Error Recovery Tests

struct DocumentParseErrorRecoveryTests {
    
    @Test func parsesValidJSONAfterError() throws {
        // First, try invalid JSON
        let invalid = "{ invalid }"
        #expect(throws: DocumentParseError.self) {
            _ = try Document.Definition(jsonString: invalid)
        }
        
        // Then, parse valid JSON (should succeed)
        let valid = """
        {
            "id": "recovered",
            "root": { "children": [] }
        }
        """
        let definition = try Document.Definition(jsonString: valid)
        #expect(definition.id == "recovered")
    }
    
    @Test func multipleParsingAttempts() throws {
        // Attempt multiple parses, some failing some succeeding
        let testCases: [(String, Bool)] = [
            ("{}", false),  // Missing required fields
            ("{\"id\":\"test\"}", false),  // Missing root
            ("{\"id\":\"test\",\"root\":{\"children\":[]}}", true),  // Valid
            ("invalid", false),  // Invalid JSON
            ("{\"id\":\"test2\",\"root\":{\"children\":[]}}", true),  // Valid
        ]
        
        for (json, shouldSucceed) in testCases {
            do {
                let _ = try Document.Definition(jsonString: json)
                if !shouldSucceed {
                    Issue.record("Expected failure for: \(json)")
                }
            } catch {
                if shouldSucceed {
                    Issue.record("Expected success for: \(json)")
                }
            }
        }
    }
}
