//
//  DataSource.swift
//  CladsRendererFramework
//

import Foundation

/// Data source definition
public struct DataSource: Codable {
    public let type: DataSourceType
    public let value: String?
    public let path: String?

    public init(type: DataSourceType, value: String? = nil, path: String? = nil) {
        self.type = type
        self.value = value
        self.path = path
    }
}

public enum DataSourceType: String, Codable {
    case `static`
    case binding
}
