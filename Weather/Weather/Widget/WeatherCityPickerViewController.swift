//
//  WeatherCityPickerViewController.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather City Picker Delegate

protocol WeatherCityPickerDelegate: AnyObject {
    func cityPickerDidChangeCity()
}

// MARK: - Weather City Picker View Controller

final class WeatherCityPickerViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: WeatherCityPickerDelegate?
    private let persistenceService: PersistenceService
    private let locationService: LocationService
    private let locations = WeatherLocations.available

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Current location display at top
    private let currentLocationContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let currentLocationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let currentLocationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Location input row: [location button] [zip field] [go button]
    private let inputRowContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var currentLocationButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "location.fill")
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(currentLocationTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let zipCodeField: UITextField = {
        let field = UITextField()
        field.placeholder = "Zip Code"
        field.borderStyle = .roundedRect
        field.keyboardType = .numberPad
        field.font = .systemFont(ofSize: 14)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var zipCodeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Go"
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(zipCodeGoTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 2
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let presetsLabel: UILabel = {
        let label = UILabel()
        label.text = "Presets"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let presetsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
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

    init(persistenceService: PersistenceService, locationService: LocationService) {
        self.persistenceService = persistenceService
        self.locationService = locationService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismissal()
        updateCurrentLocationDisplay()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(loadingIndicator)

        // Current location display
        currentLocationContainer.addSubview(currentLocationIcon)
        currentLocationContainer.addSubview(currentLocationLabel)

        NSLayoutConstraint.activate([
            currentLocationIcon.leadingAnchor.constraint(equalTo: currentLocationContainer.leadingAnchor, constant: 8),
            currentLocationIcon.centerYAnchor.constraint(equalTo: currentLocationContainer.centerYAnchor),
            currentLocationIcon.widthAnchor.constraint(equalToConstant: 18),
            currentLocationIcon.heightAnchor.constraint(equalToConstant: 18),

            currentLocationLabel.leadingAnchor.constraint(equalTo: currentLocationIcon.trailingAnchor, constant: 6),
            currentLocationLabel.trailingAnchor.constraint(equalTo: currentLocationContainer.trailingAnchor, constant: -8),
            currentLocationLabel.topAnchor.constraint(equalTo: currentLocationContainer.topAnchor, constant: 8),
            currentLocationLabel.bottomAnchor.constraint(equalTo: currentLocationContainer.bottomAnchor, constant: -8)
        ])

        // Build input row: [location] [zip field] [go]
        inputRowContainer.addArrangedSubview(currentLocationButton)
        inputRowContainer.addArrangedSubview(zipCodeField)
        inputRowContainer.addArrangedSubview(zipCodeButton)

        // Build content stack
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(currentLocationContainer)
        contentStack.addArrangedSubview(inputRowContainer)
        contentStack.addArrangedSubview(statusLabel)
        contentStack.addArrangedSubview(dividerView)
        contentStack.addArrangedSubview(presetsLabel)
        contentStack.addArrangedSubview(presetsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24),

            dividerView.heightAnchor.constraint(equalToConstant: 1),

            currentLocationButton.widthAnchor.constraint(equalToConstant: 36),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 36),

            zipCodeField.heightAnchor.constraint(equalToConstant: 36),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Create preset city buttons
        let selectedIndex = WeatherLocations.selectedIndex(from: persistenceService)

        for (index, location) in locations.enumerated() {
            let button = createCityButton(
                name: location.name ?? "Unknown",
                isSelected: index == selectedIndex,
                tag: index
            )
            presetsStack.addArrangedSubview(button)
        }
    }

    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        zipCodeField.delegate = self
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func createCityButton(name: String, isSelected: Bool, tag: Int) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = name
        config.baseForegroundColor = isSelected ? .systemBlue : .label
        config.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        let button = UIButton(configuration: config)
        button.tag = tag
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(cityTapped(_:)), for: .touchUpInside)

        return button
    }

    private func updatePresetButtonStates(selectedIndex: Int) {
        for case let button as UIButton in presetsStack.arrangedSubviews {
            let isSelected = button.tag == selectedIndex
            var config = button.configuration
            config?.baseForegroundColor = isSelected ? .systemBlue : .label
            config?.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
            button.configuration = config
        }
    }

    private func updateCurrentLocationDisplay() {
        let selectedIndex = WeatherLocations.selectedIndex(from: persistenceService)

        if selectedIndex == WeatherLocations.customLocationIndex,
           let customLocation = WeatherLocations.customLocation(from: persistenceService) {
            currentLocationLabel.text = customLocation.name ?? "Custom Location"
            currentLocationContainer.isHidden = false
        } else {
            currentLocationContainer.isHidden = true
        }
    }

    private func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    private func hideError() {
        statusLabel.isHidden = true
    }

    private func setLoading(_ loading: Bool) {
        if loading {
            loadingIndicator.startAnimating()
            currentLocationButton.isEnabled = false
            zipCodeButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            currentLocationButton.isEnabled = true
            zipCodeButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func currentLocationTapped() {
        hideError()
        setLoading(true)
        dismissKeyboard()

        Task {
            do {
                // Get current GPS location
                let coordinate = try await locationService.currentLocation()

                // Get place name for the location
                let placeName: String
                do {
                    placeName = try await locationService.placeName(for: coordinate)
                } catch {
                    placeName = "Current Location"
                }

                await MainActor.run {
                    // Save as custom location
                    WeatherLocations.setCustomLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        name: placeName,
                        using: persistenceService
                    )

                    // Update UI
                    updatePresetButtonStates(selectedIndex: WeatherLocations.customLocationIndex)
                    updateCurrentLocationDisplay()
                    setLoading(false)

                    // Notify delegate
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    delegate?.cityPickerDidChangeCity()
                }
            } catch let error as LocationError {
                await MainActor.run {
                    setLoading(false)
                    showError(error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    setLoading(false)
                    showError("Could not get location")
                }
            }
        }
    }

    @objc private func zipCodeGoTapped() {
        guard let zipCode = zipCodeField.text, !zipCode.isEmpty else {
            showError("Please enter a zip code")
            return
        }

        hideError()
        setLoading(true)
        dismissKeyboard()

        Task {
            do {
                // Convert zip code to coordinates
                let coordinate = try await locationService.coordinatesForZipCode(zipCode)

                // Get place name for the location
                let placeName: String
                do {
                    placeName = try await locationService.placeName(for: coordinate)
                } catch {
                    placeName = "Zip: \(zipCode)"
                }

                await MainActor.run {
                    // Save as custom location
                    WeatherLocations.setCustomLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        name: placeName,
                        using: persistenceService
                    )

                    // Update UI
                    updatePresetButtonStates(selectedIndex: WeatherLocations.customLocationIndex)
                    updateCurrentLocationDisplay()
                    zipCodeField.text = ""
                    setLoading(false)

                    // Notify delegate
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    delegate?.cityPickerDidChangeCity()
                }
            } catch let error as LocationError {
                await MainActor.run {
                    setLoading(false)
                    showError(error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    setLoading(false)
                    showError("Invalid zip code")
                }
            }
        }
    }

    @objc private func cityTapped(_ sender: UIButton) {
        print("[CityPicker] cityTapped: \(sender.tag)")
        let previousIndex = WeatherLocations.selectedIndex(from: persistenceService)
        let didChange = sender.tag != previousIndex
        print("[CityPicker] previousIndex: \(previousIndex), didChange: \(didChange)")

        // Update selection
        WeatherLocations.setSelectedIndex(sender.tag, using: persistenceService)

        // Update button appearances
        updatePresetButtonStates(selectedIndex: sender.tag)
        updateCurrentLocationDisplay()
        hideError()

        // Haptic feedback and notify delegate if changed
        if didChange {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            print("[CityPicker] Calling delegate, delegate is \(delegate == nil ? "nil" : "set")")
            delegate?.cityPickerDidChangeCity()
        }
    }
}

// MARK: - UITextFieldDelegate

extension WeatherCityPickerViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        zipCodeGoTapped()
        return true
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Only allow digits
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        guard allowedCharacters.isSuperset(of: characterSet) else {
            return false
        }

        // Limit to 5 digits
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 5
    }
}
