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

// MARK: - Weather Locations

/// Shared constants for weather location selection.
enum WeatherLocations {

    /// Notification posted when the selected location changes.
    static let didChangeNotification = Notification.Name("WeatherLocationDidChange")

    /// Available locations for weather display.
    static let available: [WeatherLocation] = [
        WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York"),
        WeatherLocation(latitude: 34.0522, longitude: -118.2437, name: "Los Angeles"),
        WeatherLocation(latitude: 41.8781, longitude: -87.6298, name: "Chicago")
    ]

    /// Gets the currently selected location from persistence.
    static func selectedLocation(from persistence: PersistenceService) -> WeatherLocation {
        let index = selectedIndex(from: persistence)
        guard index >= 0, index < available.count else {
            return available[0]
        }
        return available[index]
    }

    /// Gets the currently selected index from persistence.
    static func selectedIndex(from persistence: PersistenceService) -> Int {
        let index = persistence.get(.weatherSelectedLocationIndex)
        guard index >= 0, index < available.count else {
            return 0
        }
        return index
    }

    /// Sets the selected location index and posts a notification.
    static func setSelectedIndex(_ index: Int, using persistence: PersistenceService) {
        guard index >= 0, index < available.count else { return }
        persistence.set(.weatherSelectedLocationIndex, value: index)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
