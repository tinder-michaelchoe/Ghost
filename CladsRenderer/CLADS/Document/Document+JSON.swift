//
//  Document+JSON.swift
//  CladsRendererFramework
//
//  Provides JSON parsing initializers for Document.
//

import Foundation

// MARK: - Parse Error

public enum DocumentParseError: Error, LocalizedError {
    case invalidEncoding
    case decodingError(DecodingError)

    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Invalid string encoding"
        case .decodingError(let error):
            return "JSON decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - JSON Initializers

extension Document.Definition {
    /// Initialize a Document.Definition from a JSON string
    /// - Parameter jsonString: The JSON string to parse
    /// - Throws: `DocumentParseError` if parsing fails
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw DocumentParseError.invalidEncoding
        }
        try self.init(jsonData: data)
    }

    /// Initialize a Document.Definition from JSON data
    /// - Parameter jsonData: The JSON data to parse
    /// - Throws: `DocumentParseError` if parsing fails
    public init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        do {
            self = try decoder.decode(Document.Definition.self, from: jsonData)
        } catch let error as DecodingError {
            throw DocumentParseError.decodingError(error)
        }
    }
}
