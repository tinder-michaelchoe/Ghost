//
//  WeatherTests.swift
//  WeatherTests
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation
import Testing
import CoreContracts
import TestHarness
@testable import Weather

// MARK: - Mock Network Client

/// A mock NetworkClient that returns predefined responses
final class MockNetworkClient: NetworkClient, @unchecked Sendable {

    var responses: [URL: Any] = [:]
    var rawResponses: [URL: (Data, URLResponse)] = [:]
    var requestsMade: [NetworkRequest] = []
    var shouldFail: Bool = false
    var error: Error = NetworkError.noConnection

    func perform<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T {
        requestsMade.append(request)

        if shouldFail {
            throw error
        }

        guard let response = responses[request.url] as? T else {
            throw NetworkError.noData
        }

        return response
    }

    func performRaw(_ request: NetworkRequest) async throws -> (Data, URLResponse) {
        requestsMade.append(request)

        if shouldFail {
            throw error
        }

        guard let response = rawResponses[request.url] else {
            throw NetworkError.noData
        }

        return response
    }
}

// MARK: - Mock Secrets Provider

/// A mock SecretsProvider with configurable secrets
final class MockSecretsProvider: SecretsProvider, @unchecked Sendable {

    var secrets: [SecretKey: String] = [:]

    init(secrets: [SecretKey: String] = [:]) {
        self.secrets = secrets
    }

    func secret(for key: SecretKey) throws -> String {
        guard let value = secrets[key] else {
            throw SecretsError.missingSecret(key)
        }
        return value
    }

    /// Creates a mock with NWS user agent configured
    static func withNWSDefaults() -> MockSecretsProvider {
        MockSecretsProvider(secrets: [
            .nwsUserAgent: "TestApp/1.0 (test@example.com)"
        ])
    }

    /// Creates a mock with WeatherKit secrets configured
    static func withWeatherKitDefaults() -> MockSecretsProvider {
        MockSecretsProvider(secrets: [
            .weatherKitTeamID: "TEST_TEAM",
            .weatherKitServiceID: "com.test.weatherkit",
            .weatherKitKeyID: "TEST_KEY",
            .weatherKitPrivateKey: "TEST_PRIVATE_KEY"
        ])
    }
}

// MARK: - Test Runtime Tests

@Suite("WeatherService with TestRuntime")
struct WeatherServiceRuntimeTests {

    @Test("Resolves WeatherService with mock dependencies")
    func resolvesWithMocks() async throws {
        let runtime = TestRuntime()

        // Register mock dependencies
        runtime.registerMock(NetworkClient.self, mock: MockNetworkClient())
        runtime.registerMock(SecretsProvider.self, mock: MockSecretsProvider.withNWSDefaults())

        // Register the service under test
        runtime.register(provider: WeatherServiceProvider())

        // Resolve - should work without errors
        let weatherService = try runtime.resolve(WeatherService.self)
        #expect(weatherService != nil)
    }

    @Test("Fails with clear error when NetworkClient is missing")
    func failsWhenNetworkClientMissing() async throws {
        let runtime = TestRuntime()

        // Only register SecretsProvider, forget NetworkClient
        runtime.registerMock(SecretsProvider.self, mock: MockSecretsProvider.withNWSDefaults())

        // Register the service under test
        runtime.register(provider: WeatherServiceProvider())

        // Should throw with clear error message
        do {
            _ = try runtime.resolve(WeatherService.self)
            Issue.record("Expected resolution to fail")
        } catch let error as TestRuntimeError {
            let description = error.description
            #expect(description.contains("NetworkClient"))
            #expect(description.contains("Did you forget to register a mock"))
        }
    }

    @Test("Fails with clear error when SecretsProvider is missing")
    func failsWhenSecretsProviderMissing() async throws {
        let runtime = TestRuntime()

        // Only register NetworkClient, forget SecretsProvider
        runtime.registerMock(NetworkClient.self, mock: MockNetworkClient())

        // Register the service under test
        runtime.register(provider: WeatherServiceProvider())

        // Should throw with clear error message
        do {
            _ = try runtime.resolve(WeatherService.self)
            Issue.record("Expected resolution to fail")
        } catch let error as TestRuntimeError {
            let description = error.description
            #expect(description.contains("SecretsProvider"))
        }
    }

