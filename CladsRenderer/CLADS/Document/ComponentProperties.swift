//
//  ComponentProperties.swift
//  CLADS
//
//  Protocol for type-safe component properties decoding.
//  Enables external modules to define custom component properties.
//

import Foundation

// MARK: - Component Properties Protocol

/// Protocol for defining typed properties for a component kind.
///
/// Each component type can have its own properties struct that conforms to this protocol.
/// This enables type-safe access to component-specific properties during resolution.
///
/// Example for a custom chart component:
/// ```swift
/// struct ChartProperties: ComponentProperties {
///     static let kind: Document.ComponentKind = .chart
///
///     let dataPoints: [Double]
///     let chartType: String
///     let showLabels: Bool
/// }
/// ```
public protocol ComponentProperties: Codable, Sendable {
    /// The component kind this properties type is for
    static var kind: Document.ComponentKind { get }
}

// MARK: - Component Properties Registry

/// Registry for component properties decoders.
///
/// Allows custom components to register their properties types for decoding.
public final class ComponentPropertiesRegistry: @unchecked Sendable {

    // MARK: - Storage

    private var decoders: [Document.ComponentKind: any ComponentPropertiesDecoding] = [:]
    private let queue = DispatchQueue(label: "com.clads.componentPropertiesRegistry", attributes: .concurrent)

    // MARK: - Initialization

    public init() {}

    // MARK: - Registration

    /// Registers a properties type for a component kind
    public func register<T: ComponentProperties>(_ type: T.Type) {
        let decoder = ComponentPropertiesDecoder<T>()
        queue.async(flags: .barrier) {
            self.decoders[T.kind] = decoder
        }
    }

    /// Decodes properties for a component kind from a decoder
    public func decode(kind: Document.ComponentKind, from decoder: Decoder) throws -> (any ComponentProperties)? {
        var result: (any ComponentPropertiesDecoding)?
        queue.sync {
            result = decoders[kind]
        }
        return try result?.decode(from: decoder)
    }

    /// Decodes properties for a component kind from additional properties dictionary
    public func decode(kind: Document.ComponentKind, from dictionary: [String: AnyCodableValue]) throws -> (any ComponentProperties)? {
        var result: (any ComponentPropertiesDecoding)?
        queue.sync {
            result = decoders[kind]
        }
        return try result?.decode(from: dictionary)
    }

    /// Checks if a properties decoder is registered for a kind
    public func hasDecoder(for kind: Document.ComponentKind) -> Bool {
        var result = false
        queue.sync {
            result = decoders[kind] != nil
        }
        return result
    }
}

// MARK: - Properties Decoding Protocol

/// Internal protocol for type-erased properties decoding
protocol ComponentPropertiesDecoding {
    func decode(from decoder: Decoder) throws -> any ComponentProperties
    func decode(from dictionary: [String: AnyCodableValue]) throws -> any ComponentProperties
}

/// Type-specific decoder for component properties
struct ComponentPropertiesDecoder<T: ComponentProperties>: ComponentPropertiesDecoding {
    func decode(from decoder: Decoder) throws -> any ComponentProperties {
        try T(from: decoder)
    }

    func decode(from dictionary: [String: AnyCodableValue]) throws -> any ComponentProperties {
        let data = try JSONEncoder().encode(dictionary)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - AnyCodableValue

/// Type-erased Codable value for storing arbitrary JSON values.
///
/// Used to capture additional/custom properties from component JSON.
public enum AnyCodableValue: Codable, Sendable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodableValue])
    case object([String: AnyCodableValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodableValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodableValue")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    // MARK: - Value Accessors

    public var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    public var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let v) = self { return v }
        if case .int(let v) = self { return Double(v) }
        return nil
    }

    public var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    public var arrayValue: [AnyCodableValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    public var objectValue: [String: AnyCodableValue]? {
        if case .object(let v) = self { return v }
        return nil
    }
}
