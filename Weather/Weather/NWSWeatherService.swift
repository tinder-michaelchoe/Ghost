//
//  NWSWeatherService.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - NWS Weather Service

/// Implementation of WeatherService using the National Weather Service API (api.weather.gov).
/// This is a free API that doesn't require authentication, only a User-Agent header.
/// Note: Only works for US locations.
public final class NWSWeatherService: WeatherService, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let userAgent: String

    private static let baseURL = "https://api.weather.gov"

    // Cache for grid lookups to avoid repeated /points calls
    private var gridCache: [String: NWSPointsProperties] = [:]
    private let cacheQueue = DispatchQueue(label: "com.weather.nws.cache")

    // MARK: - Init

    /// Creates an NWS Weather Service
    /// - Parameters:
    ///   - networkClient: The network client to use for requests
    ///   - userAgent: Required User-Agent header (e.g., "MyApp contact@example.com")
    public init(networkClient: NetworkClient, userAgent: String) {
        self.networkClient = networkClient
        self.userAgent = userAgent
    }

    // MARK: - WeatherService

    public func currentWeather(for location: WeatherLocation) async throws -> CurrentWeather {
        // NWS doesn't have a direct "current weather" endpoint
        // We use the first hour of the hourly forecast as current conditions
        let forecasts = try await hourlyForecast(for: location, hours: 1)

        guard let current = forecasts.first else {
            throw WeatherError.invalidData
        }

        return CurrentWeather(
            location: location,
            temperature: current.temperature,
            condition: current.condition,
            humidity: 0, // Would need separate observation endpoint
            precipitationChance: current.precipitationChance,
            timestamp: current.hour
        )
    }

    public func hourlyForecast(for location: WeatherLocation, hours: Int = 24) async throws -> [HourlyForecast] {
        let gridInfo = try await getGridInfo(for: location)

        guard let forecastURL = URL(string: gridInfo.forecastHourly) else {
            throw WeatherError.networkError("Invalid forecast URL")
        }

        let request = NetworkRequest.get(
            forecastURL,
            headers: [
                "User-Agent": userAgent,
                "Accept": "application/geo+json"
            ]
        )

        let response: NWSHourlyForecastResponse = try await networkClient.perform(request)

        return response.properties.periods.prefix(hours).compactMap { period in
            guard let forecastDate = period.startTime.toDate else {
                return nil
            }

            // NWS returns temperature in Fahrenheit
            let temperature = period.temperatureUnit == "F"
                ? Temperature(fahrenheit: Double(period.temperature))
                : Temperature(celsius: Double(period.temperature))

            let precipChance = (period.probabilityOfPrecipitation?.value ?? 0) / 100.0

            return HourlyForecast(
                hour: forecastDate,
                temperature: temperature,
                condition: period.shortForecast.nwsToWeatherCondition,
                precipitationChance: precipChance
            )
        }
    }

    public func dailyForecast(for location: WeatherLocation, days: Int = 7) async throws -> [DailyForecast] {
        let gridInfo = try await getGridInfo(for: location)

        guard let forecastURL = URL(string: gridInfo.forecast) else {
            throw WeatherError.networkError("Invalid forecast URL")
        }

        let request = NetworkRequest.get(
            forecastURL,
            headers: [
                "User-Agent": userAgent,
                "Accept": "application/geo+json"
            ]
        )

        let response: NWSDailyForecastResponse = try await networkClient.perform(request)

        // NWS returns periods where each day has two entries: day and night
        // Group by date and extract high (daytime) and low (nighttime) temps
        var dailyForecasts: [DailyForecast] = []
        let calendar = Calendar.current
        var processedDates: Set<DateComponents> = []

        for period in response.properties.periods {
            guard let date = period.startTime.toDate else { continue }

            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

            // Skip if we've already processed this date
            if processedDates.contains(dateComponents) { continue }

            // Find the matching day/night pair
            let dayPeriod = period.isDaytime ? period : nil
            let nightPeriod = !period.isDaytime ? period : nil

            // Look for the complementary period
            let matchingPeriod = response.properties.periods.first { p in
                guard let pDate = p.startTime.toDate else { return false }
                let pComponents = calendar.dateComponents([.year, .month, .day], from: pDate)
                return pComponents == dateComponents && p.isDaytime != period.isDaytime
            }

            let actualDayPeriod = dayPeriod ?? matchingPeriod
            let actualNightPeriod = nightPeriod ?? matchingPeriod

            let highTemp: Temperature
            let lowTemp: Temperature
            let condition: WeatherCondition

            if let day = actualDayPeriod {
                highTemp = day.temperatureUnit == "F"
                    ? Temperature(fahrenheit: Double(day.temperature))
                    : Temperature(celsius: Double(day.temperature))
                condition = day.shortForecast.nwsToWeatherCondition
            } else {
                highTemp = period.temperatureUnit == "F"
                    ? Temperature(fahrenheit: Double(period.temperature))
                    : Temperature(celsius: Double(period.temperature))
                condition = period.shortForecast.nwsToWeatherCondition
            }

            if let night = actualNightPeriod {
                lowTemp = night.temperatureUnit == "F"
                    ? Temperature(fahrenheit: Double(night.temperature))
                    : Temperature(celsius: Double(night.temperature))
            } else {
                lowTemp = highTemp
            }

            let precipChance = max(
                actualDayPeriod?.probabilityOfPrecipitation?.value ?? 0,
                actualNightPeriod?.probabilityOfPrecipitation?.value ?? 0
            ) / 100.0

            let forecastDate = calendar.startOfDay(for: date)
            dailyForecasts.append(DailyForecast(
                date: forecastDate,
                highTemperature: highTemp,
                lowTemperature: lowTemp,
                condition: condition,
                precipitationChance: precipChance
            ))

            processedDates.insert(dateComponents)

            if dailyForecasts.count >= days { break }
        }

        return dailyForecasts
    }

    // MARK: - Private Helpers

    private func getGridInfo(for location: WeatherLocation) async throws -> NWSPointsProperties {
        let cacheKey = "\(location.latitude),\(location.longitude)"

        // Check cache first
        if let cached = cacheQueue.sync(execute: { gridCache[cacheKey] }) {
            return cached
        }

        guard let url = URL(string: "\(Self.baseURL)/points/\(location.latitude),\(location.longitude)") else {
            throw WeatherError.networkError("Invalid points URL")
        }

        let request = NetworkRequest.get(
            url,
            headers: [
                "User-Agent": userAgent,
                "Accept": "application/geo+json"
            ]
        )

        let response: NWSPointsResponse = try await networkClient.perform(request)

        // Cache the result
        cacheQueue.sync {
            gridCache[cacheKey] = response.properties
        }

        return response.properties
    }
}
