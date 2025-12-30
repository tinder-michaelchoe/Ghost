//
//  SecretsProvider.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation

// MARK: - Secret Key

/// Keys for retrievable secrets
public enum SecretKey: String, Sendable, CaseIterable {
    // WeatherKit (Apple)
    case weatherKitTeamID
    case weatherKitServiceID
    case weatherKitKeyID
    case weatherKitPrivateKey

    // NWS (National Weather Service)
    case nwsUserAgent
}

// MARK: - Secrets Provider Protocol

/// Protocol for retrieving secrets from an abstracted source
public protocol SecretsProvider: Sendable {
    /// Retrieves a secret value for the given key
    /// - Parameter key: The secret key to retrieve
    /// - Returns: The secret value
    /// - Throws: SecretsError.missingSecret if the key is not found
    func secret(for key: SecretKey) throws -> String
}

// MARK: - Secrets Error

/// Errors that can occur during secret retrieval
public enum SecretsError: Error, Sendable {
    case missingSecret(SecretKey)

    public var localizedDescription: String {
        switch self {
        case .missingSecret(let key):
            return "Missing secret for key: \(key.rawValue)"
        }
    }
}
