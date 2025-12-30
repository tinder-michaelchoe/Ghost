//
//  WeatherService.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation

// MARK: - Weather Service Protocol

/// Protocol for fetching weather data
public protocol WeatherService: Sendable {

    /// Fetches the current weather for a location
    /// - Parameter location: The location to fetch weather for
    /// - Returns: The current weather conditions
    func currentWeather(for location: WeatherLocation) async throws -> CurrentWeather

    /// Fetches the hourly forecast for a location
    /// - Parameters:
    ///   - location: The location to fetch forecast for
    ///   - hours: Number of hours to forecast (default 24)
    /// - Returns: Array of hourly forecasts
    func hourlyForecast(for location: WeatherLocation, hours: Int) async throws -> [HourlyForecast]

    /// Fetches the daily forecast for a location
    /// - Parameters:
    ///   - location: The location to fetch forecast for
    ///   - days: Number of days to forecast (default 7)
    /// - Returns: Array of daily forecasts
    func dailyForecast(for location: WeatherLocation, days: Int) async throws -> [DailyForecast]
}

// MARK: - Weather Location

/// Represents a geographic location for weather queries
public struct WeatherLocation: Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let name: String?

    public init(latitude: Double, longitude: Double, name: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
    }
}

// MARK: - Current Weather

/// Current weather conditions at a location
public struct CurrentWeather: Sendable {
    public let location: WeatherLocation
    public let temperature: Temperature
    public let condition: WeatherCondition
    public let humidity: Double
    public let precipitationChance: Double
    public let timestamp: Date

    public init(
        location: WeatherLocation,
        temperature: Temperature,
        condition: WeatherCondition,
        humidity: Double,
        precipitationChance: Double,
        timestamp: Date = Date()
    ) {
        self.location = location
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.precipitationChance = precipitationChance
        self.timestamp = timestamp
    }
}

// MARK: - Hourly Forecast

/// Weather forecast for a specific hour
public struct HourlyForecast: Sendable, Identifiable {
    public let id: Date
    public let hour: Date
    public let temperature: Temperature
    public let condition: WeatherCondition
    public let precipitationChance: Double

    public init(
        hour: Date,
        temperature: Temperature,
        condition: WeatherCondition,
        precipitationChance: Double
    ) {
        self.id = hour
        self.hour = hour
        self.temperature = temperature
        self.condition = condition
        self.precipitationChance = precipitationChance
    }
}

// MARK: - Daily Forecast

/// Weather forecast for a specific day
public struct DailyForecast: Sendable, Identifiable {
    public let id: Date
    public let date: Date
    public let highTemperature: Temperature
    public let lowTemperature: Temperature
    public let condition: WeatherCondition
    public let precipitationChance: Double

    public init(
        date: Date,
        highTemperature: Temperature,
        lowTemperature: Temperature,
        condition: WeatherCondition,
        precipitationChance: Double
    ) {
        self.id = date
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.condition = condition
        self.precipitationChance = precipitationChance
    }
}

// MARK: - Temperature

/// Temperature value with unit conversion support
public struct Temperature: Sendable {
    public let celsius: Double

    public init(celsius: Double) {
        self.celsius = celsius
    }

    public init(fahrenheit: Double) {
        self.celsius = (fahrenheit - 32) * 5 / 9
    }

    public var fahrenheit: Double {
        celsius * 9 / 5 + 32
    }

    public func formatted(unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius:
            return String(format: "%.0f°C", celsius)
        case .fahrenheit:
            return String(format: "%.0f°F", fahrenheit)
        }
    }
}

// MARK: - Temperature Unit

/// Unit for temperature display
public enum TemperatureUnit: Sendable {
    case celsius
    case fahrenheit
}

// MARK: - Weather Condition

/// Weather condition types
public enum WeatherCondition: String, Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case heavyRain
    case thunderstorm
    case snow
    case sleet
    case fog
    case windy

    public var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .thunderstorm: return "Thunderstorm"
        case .snow: return "Snow"
        case .sleet: return "Sleet"
        case .fog: return "Fog"
        case .windy: return "Windy"
        }
    }

    public var systemImageName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .sleet: return "cloud.sleet.fill"
        case .fog: return "cloud.fog.fill"
        case .windy: return "wind"
        }
    }
}

// MARK: - Weather Error

/// Errors that can occur during weather operations
public enum WeatherError: Error, Sendable {
    case locationNotFound
    case networkError(String)
    case invalidData
    case serviceUnavailable

    public var localizedDescription: String {
        switch self {
        case .locationNotFound:
            return "Location not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidData:
            return "Invalid weather data received"
        case .serviceUnavailable:
            return "Weather service is unavailable"
        }
    }
}

// MARK: - Weather Service Type

/// Available weather service providers
public enum WeatherServiceType: String, Sendable {
    /// Apple WeatherKit - requires paid developer account and JWT auth
    case weatherKit

    /// National Weather Service - free, US locations only
    case nws
}