    @Test("Validation detects missing dependencies before resolution")
    func validationDetectsMissingDeps() async throws {
        let runtime = TestRuntime()

        // Register nothing, just the service
        runtime.register(provider: WeatherServiceProvider())

        let errors = runtime.validate()
        #expect(errors.count == 2) // Missing NetworkClient and SecretsProvider

        let missingTypes = errors.compactMap { error -> String? in
            if case .missingDependency(_, let missing) = error {
                return missing
            }
            return nil
        }

        #expect(missingTypes.contains { $0.contains("NetworkClient") })
        #expect(missingTypes.contains { $0.contains("SecretsProvider") })
    }
}

// MARK: - NWS Weather Service Behavior Tests

@Suite("NWSWeatherService Behavior")
struct NWSWeatherServiceTests {

    let testLocation = WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York")

    // MARK: - Current Weather Tests

    @Test("currentWeather returns weather from first hourly forecast")
    func currentWeatherReturnsFirstHour() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        // Mock points response
        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        // Mock hourly forecast response
        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        let hourlyResponse = makeHourlyForecastResponse(periods: [
            makeForecastPeriod(temperature: 72, shortForecast: "Sunny", precipChance: 0.10)
        ])
        mockNetwork.responses[hourlyURL] = hourlyResponse

        let weather = try await service.currentWeather(for: testLocation)

