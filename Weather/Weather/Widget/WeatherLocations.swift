//
//  WeatherLocations.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - Weather Persistence Keys

/// Persistence keys used by the Weather module.
public extension PersistenceKey where Value == Int {
    static let weatherSelectedLocationIndex = PersistenceKey(
        "weather.selectedLocationIndex",
        default: 0
    )
}

public extension PersistenceKey where Value == Double {
    static let weatherCustomLatitude = PersistenceKey(
        "weather.customLatitude",
        default: 0.0
    )
    static let weatherCustomLongitude = PersistenceKey(
        "weather.customLongitude",
        default: 0.0
    )
}

public extension PersistenceKey where Value == String {
    static let weatherCustomLocationName = PersistenceKey(
        "weather.customLocationName",
        default: ""
    )
}

// MARK: - Weather Locations

/// Shared constants for weather location selection.
enum WeatherLocations {

    /// Index value indicating a custom location is selected.
    static let customLocationIndex = -1

    /// Available preset locations for weather display.
    static let available: [WeatherLocation] = [
        WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York"),
        WeatherLocation(latitude: 34.0522, longitude: -118.2437, name: "Los Angeles"),
        WeatherLocation(latitude: 41.8781, longitude: -87.6298, name: "Chicago")
    ]

    /// Gets the currently selected location from persistence.
    /// Returns either a preset location or a custom location.
    static func selectedLocation(from persistence: PersistenceService) -> WeatherLocation {
        let index = selectedIndex(from: persistence)

        if index == customLocationIndex {
            return customLocation(from: persistence) ?? available[0]
        }

        guard index >= 0, index < available.count else {
            return available[0]
        }
        return available[index]
    }

    /// Gets the currently selected index from persistence.
    /// Returns -1 for custom location, or 0+ for preset locations.
    static func selectedIndex(from persistence: PersistenceService) -> Int {
        persistence.get(.weatherSelectedLocationIndex)
    }

    /// Sets the selected location index.
    /// Use -1 for custom location, or 0+ for preset locations.
    static func setSelectedIndex(_ index: Int, using persistence: PersistenceService) {
        persistence.set(.weatherSelectedLocationIndex, value: index)
    }

    /// Gets the custom location from persistence.
    static func customLocation(from persistence: PersistenceService) -> WeatherLocation? {
        let latitude = persistence.get(.weatherCustomLatitude)
        let longitude = persistence.get(.weatherCustomLongitude)
        let name = persistence.get(.weatherCustomLocationName)

        // Check if we have valid coordinates
        guard latitude != 0.0 || longitude != 0.0 else {
            return nil
        }

        return WeatherLocation(
            latitude: latitude,
            longitude: longitude,
            name: name.isEmpty ? nil : name
        )
    }

    /// Sets a custom location and selects it.
    static func setCustomLocation(
        latitude: Double,
        longitude: Double,
        name: String?,
        using persistence: PersistenceService
    ) {
        persistence.set(.weatherCustomLatitude, value: latitude)
        persistence.set(.weatherCustomLongitude, value: longitude)
        persistence.set(.weatherCustomLocationName, value: name ?? "")
        persistence.set(.weatherSelectedLocationIndex, value: customLocationIndex)
    }
}
