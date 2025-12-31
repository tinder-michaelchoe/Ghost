//
//  WeatherWidgetViewController.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather Widget Container

/// Container view controller for the weather widget.
/// Provides both front (weather display) and back (city picker) views
/// for the flippable dashboard widget.
final class WeatherWidgetContainer: UIViewController, CoordinatedWidgetProviding {

    // MARK: - Properties

    private let weatherService: WeatherService
    private let persistenceService: PersistenceService
    private let locationService: LocationService

    private lazy var _frontViewController: WeatherWidgetFrontViewController = {
        WeatherWidgetFrontViewController(
            weatherService: weatherService,
            persistenceService: persistenceService
        )
    }()

    private lazy var _backViewController: WeatherCityPickerViewController = {
        let picker = WeatherCityPickerViewController(
            persistenceService: persistenceService,
            locationService: locationService
        )
        picker.delegate = self
        return picker
    }()

    // MARK: - FlippableWidgetProviding

    var frontViewController: UIViewController { _frontViewController }
    var backViewController: UIViewController? { _backViewController }

    // MARK: - CoordinatedWidgetProviding

    weak var coordinator: WidgetCoordinator?
    var widgetId: String { "weather" }

    // MARK: - Init

    init(
        weatherService: WeatherService,
        persistenceService: PersistenceService,
        locationService: LocationService
    ) {
        self.weatherService = weatherService
        self.persistenceService = persistenceService
        self.locationService = locationService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // The container just holds references; actual display is handled by Dashboard
        view.backgroundColor = .clear
    }
}

// MARK: - WeatherCityPickerDelegate

extension WeatherWidgetContainer: WeatherCityPickerDelegate {
    func cityPickerDidChangeCity() {
        print("[WeatherWidget] cityPickerDidChangeCity called")
        // Refresh our own front view
        _frontViewController.refreshContent()
        // Notify the coordinator so other widgets can refresh
        print("[WeatherWidget] coordinator is \(coordinator == nil ? "nil" : "set")")
        coordinator?.widgetDidChangeSettings(widgetId: widgetId)
    }
}

// MARK: - Weather Widget Front View Controller

final class WeatherWidgetFrontViewController: UIViewController, RefreshableWidget {

    // MARK: - Properties

    private let weatherService: WeatherService
    private let persistenceService: PersistenceService
    private var currentLocation: WeatherLocation?

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

    init(weatherService: WeatherService, persistenceService: PersistenceService) {
        self.weatherService = weatherService
        self.persistenceService = persistenceService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupUI()
        loadWeather()
    }

    // MARK: - Setup

    private func setupLocation() {
        currentLocation = WeatherLocations.selectedLocation(from: persistenceService)
    }

    // MARK: - RefreshableWidget

    func refreshContent() {
        print("[WeatherWidget] refreshContent called")
        currentLocation = WeatherLocations.selectedLocation(from: persistenceService)
        print("[WeatherWidget] New location: \(currentLocation?.name ?? "nil")")
        loadWeather()
    }

    private func setupUI() {
        view.backgroundColor = .systemGray6

        // Top section: date and location (full width)
        let headerStack = UIStackView(arrangedSubviews: [dateLabel, locationLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 2
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Temperature section with icon
        let tempStack = UIStackView(arrangedSubviews: [conditionIcon, temperatureLabel])
        tempStack.axis = .horizontal
        tempStack.spacing = 4
        tempStack.alignment = .center
        tempStack.translatesAutoresizingMaskIntoConstraints = false

        // Left column: temp + high/low
        let leftColumn = UIStackView(arrangedSubviews: [tempStack, highLowLabel])
        leftColumn.axis = .vertical
        leftColumn.spacing = 2
        leftColumn.alignment = .leading
        leftColumn.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(leftColumn)
        view.addSubview(forecastStackView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Header at top, spanning full width
            headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            // Left column (temp + high/low) below header
            leftColumn.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            leftColumn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            conditionIcon.widthAnchor.constraint(equalToConstant: 28),
            conditionIcon.heightAnchor.constraint(equalToConstant: 28),

            // Forecast aligned with top of temperature, 22px gap from left column
            forecastStackView.topAnchor.constraint(equalTo: tempStack.topAnchor),
            forecastStackView.leadingAnchor.constraint(equalTo: leftColumn.trailingAnchor, constant: 22),
            forecastStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Create 5 day forecast views
        for _ in 0..<5 {
            let dayView = DayForecastView()
            forecastStackView.addArrangedSubview(dayView)
        }
    }

    // MARK: - Data Loading

    private func loadWeather() {
        guard let location = currentLocation else { return }

        loadingIndicator.startAnimating()

        Task {
            do {
                async let currentWeather = weatherService.currentWeather(for: location)
                async let forecast = weatherService.dailyForecast(for: location, days: 5)

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
