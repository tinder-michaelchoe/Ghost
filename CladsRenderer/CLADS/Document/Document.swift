//
//  Document.swift
//  CladsRendererFramework
//
//  Namespace for all decoded JSON schema types.
//

import Foundation

// MARK: - Document Namespace

/// Namespace for all decoded JSON schema types.
///
/// Types in this namespace represent the parsed JSON document structure
/// before resolution to IR (Intermediate Representation).
///
/// Usage:
/// ```swift
/// let definition = try JSONDecoder().decode(Document.Definition.self, from: jsonData)
/// let style: Document.Style = definition.styles["myStyle"]
/// ```
public enum Document {}

// MARK: - Document Definition

extension Document {
    /// Root document that contains all elements of a UI definition.
    ///
    /// This is the main type decoded from JSON.
    public struct Definition: Codable {
        public let id: String
        public let version: String?
        public let state: [String: StateValue]?
        public let styles: [String: Style]?
        public let dataSources: [String: DataSource]?
        public let actions: [String: Action]?
        public let root: RootComponent

        public init(
            id: String,
            version: String? = nil,
            state: [String: StateValue]? = nil,
            styles: [String: Style]? = nil,
            dataSources: [String: DataSource]? = nil,
            actions: [String: Action]? = nil,
            root: RootComponent
        ) {
            self.id = id
            self.version = version
            self.state = state
            self.styles = styles
            self.dataSources = dataSources
            self.actions = actions
            self.root = root
        }
    }
}

// MARK: - StateValue

extension Document {
    /// Represents a state value which can be a primitive, array, or object.
    ///
    /// Supported types:
    /// - Primitives: Int, Double, String, Bool, null
    /// - Collections: Array of StateValues, Object (dictionary) of StateValues
    ///
    /// Example JSON:
    /// ```json
    /// {
    ///   "count": 0,
    ///   "name": "John",
    ///   "interests": ["Music", "Sports", "Travel"],
    ///   "user": { "name": "Jane", "age": 25 }
    /// }
    /// ```
    public enum StateValue: Codable, Equatable {
        case intValue(Int)
        case doubleValue(Double)
        case stringValue(String)
        case boolValue(Bool)
        case nullValue
        case arrayValue([StateValue])
        case objectValue([String: StateValue])

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            // Try array first (before primitives)
            if let arrayVal = try? container.decode([StateValue].self) {
                self = .arrayValue(arrayVal)
                return
            }

            // Try object/dictionary
            if let objectVal = try? container.decode([String: StateValue].self) {
                self = .objectValue(objectVal)
                return
            }

            // Try primitives
            if let boolVal = try? container.decode(Bool.self) {
                // Check bool before int because JSON numbers can be decoded as bool
                self = .boolValue(boolVal)
            } else if let intVal = try? container.decode(Int.self) {
                self = .intValue(intVal)
            } else if let doubleVal = try? container.decode(Double.self) {
                self = .doubleValue(doubleVal)
            } else if let stringVal = try? container.decode(String.self) {
                self = .stringValue(stringVal)
            } else if container.decodeNil() {
                self = .nullValue
            } else {
                throw DecodingError.typeMismatch(
                    StateValue.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported state value type")
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .intValue(let val): try container.encode(val)
            case .doubleValue(let val): try container.encode(val)
            case .stringValue(let val): try container.encode(val)
            case .boolValue(let val): try container.encode(val)
            case .nullValue: try container.encodeNil()
            case .arrayValue(let val): try container.encode(val)
            case .objectValue(let val): try container.encode(val)
            }
        }

        // MARK: - Primitive Accessors

        public var intValue: Int? {
            if case .intValue(let val) = self { return val }
            return nil
        }

        public var doubleValue: Double? {
            if case .doubleValue(let val) = self { return val }
            return nil
        }

        public var stringValue: String? {
            if case .stringValue(let val) = self { return val }
            return nil
        }

        public var boolValue: Bool? {
            if case .boolValue(let val) = self { return val }
            return nil
        }

        // MARK: - Collection Accessors

        public var arrayValue: [StateValue]? {
            if case .arrayValue(let val) = self { return val }
            return nil
        }

        public var objectValue: [String: StateValue]? {
            if case .objectValue(let val) = self { return val }
            return nil
        }

        /// Returns true if this is a null value
        public var isNull: Bool {
            if case .nullValue = self { return true }
            return false
        }

        /// Returns the count for arrays, or nil for non-arrays
        public var count: Int? {
            arrayValue?.count
        }

        /// Returns true if this is an empty array
        public var isEmpty: Bool? {
            arrayValue?.isEmpty
        }
    }
}
