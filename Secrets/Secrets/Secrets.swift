//
//  StaticSecretsProvider.swift
//  Secrets
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - Static Secrets Provider

/// A secrets provider that returns values from an in-memory dictionary.
/// Intended for testing and development purposes.
public final class StaticSecretsProvider: SecretsProvider, @unchecked Sendable {

    // MARK: - Properties

    private let secrets: [SecretKey: String]

    // MARK: - Init

    /// Creates a provider with the given secrets dictionary
    public init(secrets: [SecretKey: String]) {
        self.secrets = secrets
    }

    /// Creates a provider with default test values
    public static func testDefaults() -> StaticSecretsProvider {
        StaticSecretsProvider(secrets: [
            // WeatherKit
            .weatherKitTeamID: "TEAM_ID_HERE",
            .weatherKitServiceID: "com.example.weatherkit",
            .weatherKitKeyID: "KEY_ID_HERE",
            .weatherKitPrivateKey: "PRIVATE_KEY_HERE",
            // NWS
            .nwsUserAgent: "GhostApp contact@example.com",
        ])
    }

    // MARK: - SecretsProvider

    public func secret(for key: SecretKey) throws -> String {
        guard let value = secrets[key] else {
            throw SecretsError.missingSecret(key)
        }
        return value
    }
}

// MARK: - Secrets Service Provider

/// Service provider that registers the SecretsProvider.
public final class SecretsServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(SecretsProvider.self) {
            StaticSecretsProvider.testDefaults()
        }
    }
}
