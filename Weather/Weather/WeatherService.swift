//
//  WeatherService.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - WeatherKit Service

/// Implementation of WeatherService using Apple's WeatherKit REST API.
public final class WeatherKitService: WeatherService, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let configuration: WeatherKitConfiguration
    private let tokenGenerator: WeatherKitTokenGenerator
    private let locale: String

    private static let baseURL = "https://weatherkit.apple.com/api/v1/weather"

    // MARK: - Init

    public init(
        networkClient: NetworkClient,
        configuration: WeatherKitConfiguration,
        locale: String = "en_US"
    ) {
        self.networkClient = networkClient
        self.configuration = configuration
        self.tokenGenerator = WeatherKitTokenGenerator(configuration: configuration)
        self.locale = locale
    }

    // MARK: - WeatherService

    public func currentWeather(for location: WeatherLocation) async throws -> CurrentWeather {
        let token = try tokenGenerator.generateToken()

        guard let url = buildURL(
            for: location,
            dataSets: ["currentWeather"]
        ) else {
            throw WeatherError.networkError("Invalid URL")
        }

        let request = NetworkRequest.get(
            url,
            headers: ["Authorization": "Bearer \(token)"]
        )

        let response: WeatherKitResponse = try await networkClient.perform(request)

        guard let current = response.currentWeather else {
            throw WeatherError.invalidData
        }

        return mapCurrentWeather(current, location: location)
    }

    public func hourlyForecast(
        for location: WeatherLocation,
        hours: Int = 24
    ) async throws -> [HourlyForecast] {
        let token = try tokenGenerator.generateToken()

        guard let url = buildURL(
            for: location,
            dataSets: ["forecastHourly"]
        ) else {
            throw WeatherError.networkError("Invalid URL")
        }

        let request = NetworkRequest.get(
            url,
            headers: ["Authorization": "Bearer \(token)"]
        )

        let response: WeatherKitResponse = try await networkClient.perform(request)

        guard let hourly = response.forecastHourly else {
            throw WeatherError.invalidData
        }

        return mapHourlyForecast(hourly, hours: hours)
    }

    public func dailyForecast(
        for location: WeatherLocation,
        days: Int = 7
    ) async throws -> [DailyForecast] {
        let token = try tokenGenerator.generateToken()

        guard let url = buildURL(
            for: location,
            dataSets: ["forecastDaily"]
        ) else {
            throw WeatherError.networkError("Invalid URL")
        }

        let request = NetworkRequest.get(
            url,
            headers: ["Authorization": "Bearer \(token)"]
        )

        let response: WeatherKitResponse = try await networkClient.perform(request)

        guard let daily = response.forecastDaily else {
            throw WeatherError.invalidData
        }

        return mapDailyForecast(daily, days: days)
    }

    // MARK: - Private Helpers

    private func buildURL(
        for location: WeatherLocation,
        dataSets: [String]
    ) -> URL? {
        let urlString = "\(Self.baseURL)/\(locale)/\(location.latitude)/\(location.longitude)"
        guard var components = URLComponents(string: urlString) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "dataSets", value: dataSets.joined(separator: ","))
        ]

        return components.url
    }

    private func mapCurrentWeather(
        _ response: CurrentWeatherResponse,
        location: WeatherLocation
    ) -> CurrentWeather {
        CurrentWeather(
            location: location,
            temperature: Temperature(celsius: response.temperature),
            condition: response.conditionCode.toWeatherCondition,
            humidity: response.humidity,
            precipitationChance: response.precipitationIntensity ?? 0,
            timestamp: response.asOf.toDate ?? Date()
        )
    }

    private func mapHourlyForecast(
        _ response: HourlyForecastResponse,
        hours: Int
    ) -> [HourlyForecast] {
        response.hours.prefix(hours).compactMap { hour in
            guard let forecastDate = hour.forecastStart.toDate else {
                return nil
            }

            return HourlyForecast(
                hour: forecastDate,
                temperature: Temperature(celsius: hour.temperature),
                condition: hour.conditionCode.toWeatherCondition,
                precipitationChance: hour.precipitationChance
            )
        }
    }

    private func mapDailyForecast(
        _ response: DailyForecastResponse,
        days: Int
    ) -> [DailyForecast] {
        response.days.prefix(days).compactMap { day in
            guard let forecastDate = day.forecastStart.toDate else {
                return nil
            }

            return DailyForecast(
                date: forecastDate,
                highTemperature: Temperature(celsius: day.temperatureMax),
                lowTemperature: Temperature(celsius: day.temperatureMin),
                condition: day.conditionCode.toWeatherCondition,
                precipitationChance: day.precipitationChance
            )
        }
    }
}

// MARK: - Weather Service Provider

/// Service provider that registers the WeatherService.
/// Requires NetworkClient and SecretsProvider to be registered first.
///
/// To configure which service to use, register a `WeatherServiceType` before this provider runs:
/// ```
/// registry.register(WeatherServiceType.self) { _ in .weatherKit }
/// ```
/// If no type is registered, defaults to `.nws`.
public final class WeatherServiceProvider: ServiceProvider {

    /// Default service type when none is configured
    public static var defaultServiceType: WeatherServiceType = .nws

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(
            WeatherService.self,
            dependencies: (
                NetworkClient.self,
                SecretsProvider.self
            ),
            factory: { _, networkClient, secrets in
                // Check for configured service type, fallback to default
                let serviceType = Self.defaultServiceType

                switch serviceType {
                case .weatherKit:
                    let configuration = try! WeatherKitConfiguration(
                        teamID: secrets.secret(for: .weatherKitTeamID),
                        serviceID: secrets.secret(for: .weatherKitServiceID),
                        keyID: secrets.secret(for: .weatherKitKeyID),
                        privateKey: secrets.secret(for: .weatherKitPrivateKey)
                    )
                    return WeatherKitService(networkClient: networkClient, configuration: configuration)

                case .nws:
                    // Use secrets for user agent, fallback to default
                    let userAgent: String
                    if let secret = try? secrets.secret(for: .nwsUserAgent) {
                        userAgent = secret
                    } else {
                        userAgent = "GhostApp/1.0 (ghost@example.com)"
                    }
                    return NWSWeatherService(networkClient: networkClient, userAgent: userAgent)
                @unknown default:
                    fatalError("Must implement")
                }
            }
        )
    }
}
