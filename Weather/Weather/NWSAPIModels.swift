//
//  NWSAPIModels.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - Points Response

/// Response from /points/{lat},{lon} endpoint
struct NWSPointsResponse: Decodable, Sendable {
    let properties: NWSPointsProperties
}

struct NWSPointsProperties: Decodable, Sendable {
    let gridId: String
    let gridX: Int
    let gridY: Int
    let forecast: String
    let forecastHourly: String
    let forecastGridData: String
    let relativeLocation: NWSRelativeLocation?
    let timeZone: String
}

struct NWSRelativeLocation: Decodable, Sendable {
    let properties: NWSRelativeLocationProperties
}

struct NWSRelativeLocationProperties: Decodable, Sendable {
    let city: String
    let state: String
}

// MARK: - Hourly Forecast Response

/// Response from /gridpoints/{office}/{x},{y}/forecast/hourly endpoint
struct NWSHourlyForecastResponse: Decodable, Sendable {
    let properties: NWSForecastProperties
}

struct NWSForecastProperties: Decodable, Sendable {
    let units: String?
    let updateTime: String?
    let periods: [NWSForecastPeriod]
}

struct NWSForecastPeriod: Decodable, Sendable {
    let number: Int
    let startTime: String
    let endTime: String
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let windDirection: String
    let shortForecast: String
    let detailedForecast: String?
    let probabilityOfPrecipitation: NWSQuantitativeValue?
    let relativeHumidity: NWSQuantitativeValue?
    let dewpoint: NWSQuantitativeValue?
}

struct NWSQuantitativeValue: Decodable, Sendable {
    let unitCode: String
    let value: Double?
}

// MARK: - Daily Forecast Response

/// Response from /gridpoints/{office}/{x},{y}/forecast endpoint
/// The daily forecast returns periods where each day has two entries: day and night
struct NWSDailyForecastResponse: Decodable, Sendable {
    let properties: NWSForecastProperties
}

// MARK: - Date Parsing Helper

extension String {
    /// Parses ISO8601 date string to Date
    var toDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}

// MARK: - Condition Code Mapping

extension String {
    /// Maps NWS short forecast descriptions to WeatherCondition
    var nwsToWeatherCondition: WeatherCondition {
        let lowercased = self.lowercased()

        if lowercased.contains("thunder") {
            return .thunderstorm
        } else if lowercased.contains("snow") || lowercased.contains("flurr") || lowercased.contains("blizzard") {
            return .snow
        } else if lowercased.contains("sleet") || lowercased.contains("freezing") || lowercased.contains("ice") {
            return .sleet
        } else if lowercased.contains("heavy rain") || lowercased.contains("showers") {
            return .heavyRain
        } else if lowercased.contains("rain") || lowercased.contains("drizzle") {
            return .rain
        } else if lowercased.contains("fog") || lowercased.contains("mist") || lowercased.contains("haze") {
            return .fog
        } else if lowercased.contains("wind") || lowercased.contains("breezy") {
            return .windy
        } else if lowercased.contains("cloudy") || lowercased.contains("overcast") {
            if lowercased.contains("partly") || lowercased.contains("mostly clear") {
                return .partlyCloudy
            }
            return .cloudy
        } else if lowercased.contains("sunny") || lowercased.contains("clear") {
            return .clear
        }

        return .clear
    }
}
