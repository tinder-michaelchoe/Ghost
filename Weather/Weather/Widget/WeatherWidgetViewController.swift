//
//  WeatherWidgetViewController.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather Widget View Controller

final class WeatherWidgetViewController: UIViewController {

    // MARK: - Properties

    private let context: AppContext
    private var weatherService: WeatherService?
    private var currentLocation: WeatherLocation = WeatherLocationStore.shared.selectedLocation

    // MARK: - UI Components

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let conditionIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .light)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let highLowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let forecastStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Init

    init(context: AppContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
        loadWeather()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGray6

        // Left side: date, location, temp
        let leftStack = UIStackView(arrangedSubviews: [dateLabel, locationLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        let tempStack = UIStackView(arrangedSubviews: [conditionIcon, temperatureLabel])
        tempStack.axis = .horizontal
        tempStack.spacing = 4
        tempStack.alignment = .center
        tempStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(leftStack)
        view.addSubview(tempStack)
        view.addSubview(highLowLabel)
        view.addSubview(forecastStackView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            leftStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            leftStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            tempStack.topAnchor.constraint(equalTo: leftStack.bottomAnchor, constant: 4),
            tempStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            conditionIcon.widthAnchor.constraint(equalToConstant: 28),
            conditionIcon.heightAnchor.constraint(equalToConstant: 28),

            highLowLabel.topAnchor.constraint(equalTo: tempStack.bottomAnchor, constant: 2),
            highLowLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            forecastStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            forecastStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            forecastStackView.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 16),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Create 5 day forecast views
        for _ in 0..<5 {
            let dayView = DayForecastView()
            forecastStackView.addArrangedSubview(dayView)
        }
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidChange),
            name: WeatherLocationStore.locationDidChangeNotification,
            object: nil
        )
    }

    @objc private func locationDidChange() {
        currentLocation = WeatherLocationStore.shared.selectedLocation
        loadWeather()
    }

    // MARK: - Data Loading

    private func loadWeather() {
        loadingIndicator.startAnimating()

        Task {
            do {
                guard let service = context.services.resolve(WeatherService.self) else {
                    throw WeatherError.serviceUnavailable
                }
                self.weatherService = service

                async let currentWeather = service.currentWeather(for: currentLocation)
                async let forecast = service.dailyForecast(for: currentLocation, days: 5)

                let (weather, dailyForecast) = try await (currentWeather, forecast)

                await MainActor.run {
                    updateUI(with: weather, forecast: dailyForecast)
                    loadingIndicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    showError()
                }
            }
        }
    }

    private func updateUI(with weather: CurrentWeather, forecast: [DailyForecast]) {
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        dateLabel.text = dateFormatter.string(from: Date())

        // Location
        locationLabel.text = weather.location.name ?? "Unknown"

        // Condition icon
        conditionIcon.image = UIImage(systemName: weather.condition.systemImageName)
        conditionIcon.tintColor = iconColor(for: weather.condition)

        // Temperature
        temperatureLabel.text = weather.temperature.formatted(unit: .fahrenheit)

        // High/Low from today's forecast
        if let today = forecast.first {
            highLowLabel.text = "H:\(today.highTemperature.formatted(unit: .fahrenheit)) L:\(today.lowTemperature.formatted(unit: .fahrenheit))"
        }

        // 5 day forecast
        let forecastViews = forecastStackView.arrangedSubviews.compactMap { $0 as? DayForecastView }
        for (index, day) in forecast.prefix(5).enumerated() {
            guard index < forecastViews.count else { break }
            forecastViews[index].configure(with: day)
        }
    }

    private func showError() {
        dateLabel.text = "--"
        locationLabel.text = "Unable to load"
        temperatureLabel.text = "--°"
        highLowLabel.text = ""
    }

    private func iconColor(for condition: WeatherCondition) -> UIColor {
        switch condition {
        case .clear: return .systemOrange
        case .partlyCloudy: return .systemYellow
        case .cloudy, .fog: return .systemGray
        case .rain, .heavyRain: return .systemBlue
        case .thunderstorm: return .systemPurple
        case .snow, .sleet: return .systemCyan
        case .windy: return .systemTeal
        }
    }
}

// MARK: - Day Forecast View

private final class DayForecastView: UIView {

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(dayLabel)
        addSubview(iconView)
        addSubview(tempLabel)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: topAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            iconView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 2),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            tempLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
            tempLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tempLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(with forecast: DailyForecast) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        dayLabel.text = dateFormatter.string(from: forecast.date)

        iconView.image = UIImage(systemName: forecast.condition.systemImageName)
        iconView.tintColor = .secondaryLabel

        tempLabel.text = String(format: "%.0f°", forecast.highTemperature.fahrenheit)
    }
}
