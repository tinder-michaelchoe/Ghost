//
//  WeatherKitConfiguration.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation

/// Configuration required for WeatherKit REST API authentication.
public struct WeatherKitConfiguration: Sendable {

    /// Your Apple Developer Team ID
    public let teamID: String

    /// The Service ID (Bundle ID style, e.g., "com.myapp.weatherkit")
    public let serviceID: String

    /// The Key ID from the private key you created in App Store Connect
    public let keyID: String

    /// The ES256 private key in PEM format (without headers)
    public let privateKey: String

    public init(teamID: String, serviceID: String, keyID: String, privateKey: String) {
        self.teamID = teamID
        self.serviceID = serviceID
        self.keyID = keyID
        self.privateKey = privateKey
    }
}
