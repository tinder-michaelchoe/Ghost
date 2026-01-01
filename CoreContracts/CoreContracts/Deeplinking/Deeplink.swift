//
//  Deeplink.swift
//  CoreContracts
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Represents a parsed deep link URL.
/// URL format: ghost://[tab]/[feature]/[action]?[query]
public struct Deeplink: Sendable, Equatable {

    /// The URL scheme (e.g., "ghost")
    public let scheme: String

    /// The tab to navigate to (from URL host)
    /// e.g., "dashboard", "settings"
    public let tab: String?

    /// The feature that should handle this deeplink (first path component)
    /// e.g., "weather", "art"
    /// Handlers register by feature name.
    public let feature: String?

    /// The action to perform within the feature (second path component)
    /// e.g., "city", "refresh"
    public let action: String?

    /// All path components for more complex routing
    public let pathComponents: [String]

    /// Query parameters as key-value pairs
    public let queryParameters: [String: String]

    /// The original URL that was parsed
    public let originalURL: URL

    // MARK: - Initialization

    /// Creates a Deeplink from a URL.
    /// Returns nil if the URL cannot be parsed.
    public init?(url: URL) {
        guard let scheme = url.scheme else { return nil }

        self.scheme = scheme
        self.tab = url.host
        self.originalURL = url

        // Parse path components (filter out empty strings from leading "/")
        let components = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        self.pathComponents = components

        // First path component is the feature
        self.feature = components.first

        // Second path component is the action
        self.action = components.count > 1 ? components[1] : nil

        // Parse query parameters
        var params: [String: String] = [:]
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            for item in queryItems {
                params[item.name] = item.value ?? ""
            }
        }
        self.queryParameters = params
    }

    // MARK: - Convenience

    /// Returns a query parameter value for the given key.
    public func parameter(_ key: String) -> String? {
        queryParameters[key]
    }

    /// Returns path components after feature and action (for deeper routing)
    public var remainingPath: [String] {
        guard pathComponents.count > 2 else { return [] }
        return Array(pathComponents.dropFirst(2))
    }
}
