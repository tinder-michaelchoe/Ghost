//
//  Component.swift
//  CladsRendererFramework
//

import Foundation

/// Component types supported by the renderer
public enum ComponentType: String, Codable {
    case label
    case button
    case textfield
    case image
}

/// Actions that can be bound to component events
public struct ComponentActions: Codable {
    public let onTap: String?
    public let onValueChanged: String?

    public init(onTap: String? = nil, onValueChanged: String? = nil) {
        self.onTap = onTap
        self.onValueChanged = onValueChanged
    }
}

/// A UI component (label, button, textfield, etc.)
public struct Component: Codable {
    public let type: ComponentType
    public let id: String?
    public let styleId: String?
    public let dataSourceId: String?
    public let label: String?
    public let placeholder: String?
    public let bind: String?
    public let fillWidth: Bool?
    public let actions: ComponentActions?
    public let data: DataReference?

    public init(
        type: ComponentType,
        id: String? = nil,
        styleId: String? = nil,
        dataSourceId: String? = nil,
        label: String? = nil,
        placeholder: String? = nil,
        bind: String? = nil,
        fillWidth: Bool? = nil,
        actions: ComponentActions? = nil,
        data: DataReference? = nil
    ) {
        self.type = type
        self.id = id
        self.styleId = styleId
        self.dataSourceId = dataSourceId
        self.label = label
        self.placeholder = placeholder
        self.bind = bind
        self.fillWidth = fillWidth
        self.actions = actions
        self.data = data
    }
}

/// Reference to a data source or inline data
public struct DataReference: Codable {
    public let type: DataReferenceType
    public let value: String?
    public let path: String?
    public let template: String?

    public init(type: DataReferenceType, value: String? = nil, path: String? = nil, template: String? = nil) {
        self.type = type
        self.value = value
        self.path = path
        self.template = template
    }
}

public enum DataReferenceType: String, Codable {
    case `static`
    case binding
}
