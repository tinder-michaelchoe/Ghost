//
//  Document.swift
//  CladsRendererFramework
//

import Foundation

/// Root document that contains all elements of a UI definition
public struct Document {
    public let id: String
    public let version: String?
    public let state: [String: StateValue]?
    public let styles: [String: Style]?
    public let dataSources: [String: DataSource]?
    public let actions: [String: [String: Any]]?
    public let root: RootComponent

    public init(
        id: String,
        version: String? = nil,
        state: [String: StateValue]? = nil,
        styles: [String: Style]? = nil,
        dataSources: [String: DataSource]? = nil,
        actions: [String: [String: Any]]? = nil,
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

// MARK: - Codable

extension Document: Codable {
    enum CodingKeys: String, CodingKey {
        case id, version, state, styles, dataSources, actions, root
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        state = try container.decodeIfPresent([String: StateValue].self, forKey: .state)
        styles = try container.decodeIfPresent([String: Style].self, forKey: .styles)
        dataSources = try container.decodeIfPresent([String: DataSource].self, forKey: .dataSources)
        root = try container.decode(RootComponent.self, forKey: .root)

        // Decode actions as raw JSON dictionaries
        if let actionsContainer = try? container.decodeIfPresent([String: JSONValue].self, forKey: .actions) {
            var actionDicts: [String: [String: Any]] = [:]
            for (key, value) in actionsContainer {
                if case .object(let dict) = value {
                    actionDicts[key] = dict.mapValues { $0.toAny() }
                }
            }
            actions = actionDicts.isEmpty ? nil : actionDicts
        } else {
            actions = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(styles, forKey: .styles)
        try container.encodeIfPresent(dataSources, forKey: .dataSources)
        try container.encode(root, forKey: .root)

        // Encode actions
        if let actions = actions {
            let jsonActions = actions.mapValues { dict in
                JSONValue.object(dict.mapValues { JSONValue.from($0) })
            }
            try container.encode(jsonActions, forKey: .actions)
        }
    }
}

// MARK: - JSON Value Helper

/// Helper enum for decoding arbitrary JSON values
enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    func toAny() -> Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .object(let value): return value.mapValues { $0.toAny() }
        case .array(let value): return value.map { $0.toAny() }
        case .null: return NSNull()
        }
    }

    static func from(_ value: Any) -> JSONValue {
        switch value {
        case let v as String: return .string(v)
        case let v as Int: return .int(v)
        case let v as Double: return .double(v)
        case let v as Bool: return .bool(v)
        case let v as [String: Any]: return .object(v.mapValues { from($0) })
        case let v as [Any]: return .array(v.map { from($0) })
        default: return .null
        }
    }
}

// MARK: - StateValue

/// Represents a state value which can be static or computed
public enum StateValue: Codable {
    case intValue(Int)
    case doubleValue(Double)
    case stringValue(String)
    case boolValue(Bool)
    case nullValue

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            self = .intValue(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .doubleValue(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .stringValue(stringVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .boolValue(boolVal)
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
        }
    }

    public var intValue: Int? {
        if case .intValue(let val) = self { return val }
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
}
