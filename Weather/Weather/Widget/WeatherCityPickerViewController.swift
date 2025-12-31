//
//  WeatherCityPickerViewController.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather City Picker View Controller

final class WeatherCityPickerViewController: UIViewController {

    // MARK: - Properties

    private let persistenceService: PersistenceService
    private let locations = WeatherLocations.available

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select City"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    init(persistenceService: PersistenceService) {
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

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true

        view.addSubview(titleLabel)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])

        // Create city buttons
        let selectedIndex = WeatherLocations.selectedIndex(from: persistenceService)

        for (index, location) in locations.enumerated() {
            let button = createCityButton(
                name: location.name ?? "Unknown",
                isSelected: index == selectedIndex,
                tag: index
            )
            stackView.addArrangedSubview(button)
        }
    }

    private func createCityButton(name: String, isSelected: Bool, tag: Int) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = name
        config.baseForegroundColor = isSelected ? .systemBlue : .label
        config.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)

        let button = UIButton(configuration: config)
        button.tag = tag
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(cityTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Actions

    @objc private func cityTapped(_ sender: UIButton) {
        let previousIndex = WeatherLocations.selectedIndex(from: persistenceService)

        // Update selection
        WeatherLocations.setSelectedIndex(sender.tag, using: persistenceService)

        // Update button appearances
        for case let button as UIButton in stackView.arrangedSubviews {
            let isSelected = button.tag == sender.tag
            var config = button.configuration
            config?.baseForegroundColor = isSelected ? .systemBlue : .label
            config?.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
            button.configuration = config
        }

        // Haptic feedback
        if sender.tag != previousIndex {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}
