//
//  Action.swift
//  CladsRendererFramework
//
//  Schema types for action definitions. These are decoded directly from JSON.
//

import Foundation

// MARK: - Action

extension Document {
    /// An action definition from JSON.
    ///
    /// Actions are decoded from the `actions` dictionary in a Document:
    /// ```json
    /// {
    ///   "actions": {
    ///     "myAction": { "type": "dismiss" },
    ///     "updateState": { "type": "setState", "path": "counter", "value": 10 }
    ///   }
    /// }
    /// ```
    ///
    /// The `type` field determines which action variant is decoded.
    public enum Action: Codable, Sendable {
        case dismiss
        case setState(SetStateAction)
        case toggleState(ToggleStateAction)
        case showAlert(ShowAlertAction)
        case navigate(NavigateAction)
        case sequence(SequenceAction)
        case custom(CustomAction)

        // MARK: - Coding Keys

        private enum CodingKeys: String, CodingKey {
            case type
        }

        private enum ActionType: String, Codable {
            case dismiss
            case setState
            case toggleState
            case showAlert
            case navigate
            case sequence
        }

        // MARK: - Codable

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Try to decode known action types
            if let type = try? container.decode(ActionType.self, forKey: .type) {
                switch type {
                case .dismiss:
                    self = .dismiss
                case .setState:
                    self = .setState(try SetStateAction(from: decoder))
                case .toggleState:
                    self = .toggleState(try ToggleStateAction(from: decoder))
                case .showAlert:
                    self = .showAlert(try ShowAlertAction(from: decoder))
                case .navigate:
                    self = .navigate(try NavigateAction(from: decoder))
                case .sequence:
                    self = .sequence(try SequenceAction(from: decoder))
                }
            } else {
                // Unknown type - decode as custom action
                self = .custom(try CustomAction(from: decoder))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .dismiss:
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(ActionType.dismiss, forKey: .type)
            case .setState(let action):
                try action.encode(to: encoder)
            case .toggleState(let action):
                try action.encode(to: encoder)
            case .showAlert(let action):
                try action.encode(to: encoder)
            case .navigate(let action):
                try action.encode(to: encoder)
            case .sequence(let action):
                try action.encode(to: encoder)
            case .custom(let action):
                try action.encode(to: encoder)
            }
        }
    }
}

// MARK: - SetStateAction

extension Document {
    /// Sets a value in the state store.
    ///
    /// JSON:
    /// ```json
    /// { "type": "setState", "path": "user.name", "value": "John" }
    /// { "type": "setState", "path": "counter", "value": { "$expr": "counter + 1" } }
    /// ```
    public struct SetStateAction: Codable, Sendable {
        public let path: String
        public let value: SetValue

        public init(path: String, value: SetValue) {
            self.path = path
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case type, path, value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            path = try container.decode(String.self, forKey: .path)
            value = try container.decode(SetValue.self, forKey: .value)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("setState", forKey: .type)
            try container.encode(path, forKey: .path)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - ToggleStateAction

extension Document {
    /// Toggles a boolean value in the state store.
    ///
    /// JSON:
    /// ```json
    /// { "type": "toggleState", "path": "selected.technology" }
    /// ```
    public struct ToggleStateAction: Codable, Sendable {
        public let path: String

        public init(path: String) {
            self.path = path
        }

        private enum CodingKeys: String, CodingKey {
            case type, path
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            path = try container.decode(String.self, forKey: .path)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("toggleState", forKey: .type)
            try container.encode(path, forKey: .path)
        }
    }
}

// MARK: - SetValue

extension Document {
    /// A value to set in state - either a literal or an expression.
    ///
    /// JSON:
    /// ```json
    /// "hello"           // literal string
    /// 42                // literal number
    /// true              // literal bool
    /// { "$expr": "x+1" } // expression
    /// ```
    public enum SetValue: Codable, Sendable {
        case literal(StateValue)
        case expression(String)

        private enum ExpressionKeys: String, CodingKey {
            case expr = "$expr"
        }

        public init(from decoder: Decoder) throws {
            // First try to decode as expression object
            if let container = try? decoder.container(keyedBy: ExpressionKeys.self),
               let expr = try? container.decode(String.self, forKey: .expr) {
                self = .expression(expr)
                return
            }

            // Otherwise decode as literal StateValue
            self = .literal(try StateValue(from: decoder))
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .literal(let value):
                try value.encode(to: encoder)
            case .expression(let expr):
                var container = encoder.container(keyedBy: ExpressionKeys.self)
                try container.encode(expr, forKey: .expr)
            }
        }
    }
}

// MARK: - ShowAlertAction

extension Document {
    /// Shows an alert dialog.
    ///
    /// JSON:
    /// ```json
    /// {
    ///   "type": "showAlert",
    ///   "title": "Confirm",
    ///   "message": "Are you sure?",
    ///   "buttons": [
    ///     { "label": "Cancel", "style": "cancel" },
    ///     { "label": "Delete", "style": "destructive", "action": "deleteItem" }
    ///   ]
    /// }
    /// ```
    public struct ShowAlertAction: Codable, Sendable {
        public let title: String
        public let message: AlertMessageContent?
        public let buttons: [AlertButton]?

