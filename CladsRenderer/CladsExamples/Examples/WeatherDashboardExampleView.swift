//
//  WeatherDashboardExampleView.swift
//  CladsExamples
//
//  Example demonstrating real weather data integration with CLADS.
//  Uses onAppear lifecycle action to trigger data fetch and update state.
//

import CLADS
import CladsModules
import CoreContracts
import SwiftUI

// MARK: - Weather Dashboard Example View

/// Example demonstrating:
/// - Real weather data from WeatherService
/// - onAppear lifecycle action to trigger async data fetch
/// - State updates from async service calls
/// - Loading states and data binding
public struct WeatherDashboardExampleView: View {
    @Environment(\.dismiss) private var dismiss

    private let weatherService: WeatherService

    public init(weatherService: WeatherService) {
        self.weatherService = weatherService
    }

    public var body: some View {
        if let document = try? Document.Definition(jsonString: weatherDashboardJSON) {
            CladsRendererView(
                document: document,
                customActions: [
                    "fetchWeather": { [weatherService] params, context in
                        await fetchWeather(service: weatherService, context: context)
                    }
                ]
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Failed to parse Weather JSON")
                    .foregroundStyle(.secondary)
                Button("Dismiss") { dismiss() }
            }
        }
    }
}

// MARK: - Fetch Weather

// MARK: - Cities

// NWS API only works for US locations
private let cities = [
    WeatherLocation(latitude: 37.7749, longitude: -122.4194, name: "San Francisco"),
    WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York"),
    WeatherLocation(latitude: 34.0522, longitude: -118.2437, name: "Los Angeles"),
    WeatherLocation(latitude: 41.8781, longitude: -87.6298, name: "Chicago"),
    WeatherLocation(latitude: 29.7604, longitude: -95.3698, name: "Houston")
]

@MainActor
private func fetchWeather(service: WeatherService, context: ActionExecutionContext) async {
    // Set loading state
    context.stateStore.set("isLoading", value: true)

    // Randomly select a city
    let location = cities.randomElement() ?? cities[0]

    do {
        // Fetch current weather
        let current = try await service.currentWeather(for: location)

        // Update date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        context.stateStore.set("currentDate", value: dateFormatter.string(from: Date()))

        // Update state with real data
        let temp = Int(current.temperature.fahrenheit)
        context.stateStore.set("location", value: location.name ?? "Unknown")
        context.stateStore.set("temperature", value: temp)
        context.stateStore.set("feelsLike", value: temp - 4)
        context.stateStore.set("humidity", value: Int(current.humidity * 100))
        context.stateStore.set("condition", value: current.condition.displayName)

        // Fetch real hourly forecast
        let hourlyForecast = try await service.hourlyForecast(for: location, hours: 6)
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "h a"

        for (index, hour) in hourlyForecast.prefix(6).enumerated() {
            let hourTemp = Int(hour.temperature.fahrenheit)
            context.stateStore.set("hour\(index)Temp", value: "\(hourTemp)°")
            if index == 0 {
                context.stateStore.set("hour0Label", value: "Now")
            } else {
                context.stateStore.set("hour\(index)Label", value: hourFormatter.string(from: hour.hour))
            }
        }

        // Fetch real daily forecast
        let dailyForecast = try await service.dailyForecast(for: location, days: 5)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for (index, day) in dailyForecast.prefix(5).enumerated() {
            let high = Int(day.highTemperature.fahrenheit)
            let low = Int(day.lowTemperature.fahrenheit)
            context.stateStore.set("day\(index)High", value: "\(high)°")
            context.stateStore.set("day\(index)Low", value: " / \(low)°")
            if index == 0 {
                context.stateStore.set("day0Label", value: "Today")
            } else {
                context.stateStore.set("day\(index)Label", value: dayFormatter.string(from: day.date))
            }
        }

        // Placeholder values for wind/UV
        context.stateStore.set("windSpeed", value: Int.random(in: 5...20))
        context.stateStore.set("uvIndex", value: Int.random(in: 3...9))

    } catch {
        print("WeatherDashboardExampleView: Failed to fetch weather: \(error)")

        // Fall back to placeholder data on error
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let temp = 72
        context.stateStore.set("currentDate", value: dateFormatter.string(from: Date()))
        context.stateStore.set("location", value: location.name ?? "Unknown")
        context.stateStore.set("temperature", value: temp)
        context.stateStore.set("feelsLike", value: temp - 4)
        context.stateStore.set("humidity", value: 65)
        context.stateStore.set("condition", value: "Unable to fetch")
        context.stateStore.set("windSpeed", value: 12)
        context.stateStore.set("uvIndex", value: 6)

        // Hourly fallback
        context.stateStore.set("hour0Label", value: "Now")
        context.stateStore.set("hour0Temp", value: "\(temp)°")
        context.stateStore.set("hour1Label", value: "1 PM")
        context.stateStore.set("hour1Temp", value: "\(temp + 2)°")
        context.stateStore.set("hour2Label", value: "2 PM")
        context.stateStore.set("hour2Temp", value: "\(temp + 1)°")
        context.stateStore.set("hour3Label", value: "3 PM")
        context.stateStore.set("hour3Temp", value: "\(temp - 1)°")
        context.stateStore.set("hour4Label", value: "4 PM")
        context.stateStore.set("hour4Temp", value: "\(temp - 2)°")
        context.stateStore.set("hour5Label", value: "5 PM")
        context.stateStore.set("hour5Temp", value: "\(temp - 4)°")

        // Daily fallback
        context.stateStore.set("day0Label", value: "Today")
        context.stateStore.set("day0High", value: "\(temp + 4)°")
        context.stateStore.set("day0Low", value: " / \(temp - 14)°")
        context.stateStore.set("day1Label", value: "Mon")
        context.stateStore.set("day1High", value: "\(temp + 2)°")
        context.stateStore.set("day1Low", value: " / \(temp - 16)°")
        context.stateStore.set("day2Label", value: "Tue")
        context.stateStore.set("day2High", value: "\(temp - 4)°")
        context.stateStore.set("day2Low", value: " / \(temp - 20)°")
        context.stateStore.set("day3Label", value: "Wed")
        context.stateStore.set("day3High", value: "\(temp - 7)°")
        context.stateStore.set("day3Low", value: " / \(temp - 22)°")
        context.stateStore.set("day4Label", value: "Thu")
        context.stateStore.set("day4High", value: "\(temp - 2)°")
        context.stateStore.set("day4Low", value: " / \(temp - 18)°")
    }

    context.stateStore.set("isLoading", value: false)
}
