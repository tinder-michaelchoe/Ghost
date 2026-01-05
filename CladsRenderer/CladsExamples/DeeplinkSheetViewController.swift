//
//  DeeplinkSheetViewController.swift
//  CladsExamples
//
//  A simple sheet view controller presented via deeplink.
//

import UIKit

/// A sheet view controller that displays a title and message.
/// Presented when a deeplink requests a sheet on the dashboard.
final class DeeplinkSheetViewController: UIViewController {

    // MARK: - Properties

    private let sheetTitle: String
    private let message: String

    // MARK: - UI Elements

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "link.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let successBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Deeplink Handled Successfully"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkmark)

        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            checkmark.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 20),
            checkmark.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            view.heightAnchor.constraint(equalToConstant: 44)
        ])

        return view
    }()

    private lazy var dismissButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Dismiss"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(title: String, message: String) {
        self.sheetTitle = title
        self.message = message
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
        view.backgroundColor = .systemBackground

        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(successBadge)
        view.addSubview(dismissButton)

        titleLabel.text = sheetTitle
        messageLabel.text = message

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            successBadge.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            successBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
