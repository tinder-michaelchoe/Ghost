//
//  CLADSValidator.swift
//  CLADS
//
//  JSON schema validation for CLADS documents.
//

import Foundation

// MARK: - Validation Error

/// Errors that can occur during CLADS document validation
public enum CLADSValidationError: Error, CustomStringConvertible {
    case missingRequiredField(field: String, path: String)
    case invalidType(expected: String, actual: String, path: String)
    case invalidEnumValue(value: String, allowed: [String], path: String)
    case invalidFormat(message: String, path: String)
    case unknownComponentType(type: String, path: String)
    case unknownActionType(type: String, path: String)
    case mutuallyExclusiveFields(fields: [String], path: String)
    case invalidRange(value: Double, min: Double?, max: Double?, path: String)
    case decodingFailed(underlying: Error)
    case multipleErrors([CLADSValidationError])
    
    public var description: String {
        switch self {
        case .missingRequiredField(let field, let path):
            return "Missing required field '\(field)' at \(path)"
        case .invalidType(let expected, let actual, let path):
            return "Invalid type at \(path): expected \(expected), got \(actual)"
        case .invalidEnumValue(let value, let allowed, let path):
            return "Invalid value '\(value)' at \(path). Allowed: \(allowed.joined(separator: ", "))"
        case .invalidFormat(let message, let path):
            return "Invalid format at \(path): \(message)"
        case .unknownComponentType(let type, let path):
            return "Unknown component type '\(type)' at \(path)"
        case .unknownActionType(let type, let path):
            return "Unknown action type '\(type)' at \(path)"
        case .mutuallyExclusiveFields(let fields, let path):
            return "Mutually exclusive fields \(fields) at \(path)"
        case .invalidRange(let value, let min, let max, let path):
            return "Value \(value) out of range [\(min.map { String($0) } ?? "-∞"), \(max.map { String($0) } ?? "∞")] at \(path)"
        case .decodingFailed(let underlying):
            return "JSON decoding failed: \(underlying.localizedDescription)"
        case .multipleErrors(let errors):
            return "Multiple validation errors:\n" + errors.map { "  - \($0.description)" }.joined(separator: "\n")
        }
    }
}

// MARK: - Validation Result

/// Result of validating a CLADS document
public struct CLADSValidationResult {
    /// Whether the document is valid
    public let isValid: Bool
    
    /// List of errors found (empty if valid)
    public let errors: [CLADSValidationError]
    
    /// List of warnings (non-fatal issues)
    public let warnings: [String]
    
    /// The parsed document (nil if parsing failed)
    public let document: Document.Definition?
    
    public init(isValid: Bool, errors: [CLADSValidationError] = [], warnings: [String] = [], document: Document.Definition? = nil) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.document = document
    }
}

// MARK: - CLADS Validator

/// Validates CLADS JSON documents against the schema
public struct CLADSValidator {
    
    // MARK: - Configuration
    
    /// Known built-in component types
    public var knownComponentTypes: Set<String> = [
        "label", "button", "textfield", "image", "gradient", "toggle", "slider", "divider"
    ]
    
    /// Known layout types
    public let layoutTypes: Set<String> = ["vstack", "hstack", "zstack"]
    
    /// Known section types
    public let sectionTypes: Set<String> = ["horizontal", "list", "grid", "flow"]
    
    /// Known action types
    public let actionTypes: Set<String> = ["dismiss", "setState", "toggleState", "showAlert", "navigate", "sequence"]
    
    /// Whether to allow unknown component types (for extensibility)
    public var allowUnknownComponents: Bool = true
    
    /// Whether to allow unknown action types (for extensibility)
    public var allowUnknownActions: Bool = true
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Validate a JSON string
    public func validate(jsonString: String) -> CLADSValidationResult {
        guard let data = jsonString.data(using: .utf8) else {
            return CLADSValidationResult(
                isValid: false,
                errors: [.invalidFormat(message: "Invalid UTF-8 string", path: "$")]
            )
        }
        return validate(jsonData: data)
    }
    
    /// Validate JSON data
    public func validate(jsonData: Data) -> CLADSValidationResult {
        var errors: [CLADSValidationError] = []
        var warnings: [String] = []
        
        // Try to decode as raw JSON first for structural validation
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        } catch {
            return CLADSValidationResult(
                isValid: false,
                errors: [.decodingFailed(underlying: error)]
            )
        }
        
        guard let root = jsonObject as? [String: Any] else {
            return CLADSValidationResult(
                isValid: false,
                errors: [.invalidType(expected: "object", actual: String(describing: type(of: jsonObject)), path: "$")]
            )
        }
        
