//
//  WeatherKitAPIModels.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation

// MARK: - API Response Wrapper

/// Root response from WeatherKit API
struct WeatherKitResponse: Decodable, Sendable {
    let currentWeather: CurrentWeatherResponse?
    let forecastHourly: HourlyForecastResponse?
}

// MARK: - Current Weather Response

struct CurrentWeatherResponse: Decodable, Sendable {
    let metadata: WeatherMetadata
    let asOf: String
    let cloudCover: Double?
    let conditionCode: String
    let daylight: Bool?
    let humidity: Double
    let precipitationIntensity: Double?
    let pressure: Double?
    let pressureTrend: String?
    let temperature: Double
    let temperatureApparent: Double?
    let temperatureDewPoint: Double?
    let uvIndex: Int?
    let visibility: Double?
    let windDirection: Int?
    let windGust: Double?
    let windSpeed: Double?
}

// MARK: - Hourly Forecast Response

struct HourlyForecastResponse: Decodable, Sendable {
    let metadata: WeatherMetadata
    let hours: [HourlyWeatherResponse]
}

struct HourlyWeatherResponse: Decodable, Sendable {
    let forecastStart: String
    let cloudCover: Double?
    let conditionCode: String
    let daylight: Bool?
    let humidity: Double
    let precipitationAmount: Double?
    let precipitationIntensity: Double?
    let precipitationChance: Double
    let precipitationType: String?
    let pressure: Double?
    let pressureTrend: String?
    let snowfallIntensity: Double?
    let snowfallAmount: Double?
    let temperature: Double
    let temperatureApparent: Double?
    let temperatureDewPoint: Double?
    let uvIndex: Int?
    let visibility: Double?
    let windDirection: Int?
    let windGust: Double?
    let windSpeed: Double?
}

// MARK: - Metadata

struct WeatherMetadata: Decodable, Sendable {
    let attributionURL: String?
    let expireTime: String?
    let latitude: Double
    let longitude: Double
    let readTime: String?
    let reportedTime: String?
    let units: String?
    let version: Int?
}

// MARK: - Condition Code Mapping

extension String {
    /// Maps WeatherKit condition codes to our WeatherCondition enum
    var toWeatherCondition: CoreContracts.WeatherCondition {
        switch self.lowercased() {
        case "clear", "mostlyclear":
            return .clear
        case "partlycloudy", "mostlycloudy":
            return .partlyCloudy
        case "cloudy", "overcast":
            return .cloudy
        case "rain", "drizzle":
            return .rain
        case "heavyrain":
            return .heavyRain
        case "thunderstorm", "thunderstorms", "scatteredthunderstorms", "isolatedthunderstorms":
            return .thunderstorm
        case "snow", "flurries", "heavysnow", "blizzard":
            return .snow
        case "sleet", "freezingrain", "freezingdrizzle", "wintry_mix", "wintrymix":
            return .sleet
        case "fog", "haze", "smoky", "dust", "blowingdust":
            return .fog
        case "windy", "breezy":
            return .windy
        default:
            return .clear
        }
    }
}

// MARK: - Date Parsing

extension String {
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

import CoreContracts
