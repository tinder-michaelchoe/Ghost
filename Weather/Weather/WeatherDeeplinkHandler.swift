//
//  WeatherDeeplinkHandler.swift
//  Weather
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import Foundation

/// Notification posted when the weather location changes via deeplink.
/// Widgets should observe this to refresh their content.
public extension Notification.Name {
    static let weatherLocationDidChange = Notification.Name("weatherLocationDidChange")
}

/// Handles deeplinks for the weather feature.
/// Example URLs:
/// - ghost://dashboard/weather/city?name=Seattle
/// - ghost://dashboard/weather/city?name=New%20York
public final class WeatherDeeplinkHandler: DeeplinkHandler {

    // MARK: - Properties

    public let feature = "weather"

    private let persistenceService: PersistenceService

    // MARK: - Initialization

    public init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }

    // MARK: - DeeplinkHandler

    @MainActor
    public func handle(_ deeplink: Deeplink) -> Bool {
        // Expecting: ghost://dashboard/weather/city?name=Seattle
        guard deeplink.action == "city" else {
            print("[WeatherDeeplink] Unknown action: \(deeplink.action ?? "nil")")
            return false
        }

        guard let cityName = deeplink.parameter("name") else {
            print("[WeatherDeeplink] Missing 'name' parameter")
            return false
        }

        print("[WeatherDeeplink] Switching to city: \(cityName)")

        // Try to find in available locations (case-insensitive)
        if let index = WeatherLocations.available.firstIndex(where: {
            $0.name?.lowercased() == cityName.lowercased()
        }) {
            // Found in presets
            WeatherLocations.setSelectedIndex(index, using: persistenceService)
            print("[WeatherDeeplink] Selected preset location at index \(index)")
        } else {
            // Not a preset - try to geocode or use as custom
            // For now, check for some well-known cities
            if let location = knownCity(named: cityName) {
                WeatherLocations.setCustomLocation(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    name: location.name,
                    using: persistenceService
                )
                print("[WeatherDeeplink] Set custom location: \(location.name ?? cityName)")
            } else {
                print("[WeatherDeeplink] Unknown city: \(cityName)")
                return false
            }
        }

        // Notify observers that the location changed
        NotificationCenter.default.post(name: .weatherLocationDidChange, object: nil)

        return true
    }

    // MARK: - Known Cities

    /// Returns coordinates for well-known cities not in the preset list.
    private func knownCity(named name: String) -> (latitude: Double, longitude: Double, name: String)? {
        let cities: [(name: String, lat: Double, lon: Double)] = [
            ("Seattle", 47.6062, -122.3321),
            ("San Francisco", 37.7749, -122.4194),
            ("Miami", 25.7617, -80.1918),
            ("Boston", 42.3601, -71.0589),
            ("Denver", 39.7392, -104.9903),
            ("Austin", 30.2672, -97.7431),
            ("Portland", 45.5155, -122.6789),
            ("Phoenix", 33.4484, -112.0740),
            ("Atlanta", 33.7490, -84.3880),
            ("Dallas", 32.7767, -96.7970),
            ("Houston", 29.7604, -95.3698),
            ("Philadelphia", 39.9526, -75.1652),
            ("Washington", 38.9072, -77.0369),
            ("Las Vegas", 36.1699, -115.1398),
            ("Nashville", 36.1627, -86.7816),
            ("Paris", 48.8566, 2.3522),
            ("London", 51.5074, -0.1278),
            ("Tokyo", 35.6762, 139.6503),
            ("Sydney", -33.8688, 151.2093),
        ]

        let lowercasedName = name.lowercased()
        if let city = cities.first(where: { $0.name.lowercased() == lowercasedName }) {
            return (city.lat, city.lon, city.name)
        }
        return nil
    }
}
