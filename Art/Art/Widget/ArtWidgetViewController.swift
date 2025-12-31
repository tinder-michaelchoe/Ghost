//
//  ArtWidgetViewController.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import UIKit

// MARK: - Art Widget Container

/// Container view controller for the art widget.
/// Provides both front (framed artwork) and back (info + refresh) views.
final class ArtWidgetContainer: UIViewController, FlippableWidgetProviding {

    // MARK: - Properties

    private let artService: ArtSearching
    private let weatherService: WeatherService
    private let persistenceService: PersistenceService

    private lazy var _frontViewController: ArtWidgetFrontViewController = {
        ArtWidgetFrontViewController(
            artService: artService,
            weatherService: weatherService,
            persistenceService: persistenceService
        )
    }()

    private lazy var _backViewController: ArtWidgetBackViewController = {
        let backVC = ArtWidgetBackViewController()
        backVC.delegate = _frontViewController
        _frontViewController.backViewController = backVC
        return backVC
    }()

    // MARK: - FlippableWidgetProviding

    var frontViewController: UIViewController { _frontViewController }
    var backViewController: UIViewController? { _backViewController }

    // MARK: - Init

    init(
        artService: ArtSearching,
        weatherService: WeatherService,
        persistenceService: PersistenceService
    ) {
        self.artService = artService
        self.weatherService = weatherService
        self.persistenceService = persistenceService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
}

// MARK: - Art Widget Front View Controller

final class ArtWidgetFrontViewController: UIViewController, RefreshableWidget {

    // MARK: - Properties

    private let artService: ArtSearching
    private let weatherService: WeatherService
    private let persistenceService: PersistenceService

    private var currentResult: ArtSearchResult?
    weak var backViewController: ArtWidgetBackViewController?

    // MARK: - UI Components

    private let frameImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "goldFrame", in: Bundle(for: ArtWidgetFrontViewController.self), with: nil)
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .secondaryLabel
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let errorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let errorIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo.artframe")
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Unable to load art"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    init(
        artService: ArtSearching,
        weatherService: WeatherService,
        persistenceService: PersistenceService
    ) {
        self.artService = artService
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
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Defer loading to avoid layout changes during initial collection view layout
        if artworkImageView.image == nil && !loadingIndicator.isAnimating {
            loadArtwork()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Add artwork behind the frame
        view.addSubview(artworkImageView)
        view.addSubview(frameImageView)
        view.addSubview(loadingIndicator)

        // Error state
        errorStackView.addArrangedSubview(errorIconView)
        errorStackView.addArrangedSubview(errorLabel)
        view.addSubview(errorStackView)

        // Frame fills the view
        NSLayoutConstraint.activate([
            frameImageView.topAnchor.constraint(equalTo: view.topAnchor),
            frameImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Artwork is inset from the frame edges
            // Adjust these values based on the actual frame asset
            artworkImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            artworkImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            artworkImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            artworkImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorIconView.widthAnchor.constraint(equalToConstant: 40),
            errorIconView.heightAnchor.constraint(equalToConstant: 40),

            errorStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - RefreshableWidget

    func refreshContent() {
        print("[ArtWidget] refreshContent called")
        loadArtwork()
    }

    // MARK: - Data Loading

    func loadArtwork() {
        loadingIndicator.startAnimating()
        errorStackView.isHidden = true
        artworkImageView.image = nil

        print("[ArtWidget] Starting to load artwork...")

        Task {
            do {
                // Get current weather
                let location = WeatherLocations.selectedLocation(from: persistenceService)
                print("[ArtWidget] Getting weather for: \(location.name ?? "unknown")")

                let weather = try await weatherService.currentWeather(for: location)
                print("[ArtWidget] Weather condition: \(weather.condition)")

                // Search for art based on weather
                let result: ArtSearchResult
                do {
                    print("[ArtWidget] Searching art for condition: \(weather.condition)")
                    result = try await artService.searchArt(for: weather.condition)
                } catch ArtError.noArtworkFound {
                    // Fall back to art of the day
                    print("[ArtWidget] No weather art found, trying art of the day...")
                    result = try await artService.searchArtOfTheDay()
                }

                print("[ArtWidget] Found artwork: '\(result.artwork.title)' for keyword '\(result.keyword)'")

                // Fetch the image
                print("[ArtWidget] Fetching image...")
                let image = try await artService.fetchImage(for: result.artwork)

                await MainActor.run {
                    print("[ArtWidget] Displaying artwork")
                    self.currentResult = result
                    self.artworkImageView.image = image
                    self.loadingIndicator.stopAnimating()
                    self.backViewController?.update(with: result)
                }
            } catch {
                print("[ArtWidget] Error loading artwork: \(error)")
                await MainActor.run {
                    self.showError()
                }
            }
        }
    }

    private func showError() {
        loadingIndicator.stopAnimating()
        artworkImageView.image = nil
        errorStackView.isHidden = false
    }
}

// MARK: - Art Widget Back View Controller

protocol ArtWidgetBackViewControllerDelegate: AnyObject {
    func loadArtwork()
}

final class ArtWidgetBackViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: ArtWidgetBackViewControllerDelegate?
    private var currentResult: ArtSearchResult?

    // MARK: - UI Components

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let keywordLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var refreshButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "New Artwork"
        config.image = UIImage(systemName: "arrow.clockwise")
        config.imagePadding = 6
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGray6

        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(artistLabel)
        containerStack.addArrangedSubview(keywordLabel)

        // Add spacing before button
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        containerStack.addArrangedSubview(spacer)
        containerStack.addArrangedSubview(refreshButton)

        view.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            spacer.heightAnchor.constraint(equalToConstant: 8),

            refreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Update

    func update(with result: ArtSearchResult) {
        currentResult = result
        titleLabel.text = result.artwork.title
        artistLabel.text = result.artwork.artist
        keywordLabel.text = "Inspired by: \(result.keyword)"
    }

    // MARK: - Actions

    @objc private func refreshTapped() {
        delegate?.loadArtwork()
    }
}

// MARK: - Delegate Conformance

extension ArtWidgetFrontViewController: ArtWidgetBackViewControllerDelegate {}

// MARK: - Weather Locations Access

// Import the WeatherLocations from the Weather module
// For now, we duplicate the minimal logic needed
private enum WeatherLocations {
    static let available: [WeatherLocation] = [
        WeatherLocation(latitude: 40.7128, longitude: -74.0060, name: "New York"),
        WeatherLocation(latitude: 34.0522, longitude: -118.2437, name: "Los Angeles"),
        WeatherLocation(latitude: 41.8781, longitude: -87.6298, name: "Chicago")
    ]

    static func selectedLocation(from persistence: PersistenceService) -> WeatherLocation {
        let index = persistence.get(.weatherSelectedLocationIndex)
        guard index >= 0, index < available.count else {
            return available[0]
        }
        return available[index]
    }
}

private extension PersistenceKey where Value == Int {
    static let weatherSelectedLocationIndex = PersistenceKey(
        "weather.selectedLocationIndex",
        default: 0
    )
}