        public init(title: String, message: AlertMessageContent? = nil, buttons: [AlertButton]? = nil) {
            self.title = title
            self.message = message
            self.buttons = buttons
        }

        private enum CodingKeys: String, CodingKey {
            case type, title, message, buttons
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Alert"
            message = try container.decodeIfPresent(AlertMessageContent.self, forKey: .message)
            buttons = try container.decodeIfPresent([AlertButton].self, forKey: .buttons)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("showAlert", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(message, forKey: .message)
            try container.encodeIfPresent(buttons, forKey: .buttons)
        }
    }
}

// MARK: - AlertMessageContent

extension Document {
    /// Alert message content - static string or template with bindings.
    ///
    /// JSON:
    /// ```json
    /// "Simple message"                                    // static
    /// { "type": "binding", "template": "Hello ${name}" }  // template
    /// ```
    public enum AlertMessageContent: Codable, Sendable {
        case `static`(String)
        case template(String)

        private enum CodingKeys: String, CodingKey {
            case type, template
        }

        public init(from decoder: Decoder) throws {
            // Try as simple string first
            if let container = try? decoder.singleValueContainer(),
               let string = try? container.decode(String.self) {
                self = .static(string)
                return
            }

            // Try as template object
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            if type == "binding" {
                let template = try container.decode(String.self, forKey: .template)
                self = .template(template)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown message type: \(type)")
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .static(let string):
                var container = encoder.singleValueContainer()
                try container.encode(string)
            case .template(let template):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode("binding", forKey: .type)
                try container.encode(template, forKey: .template)
            }
        }
    }
}

// MARK: - AlertButton

extension Document {
    /// A button in an alert dialog.
    ///
    /// JSON:
    /// ```json
    /// { "label": "OK" }
    /// { "label": "Delete", "style": "destructive", "action": "confirmDelete" }
    /// ```
    public struct AlertButton: Codable, Sendable {
        public let label: String
        public let style: AlertButtonStyle?
        public let action: String?

        public init(label: String, style: AlertButtonStyle? = nil, action: String? = nil) {
            self.label = label
            self.style = style
            self.action = action
        }
    }
}

// MARK: - NavigateAction

extension Document {
    /// Navigates to a destination.
    ///
    /// JSON:
    /// ```json
    /// { "type": "navigate", "destination": "details", "presentation": "push" }
    /// { "type": "navigate", "destination": "settings", "presentation": "present" }
    /// ```
    public struct NavigateAction: Codable, Sendable {
        public let destination: String
        public let presentation: NavigationPresentation?

        public init(destination: String, presentation: NavigationPresentation? = nil) {
            self.destination = destination
            self.presentation = presentation
        }

        private enum CodingKeys: String, CodingKey {
            case type, destination, presentation
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            destination = try container.decode(String.self, forKey: .destination)
            presentation = try container.decodeIfPresent(NavigationPresentation.self, forKey: .presentation)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("navigate", forKey: .type)
            try container.encode(destination, forKey: .destination)
            try container.encodeIfPresent(presentation, forKey: .presentation)
        }
    }
}

// MARK: - SequenceAction

extension Document {
    /// Executes multiple actions in sequence.
    ///
    /// JSON:
    /// ```json
    /// {
    ///   "type": "sequence",
    ///   "steps": [
    ///     { "type": "setState", "path": "loading", "value": true },
    ///     { "type": "navigate", "destination": "results" }
    ///   ]
    /// }
    /// ```
    public struct SequenceAction: Codable, Sendable {
        public let steps: [Action]

        public init(steps: [Action]) {
            self.steps = steps
        }

        private enum CodingKeys: String, CodingKey {
            case type, steps
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            steps = try container.decode([Action].self, forKey: .steps)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("sequence", forKey: .type)
            try container.encode(steps, forKey: .steps)
        }
    }
}

// MARK: - CustomAction

extension Document {
    /// A custom action with an unknown type.
    ///
    /// Used for extensibility - allows defining action types not built into the framework.
    ///
    /// JSON:
    /// ```json
    /// { "type": "analytics.track", "event": "button_clicked", "properties": {...} }
    /// ```
    public struct CustomAction: Codable, Sendable {
        public let type: String
        public let parameters: [String: StateValue]

        public init(type: String, parameters: [String: StateValue] = [:]) {
            self.type = type
            self.parameters = parameters
        }

        private struct DynamicCodingKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue: Int) {
                return nil
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)

            // Extract type
            guard let typeKey = DynamicCodingKey(stringValue: "type"),
                  let type = try? container.decode(String.self, forKey: typeKey) else {
                throw DecodingError.keyNotFound(
                    DynamicCodingKey(stringValue: "type")!,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing 'type' field")
                )
            }
            self.type = type

            // Extract all other fields as parameters
            var params: [String: StateValue] = [:]
            for key in container.allKeys where key.stringValue != "type" {
                if let value = try? container.decode(StateValue.self, forKey: key) {
                    params[key.stringValue] = value
                }
            }
            self.parameters = params
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            try container.encode(type, forKey: DynamicCodingKey(stringValue: "type")!)
            for (key, value) in parameters {
                if let codingKey = DynamicCodingKey(stringValue: key) {
                    try container.encode(value, forKey: codingKey)
                }
            }
        }
    }
}
