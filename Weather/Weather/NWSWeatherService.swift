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
