//
//  WeatherKitTokenGenerator.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CryptoKit
import Foundation

/// Generates JWT tokens for WeatherKit REST API authentication.
struct WeatherKitTokenGenerator {

    private let configuration: WeatherKitConfiguration

    init(configuration: WeatherKitConfiguration) {
        self.configuration = configuration
    }

    /// Generates a signed JWT token for WeatherKit API requests.
    /// - Parameter expirationInterval: How long until the token expires (default 1 hour)
    /// - Returns: A signed JWT bearer token
    func generateToken(expirationInterval: TimeInterval = 3600) throws -> String {
        let now = Date()
        let expiration = now.addingTimeInterval(expirationInterval)

        let header = JWTHeader(
            alg: "ES256",
            kid: configuration.keyID,
            id: "\(configuration.teamID).\(configuration.serviceID)"
        )

        let payload = JWTPayload(
            iss: configuration.teamID,
            iat: Int(now.timeIntervalSince1970),
            exp: Int(expiration.timeIntervalSince1970),
            sub: configuration.serviceID
        )

        let headerData = try JSONEncoder().encode(header)
        let payloadData = try JSONEncoder().encode(payload)

        let headerBase64 = headerData.base64URLEncodedString()
        let payloadBase64 = payloadData.base64URLEncodedString()

        let signingInput = "\(headerBase64).\(payloadBase64)"

        let signature = try sign(signingInput)

        return "\(signingInput).\(signature)"
    }

    private func sign(_ input: String) throws -> String {
        guard let inputData = input.data(using: .utf8) else {
            throw WeatherKitTokenError.invalidInput
        }

        let privateKey = try loadPrivateKey()
        let signature = try privateKey.signature(for: inputData)

        return signature.rawRepresentation.base64URLEncodedString()
    }

    private func loadPrivateKey() throws -> P256.Signing.PrivateKey {
        // Remove PEM headers/footers and whitespace if present
        let keyString = configuration.privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: keyString) else {
            throw WeatherKitTokenError.invalidPrivateKey
        }

        // The key from Apple is in PKCS#8 format, we need to extract the raw key
        // PKCS#8 for P-256 has a fixed header we need to skip
        let pkcs8Header: [UInt8] = [
            0x30, 0x81, 0x87, 0x02, 0x01, 0x00, 0x30, 0x13,
            0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02,
            0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D,
            0x03, 0x01, 0x07, 0x04, 0x6D, 0x30, 0x6B, 0x02,
            0x01, 0x01, 0x04, 0x20
        ]

        if keyData.count > pkcs8Header.count {
            // Try PKCS#8 format first
            let headerData = Data(pkcs8Header)
            if keyData.prefix(pkcs8Header.count) == headerData {
                let rawKeyData = keyData.dropFirst(pkcs8Header.count).prefix(32)
                return try P256.Signing.PrivateKey(rawRepresentation: rawKeyData)
            }
        }

        // Try raw key format
        if keyData.count == 32 {
            return try P256.Signing.PrivateKey(rawRepresentation: keyData)
        }

        // Try x963 format
        do {
            return try P256.Signing.PrivateKey(x963Representation: keyData)
        } catch {
            // Try DER format
            do {
                return try P256.Signing.PrivateKey(derRepresentation: keyData)
            } catch {
                throw WeatherKitTokenError.invalidPrivateKey
            }
        }
    }
}

// MARK: - JWT Models

private struct JWTHeader: Encodable {
    let alg: String
    let kid: String
    let id: String
    let typ: String = "JWT"
}

private struct JWTPayload: Encodable {
    let iss: String
    let iat: Int
    let exp: Int
    let sub: String
}

// MARK: - Errors

enum WeatherKitTokenError: Error {
    case invalidInput
    case invalidPrivateKey
    case signingFailed

    var localizedDescription: String {
        switch self {
        case .invalidInput:
            return "Invalid input for JWT signing"
        case .invalidPrivateKey:
            return "Invalid private key format"
        case .signingFailed:
            return "Failed to sign JWT"
        }
    }
}

// MARK: - Base64URL Encoding

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