        // Validate structure
        validateDocument(root, path: "$", errors: &errors, warnings: &warnings)
        
        // Try to decode as Document.Definition
        var document: Document.Definition?
        if errors.isEmpty {
            do {
                document = try JSONDecoder().decode(Document.Definition.self, from: jsonData)
            } catch {
                errors.append(.decodingFailed(underlying: error))
            }
        }
        
        return CLADSValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            document: document
        )
    }
    
    // MARK: - Document Validation
    
    private func validateDocument(_ doc: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        // Required: id
        if doc["id"] == nil {
            errors.append(.missingRequiredField(field: "id", path: path))
        } else if !(doc["id"] is String) {
            errors.append(.invalidType(expected: "string", actual: typeName(doc["id"]), path: "\(path).id"))
        }
        
        // Required: root
        guard let root = doc["root"] as? [String: Any] else {
            errors.append(.missingRequiredField(field: "root", path: path))
            return
        }
        
        validateRootComponent(root, path: "\(path).root", errors: &errors, warnings: &warnings)
        
        // Optional: styles
        if let styles = doc["styles"] as? [String: Any] {
            for (key, value) in styles {
                if let style = value as? [String: Any] {
                    validateStyle(style, path: "\(path).styles.\(key)", errors: &errors, warnings: &warnings)
                }
            }
        }
        
        // Optional: actions
        if let actions = doc["actions"] as? [String: Any] {
            for (key, value) in actions {
                if let action = value as? [String: Any] {
                    validateAction(action, path: "\(path).actions.\(key)", errors: &errors, warnings: &warnings)
                }
            }
        }
    }
    
    // MARK: - Root Component Validation
    
    private func validateRootComponent(_ root: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        // Required: children
        guard let children = root["children"] as? [[String: Any]] else {
            errors.append(.missingRequiredField(field: "children", path: path))
            return
        }
        
        for (index, child) in children.enumerated() {
            validateLayoutNode(child, path: "\(path).children[\(index)]", errors: &errors, warnings: &warnings)
        }
        
        // Optional: colorScheme
        if let colorScheme = root["colorScheme"] as? String {
            let allowed = ["light", "dark", "system"]
            if !allowed.contains(colorScheme) {
                errors.append(.invalidEnumValue(value: colorScheme, allowed: allowed, path: "\(path).colorScheme"))
            }
        }
    }
    
    // MARK: - Layout Node Validation
    
    private func validateLayoutNode(_ node: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let type = node["type"] as? String else {
            errors.append(.missingRequiredField(field: "type", path: path))
            return
        }
        
        if type == "spacer" {
            // Spacer is valid with just type
            return
        }
        
        if layoutTypes.contains(type) {
            validateLayout(node, path: path, errors: &errors, warnings: &warnings)
        } else if type == "sectionLayout" {
            validateSectionLayout(node, path: path, errors: &errors, warnings: &warnings)
        } else if type == "forEach" {
            validateForEach(node, path: path, errors: &errors, warnings: &warnings)
        } else {
            // Assume it's a component
            validateComponent(node, path: path, errors: &errors, warnings: &warnings)
        }
    }
    
    // MARK: - Layout Validation
    
    private func validateLayout(_ layout: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        let type = layout["type"] as? String ?? ""
        
        if !layoutTypes.contains(type) {
            errors.append(.invalidEnumValue(value: type, allowed: Array(layoutTypes), path: "\(path).type"))
        }
        
        // Validate children
        if let children = layout["children"] as? [[String: Any]] {
            for (index, child) in children.enumerated() {
                validateLayoutNode(child, path: "\(path).children[\(index)]", errors: &errors, warnings: &warnings)
            }
        }
        
        // Validate alignment for zstack
        if type == "zstack", let alignment = layout["alignment"] {
            if let alignObj = alignment as? [String: Any] {
                if let h = alignObj["horizontal"] as? String {
                    let allowed = ["leading", "center", "trailing"]
                    if !allowed.contains(h) {
                        errors.append(.invalidEnumValue(value: h, allowed: allowed, path: "\(path).alignment.horizontal"))
                    }
                }
                if let v = alignObj["vertical"] as? String {
                    let allowed = ["top", "center", "bottom"]
                    if !allowed.contains(v) {
                        errors.append(.invalidEnumValue(value: v, allowed: allowed, path: "\(path).alignment.vertical"))
                    }
                }
            } else if let alignStr = alignment as? String {
                let allowed = ["leading", "center", "trailing"]
                if !allowed.contains(alignStr) {
                    errors.append(.invalidEnumValue(value: alignStr, allowed: allowed, path: "\(path).alignment"))
                }
            }
        }
    }
    
    // MARK: - Section Layout Validation
    
    private func validateSectionLayout(_ sectionLayout: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let sections = sectionLayout["sections"] as? [[String: Any]] else {
            errors.append(.missingRequiredField(field: "sections", path: path))
            return
        }
        
        for (index, section) in sections.enumerated() {
            validateSectionDefinition(section, path: "\(path).sections[\(index)]", errors: &errors, warnings: &warnings)
        }
    }
    
    private func validateSectionDefinition(_ section: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let layout = section["layout"] as? [String: Any] else {
            errors.append(.missingRequiredField(field: "layout", path: path))
            return
        }
        
        validateSectionLayoutConfig(layout, path: "\(path).layout", errors: &errors, warnings: &warnings)
        
        // Validate children or dataSource+itemTemplate
        if let children = section["children"] as? [[String: Any]] {
            for (index, child) in children.enumerated() {
                validateLayoutNode(child, path: "\(path).children[\(index)]", errors: &errors, warnings: &warnings)
            }
        }
        
        if let itemTemplate = section["itemTemplate"] as? [String: Any] {
            validateLayoutNode(itemTemplate, path: "\(path).itemTemplate", errors: &errors, warnings: &warnings)
        }
    }
    
    private func validateSectionLayoutConfig(_ config: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let type = config["type"] as? String else {
            errors.append(.missingRequiredField(field: "type", path: path))
            return
        }
        
        if !sectionTypes.contains(type) {
            errors.append(.invalidEnumValue(value: type, allowed: Array(sectionTypes), path: "\(path).type"))
        }
        
        // Validate snapBehavior
        if let snap = config["snapBehavior"] as? String {
            let allowed = ["none", "viewAligned", "paging"]
            if !allowed.contains(snap) {
                errors.append(.invalidEnumValue(value: snap, allowed: allowed, path: "\(path).snapBehavior"))
            }
        }
    }
    
    // MARK: - ForEach Validation
    
    private func validateForEach(_ forEach: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        // Required: items
        if forEach["items"] == nil {
            errors.append(.missingRequiredField(field: "items", path: path))
        }
        
        // Required: template
        guard let template = forEach["template"] as? [String: Any] else {
            errors.append(.missingRequiredField(field: "template", path: path))
            return
        }
        
        validateLayoutNode(template, path: "\(path).template", errors: &errors, warnings: &warnings)
        
        // Validate layout type
        if let layout = forEach["layout"] as? String {
            if !layoutTypes.contains(layout) {
                errors.append(.invalidEnumValue(value: layout, allowed: Array(layoutTypes), path: "\(path).layout"))
            }
        }
        
        // Optional: emptyView
        if let emptyView = forEach["emptyView"] as? [String: Any] {
            validateLayoutNode(emptyView, path: "\(path).emptyView", errors: &errors, warnings: &warnings)
        }
    }
    
    // MARK: - Component Validation
    
    private func validateComponent(_ component: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let type = component["type"] as? String else {
            errors.append(.missingRequiredField(field: "type", path: path))
            return
        }
        
        // Check if known component type
        if !knownComponentTypes.contains(type) && !allowUnknownComponents {
            errors.append(.unknownComponentType(type: type, path: path))
        } else if !knownComponentTypes.contains(type) {
            warnings.append("Unknown component type '\(type)' at \(path) - will require custom resolver")
        }
        
        // Validate image source if present
        if let image = component["image"] as? [String: Any] {
            let hasSystem = image["system"] != nil
            let hasUrl = image["url"] != nil
            if !hasSystem && !hasUrl {
                errors.append(.missingRequiredField(field: "system or url", path: "\(path).image"))
            }
            if hasSystem && hasUrl {
                warnings.append("Image has both 'system' and 'url' at \(path).image - 'system' will take precedence")
            }
        }
        
        // Validate gradient colors
        if let gradientColors = component["gradientColors"] as? [[String: Any]] {
            for (index, color) in gradientColors.enumerated() {
                if color["location"] == nil {
                    errors.append(.missingRequiredField(field: "location", path: "\(path).gradientColors[\(index)]"))
                } else if let location = color["location"] as? Double {
                    if location < 0 || location > 1 {
                        errors.append(.invalidRange(value: location, min: 0, max: 1, path: "\(path).gradientColors[\(index)].location"))
                    }
                }
            }
        }
        
        // Validate actions
        if let actions = component["actions"] as? [String: Any] {
            for (key, value) in actions {
                if let action = value as? [String: Any] {
                    validateAction(action, path: "\(path).actions.\(key)", errors: &errors, warnings: &warnings)
                }
            }
        }
    }
    
    // MARK: - Style Validation
    
    private func validateStyle(_ style: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        // Validate fontWeight
        if let fontWeight = style["fontWeight"] as? String {
            let allowed = ["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"]
            if !allowed.contains(fontWeight) {
                errors.append(.invalidEnumValue(value: fontWeight, allowed: allowed, path: "\(path).fontWeight"))
            }
        }
        
        // Validate textAlignment
        if let textAlignment = style["textAlignment"] as? String {
            let allowed = ["leading", "center", "trailing"]
            if !allowed.contains(textAlignment) {
                errors.append(.invalidEnumValue(value: textAlignment, allowed: allowed, path: "\(path).textAlignment"))
            }
        }
        
        // Validate colors are hex strings
        for colorKey in ["textColor", "backgroundColor", "borderColor", "tintColor"] {
            if let color = style[colorKey] as? String {
                if !isValidHexColor(color) {
                    warnings.append("Color '\(color)' at \(path).\(colorKey) may not be a valid hex color")
                }
            }
        }
    }
    
    // MARK: - Action Validation
    
    private func validateAction(_ action: [String: Any], path: String, errors: inout [CLADSValidationError], warnings: inout [String]) {
        guard let type = action["type"] as? String else {
            errors.append(.missingRequiredField(field: "type", path: path))
            return
        }
        
        switch type {
        case "dismiss":
            // No additional validation needed
            break
            
        case "setState":
            if action["path"] == nil {
                errors.append(.missingRequiredField(field: "path", path: path))
            }
            if action["value"] == nil {
                errors.append(.missingRequiredField(field: "value", path: path))
            }
            
        case "toggleState":
            if action["path"] == nil {
                errors.append(.missingRequiredField(field: "path", path: path))
            }
            
        case "showAlert":
            // title is optional with default
            if let buttons = action["buttons"] as? [[String: Any]] {
                for (index, button) in buttons.enumerated() {
                    if button["label"] == nil {
                        errors.append(.missingRequiredField(field: "label", path: "\(path).buttons[\(index)]"))
                    }
                    if let style = button["style"] as? String {
                        let allowed = ["default", "cancel", "destructive"]
                        if !allowed.contains(style) {
                            errors.append(.invalidEnumValue(value: style, allowed: allowed, path: "\(path).buttons[\(index)].style"))
                        }
                    }
                }
            }
            
        case "navigate":
            if action["destination"] == nil {
                errors.append(.missingRequiredField(field: "destination", path: path))
            }
            if let presentation = action["presentation"] as? String {
                let allowed = ["push", "present", "fullScreen"]
                if !allowed.contains(presentation) {
                    errors.append(.invalidEnumValue(value: presentation, allowed: allowed, path: "\(path).presentation"))
                }
            }
            
        case "sequence":
            guard let steps = action["steps"] as? [[String: Any]] else {
                errors.append(.missingRequiredField(field: "steps", path: path))
                return
            }
            for (index, step) in steps.enumerated() {
                validateAction(step, path: "\(path).steps[\(index)]", errors: &errors, warnings: &warnings)
            }
            
        default:
            if !allowUnknownActions {
                errors.append(.unknownActionType(type: type, path: path))
            } else {
                warnings.append("Unknown action type '\(type)' at \(path) - will require custom handler")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func typeName(_ value: Any?) -> String {
        guard let value = value else { return "null" }
        switch value {
        case is String: return "string"
        case is Int: return "integer"
        case is Double: return "number"
        case is Bool: return "boolean"
        case is [Any]: return "array"
        case is [String: Any]: return "object"
        default: return String(describing: type(of: value))
        }
    }
    
    private func isValidHexColor(_ color: String) -> Bool {
        // Simple validation for hex colors
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8}|[A-Fa-f0-9]{3})$"
        return color.range(of: hexPattern, options: .regularExpression) != nil
    }
}

// MARK: - Convenience Extensions

public extension CLADSValidator {
    /// Validate and return the document if valid, otherwise throw
    func validateAndDecode(jsonString: String) throws -> Document.Definition {
        let result = validate(jsonString: jsonString)
        if !result.isValid {
            if result.errors.count == 1 {
                throw result.errors[0]
            } else {
                throw CLADSValidationError.multipleErrors(result.errors)
            }
        }
        guard let document = result.document else {
            throw CLADSValidationError.decodingFailed(underlying: NSError(domain: "CLADSValidator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document was nil after validation"]))
        }
        return document
    }
    
    /// Register additional known component types
    mutating func registerComponentType(_ type: String) {
        knownComponentTypes.insert(type)
    }
    
    /// Register multiple component types
    mutating func registerComponentTypes(_ types: [String]) {
        knownComponentTypes.formUnion(types)
    }
}
