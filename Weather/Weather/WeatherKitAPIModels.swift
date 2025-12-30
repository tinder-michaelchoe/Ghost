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
    let forecastDaily: DailyForecastResponse?
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

// MARK: - Daily Forecast Response

struct DailyForecastResponse: Decodable, Sendable {
    let metadata: WeatherMetadata
    let days: [DailyWeatherResponse]
}

struct DailyWeatherResponse: Decodable, Sendable {
    let forecastStart: String
    let forecastEnd: String
    let conditionCode: String
    let maxUvIndex: Int?
    let moonPhase: String?
    let moonrise: String?
    let moonset: String?
    let precipitationAmount: Double?
    let precipitationChance: Double
    let precipitationType: String?
    let snowfallAmount: Double?
    let solarMidnight: String?
    let solarNoon: String?
    let sunrise: String?
    let sunriseCivil: String?
    let sunriseNautical: String?
    let sunriseAstronomical: String?
    let sunset: String?
    let sunsetCivil: String?
    let sunsetNautical: String?
    let sunsetAstronomical: String?
    let temperatureMax: Double
    let temperatureMin: Double
    let daytimeForecast: DaytimeForecast?
    let overnightForecast: OvernightForecast?
}

struct DaytimeForecast: Decodable, Sendable {
    let forecastStart: String
    let forecastEnd: String
    let cloudCover: Double?
    let conditionCode: String
    let humidity: Double?
    let precipitationAmount: Double?
    let precipitationChance: Double?
    let precipitationType: String?
    let snowfallAmount: Double?
    let windDirection: Int?
    let windSpeed: Double?
}

struct OvernightForecast: Decodable, Sendable {
    let forecastStart: String
    let forecastEnd: String
    let cloudCover: Double?
    let conditionCode: String
    let humidity: Double?
    let precipitationAmount: Double?
    let precipitationChance: Double?
    let precipitationType: String?
    let snowfallAmount: Double?
    let windDirection: Int?
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

import CoreContracts
