//
//  DataSource.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - DataSource

extension Document {
    /// Data source definition
    public struct DataSource: Codable {

        /// The type of data source
        public enum Kind: String, Codable {
            case `static`
            case binding
        }

        public let type: Kind
        public let value: String?
        public let path: String?

        public init(type: Kind, value: String? = nil, path: String? = nil) {
            self.type = type
            self.value = value
            self.path = path
        }
    }
}
