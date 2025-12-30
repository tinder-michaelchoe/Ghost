//
//  WeatherLocationStore.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - Weather Location Store

/// Manages the selected weather location for the weather widget.
/// Uses UserDefaults to persist the selection.
final class WeatherLocationStore {

    // MARK: - Shared Instance

    static let shared = WeatherLocationStore()

    // MARK: - Notifications

    static let locationDidChangeNotification = Notification.Name("WeatherLocationDidChange")

    // MARK: - Available Locations

    static let availableLocations: [WeatherLocation] = [
        WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York"),
        WeatherLocation(latitude: 34.0522, longitude: -118.2437, name: "Los Angeles"),
        WeatherLocation(latitude: 41.8781, longitude: -87.6298, name: "Chicago")
    ]

    // MARK: - Properties

    private let defaults = UserDefaults.standard
    private let selectedLocationKey = "weather.selectedLocationIndex"

    var selectedLocation: WeatherLocation {
        get {
            let index = defaults.integer(forKey: selectedLocationKey)
            guard index >= 0, index < Self.availableLocations.count else {
                return Self.availableLocations[0]
            }
            return Self.availableLocations[index]
        }
        set {
            if let index = Self.availableLocations.firstIndex(where: { $0.name == newValue.name }) {
                defaults.set(index, forKey: selectedLocationKey)
                NotificationCenter.default.post(name: Self.locationDidChangeNotification, object: nil)
            }
        }
    }

    var selectedIndex: Int {
        get {
            let index = defaults.integer(forKey: selectedLocationKey)
            guard index >= 0, index < Self.availableLocations.count else {
                return 0
            }
            return index
        }
        set {
            guard newValue >= 0, newValue < Self.availableLocations.count else { return }
            defaults.set(newValue, forKey: selectedLocationKey)
            NotificationCenter.default.post(name: Self.locationDidChangeNotification, object: nil)
        }
    }

    // MARK: - Init

    private init() {}
}