        #expect(weather.temperature.fahrenheit == 72)
        #expect(weather.condition == .clear)
        #expect(weather.precipitationChance == 0.1)
    }

    @Test("currentWeather throws when no forecast data")
    func currentWeatherThrowsOnEmpty() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        let emptyResponse = makeHourlyForecastResponse(periods: [])
        mockNetwork.responses[hourlyURL] = emptyResponse

        do {
            _ = try await service.currentWeather(for: testLocation)
            Issue.record("Expected WeatherError.invalidData")
        } catch let error as WeatherError {
            if case .invalidData = error {
                // Expected
            } else {
                Issue.record("Expected .invalidData but got \(error)")
            }
        }
    }

    // MARK: - Hourly Forecast Tests

    @Test("hourlyForecast returns correct number of hours")
    func hourlyForecastReturnsRequestedHours() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        let periods = (0..<48).map { i in
            makeForecastPeriod(
                number: i + 1,
                temperature: 70 + i,
                shortForecast: "Clear",
                hoursFromNow: i
            )
        }
        mockNetwork.responses[hourlyURL] = makeHourlyForecastResponse(periods: periods)

        let forecast = try await service.hourlyForecast(for: testLocation, hours: 12)

        #expect(forecast.count == 12)
        #expect(forecast[0].temperature.fahrenheit == 70)
        #expect(forecast[11].temperature.fahrenheit == 81)
    }

    @Test("hourlyForecast parses temperature correctly")
    func hourlyForecastParsesTemperature() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        mockNetwork.responses[hourlyURL] = makeHourlyForecastResponse(periods: [
            makeForecastPeriod(temperature: 32, shortForecast: "Snow")
        ])

        let forecast = try await service.hourlyForecast(for: testLocation, hours: 1)

        #expect(forecast.count == 1)
        #expect(forecast[0].temperature.fahrenheit == 32)
        #expect(forecast[0].temperature.celsius == 0)
    }

    @Test("hourlyForecast maps weather conditions correctly")
    func hourlyForecastMapsConditions() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        mockNetwork.responses[hourlyURL] = makeHourlyForecastResponse(periods: [
            makeForecastPeriod(number: 1, temperature: 75, shortForecast: "Thunderstorms", hoursFromNow: 0),
            makeForecastPeriod(number: 2, temperature: 70, shortForecast: "Heavy Rain", hoursFromNow: 1),
            makeForecastPeriod(number: 3, temperature: 65, shortForecast: "Partly Cloudy", hoursFromNow: 2),
            makeForecastPeriod(number: 4, temperature: 30, shortForecast: "Snow Showers", hoursFromNow: 3),
        ])

        let forecast = try await service.hourlyForecast(for: testLocation, hours: 4)

        #expect(forecast[0].condition == .thunderstorm)
        #expect(forecast[1].condition == .heavyRain)
        #expect(forecast[2].condition == .partlyCloudy)
        #expect(forecast[3].condition == .snow)
    }

    // MARK: - Network Error Tests

    @Test("throws network error when API fails")
    func throwsOnNetworkError() async throws {
        let mockNetwork = MockNetworkClient()
        mockNetwork.shouldFail = true
        mockNetwork.error = NetworkError.noConnection

        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        do {
            _ = try await service.currentWeather(for: testLocation)
            Issue.record("Expected NetworkError")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test("caches grid info to avoid repeated points calls")
    func cachesGridInfo() async throws {
        let mockNetwork = MockNetworkClient()
        let service = NWSWeatherService(networkClient: mockNetwork, userAgent: "Test/1.0")

        setupPointsResponse(on: mockNetwork, lat: 40.7128, lon: -74.006)

        let hourlyURL = URL(string: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly")!
        mockNetwork.responses[hourlyURL] = makeHourlyForecastResponse(periods: [
            makeForecastPeriod(temperature: 72, shortForecast: "Sunny")
        ])

        // First call
        _ = try await service.hourlyForecast(for: testLocation, hours: 1)
        let firstCallCount = mockNetwork.requestsMade.count

        // Second call - should use cached grid info
        _ = try await service.hourlyForecast(for: testLocation, hours: 1)
        let secondCallCount = mockNetwork.requestsMade.count

        // First call: 1 points + 1 hourly = 2 requests
        // Second call: 0 points (cached) + 1 hourly = 1 request
        #expect(firstCallCount == 2)
        #expect(secondCallCount == 3) // Only 1 additional request
    }

    // MARK: - Test Helpers

    private func setupPointsResponse(on mockNetwork: MockNetworkClient, lat: Double, lon: Double) {
        let pointsURL = URL(string: "https://api.weather.gov/points/\(lat),\(lon)")!
        let pointsResponse = NWSPointsResponse(
            properties: NWSPointsProperties(
                gridId: "OKX",
                gridX: 33,
                gridY: 37,
                forecast: "https://api.weather.gov/gridpoints/OKX/33,37/forecast",
                forecastHourly: "https://api.weather.gov/gridpoints/OKX/33,37/forecast/hourly",
                forecastGridData: "https://api.weather.gov/gridpoints/OKX/33,37",
                relativeLocation: nil,
                timeZone: "America/New_York"
            )
        )
        mockNetwork.responses[pointsURL] = pointsResponse
    }

    private func makeHourlyForecastResponse(periods: [NWSForecastPeriod]) -> NWSHourlyForecastResponse {
        NWSHourlyForecastResponse(
            properties: NWSForecastProperties(
                units: "us",
                updateTime: ISO8601DateFormatter().string(from: Date()),
                periods: periods
            )
        )
    }

    private func makeForecastPeriod(
        number: Int = 1,
        temperature: Int,
        shortForecast: String,
        precipChance: Double = 0,
        hoursFromNow: Int = 0
    ) -> NWSForecastPeriod {
        let date = Calendar.current.date(byAdding: .hour, value: hoursFromNow, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: date)

        return NWSForecastPeriod(
            number: number,
            startTime: dateString,
            endTime: dateString,
            isDaytime: true,
            temperature: temperature,
            temperatureUnit: "F",
            windSpeed: "5 mph",
            windDirection: "N",
            shortForecast: shortForecast,
            detailedForecast: nil,
            probabilityOfPrecipitation: NWSQuantitativeValue(unitCode: "wmoUnit:percent", value: precipChance * 100),
            relativeHumidity: nil,
            dewpoint: nil
        )
    }
}

// MARK: - Direct Construction Tests (No Runtime)

@Suite("WeatherService Direct Construction")
struct WeatherServiceDirectTests {

    let testLocation = WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York")

    @Test("NWSWeatherService can be constructed directly with mocks")
    func directConstruction() async throws {
        // For pure unit tests, you can bypass the runtime entirely
        let mockNetwork = MockNetworkClient()

        let service = NWSWeatherService(
            networkClient: mockNetwork,
            userAgent: "DirectTest/1.0"
        )

        // Set up minimal mock response
        mockNetwork.shouldFail = true
        mockNetwork.error = NetworkError.noConnection

        // Test behavior
        do {
            _ = try await service.currentWeather(for: testLocation)
            Issue.record("Expected network error")
        } catch {
            // Expected - network is mocked to fail
            #expect(error is NetworkError)
        }
    }
}
