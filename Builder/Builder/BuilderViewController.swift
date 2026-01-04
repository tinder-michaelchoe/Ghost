//
//  BuilderViewController.swift
//  BuilderFramework
//
//  Created by mexicanpizza on 12/24/25.
//

import CLADS
import CladsModules
import SwiftUI
import UIKit

// MARK: - Presentation Style

enum PresentationStyle: String, CaseIterable {
    case medium = "Medium"
    case large = "Large"
    case custom = "Custom"
}

// MARK: - Builder View Controller

class BuilderViewController: UIViewController {

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "CLADS Builder"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Paste JSON to preview CLADS components"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var textViewContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.backgroundColor = .clear
        tv.textColor = .label
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.text = defaultJSON
        return tv
    }()

    private lazy var presentationLabel: UILabel = {
        let label = UILabel()
        label.text = "Presentation Style"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()

    private lazy var presentationPicker: UISegmentedControl = {
        let items = PresentationStyle.allCases.map { $0.rawValue }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1 // Default to Large
        control.addTarget(self, action: #selector(presentationStyleChanged), for: .valueChanged)
        return control
    }()

    private lazy var customHeightContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    private lazy var customHeightLabel: UILabel = {
        let label = UILabel()
        label.text = "Height (pts):"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var customHeightField: UITextField = {
        let field = UITextField()
        field.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        field.textColor = .label
        field.backgroundColor = .secondarySystemBackground
        field.layer.cornerRadius = 8
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.text = "400"
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 80).isActive = true
        field.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return field
    }()

    private lazy var renderButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Render"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(renderTapped), for: .touchUpInside)
        return button
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Properties

    private var selectedPresentationStyle: PresentationStyle {
        PresentationStyle.allCases[presentationPicker.selectedSegmentIndex]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        // Header
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        contentStack.addArrangedSubview(headerStack)

        // Text View
        textViewContainer.addSubview(textView)
        contentStack.addArrangedSubview(textViewContainer)

        // Presentation Style
        let presentationStack = UIStackView(arrangedSubviews: [presentationLabel, presentationPicker])
        presentationStack.axis = .horizontal
        presentationStack.spacing = 12
        presentationStack.alignment = .center
        contentStack.addArrangedSubview(presentationStack)

        // Custom Height Input
        customHeightContainer.addArrangedSubview(customHeightLabel)
        customHeightContainer.addArrangedSubview(customHeightField)
        customHeightContainer.addArrangedSubview(UIView()) // Spacer
        contentStack.addArrangedSubview(customHeightContainer)

        // Error Label
        contentStack.addArrangedSubview(errorLabel)

        // Render Button
        contentStack.addArrangedSubview(renderButton)

        // Add spacer at bottom
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentStack.addArrangedSubview(spacer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            textViewContainer.heightAnchor.constraint(equalToConstant: 350),

            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor, constant: -12),
        ])
    }

    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Actions

    @objc private func renderTapped() {
        dismissKeyboard()
        errorLabel.isHidden = true

        let jsonString = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !jsonString.isEmpty else {
            showError("Please enter some JSON")
            return
        }

        // Validate JSON
        guard let data = jsonString.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            showError("Invalid JSON format")
            return
        }

        // Try to create the renderer view
        guard let rendererView = CladsRendererView(jsonString: jsonString, debugMode: true) else {
            showError("Failed to parse CLADS document. Check console for details.")
            return
        }

        presentCladsSheet(rendererView)
    }

    private func presentCladsSheet(_ rendererView: CladsRendererView) {
        let hostingController = UIHostingController(rootView: rendererView)

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [detentForSelectedStyle()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }

        present(hostingController, animated: true)
    }

    private func detentForSelectedStyle() -> UISheetPresentationController.Detent {
        switch selectedPresentationStyle {
        case .medium:
            return .medium()
        case .large:
            return .large()
        case .custom:
            let height = CGFloat(Int(customHeightField.text ?? "400") ?? 400)
            return .custom { _ in height }
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func presentationStyleChanged() {
        let isCustom = selectedPresentationStyle == .custom
        UIView.animate(withDuration: 0.25) {
            self.customHeightContainer.isHidden = !isCustom
            self.customHeightContainer.alpha = isCustom ? 1 : 0
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - Default JSON

private let defaultJSON = """
{
  "id": "builder-preview",
  "version": "1.0",

  "state": {
    "counter": 0
  },

  "styles": {
    "title": {
      "fontSize": 24,
      "fontWeight": "bold",
      "textColor": "#000000"
    },
    "body": {
      "fontSize": 16,
      "fontWeight": "regular",
      "textColor": "#666666"
    },
    "button": {
      "fontSize": 17,
      "fontWeight": "semibold",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 50
    }
  },

  "actions": {
    "increment": {
      "type": "setState",
      "path": "counter",
      "value": { "$expr": "${counter} + 1" }
    },
    "close": {
      "type": "dismiss"
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 20, "bottom": 20 },
    "children": [
      {
        "type": "vstack",
        "alignment": "center",
        "spacing": 16,
        "padding": { "horizontal": 20 },
        "children": [
          { "type": "label", "text": "Hello, CLADS!", "styleId": "title" },
          { "type": "label", "text": "Edit the JSON above to customize this view.", "styleId": "body" },
          { "type": "spacer" },
          {
            "type": "hstack",
            "spacing": 12,
            "children": [
              { "type": "label", "text": "Counter:", "styleId": "body" },
              { "type": "label", "bind": "counter", "styleId": "title" }
            ]
          },
          {
            "type": "button",
            "text": "Increment",
            "styleId": "button",
            "fillWidth": true,
            "actions": { "onTap": "increment" }
          },
          {
            "type": "button",
            "text": "Close",
            "styleId": "button",
            "fillWidth": true,
            "actions": { "onTap": "close" }
          }
        ]
      }
    ]
  }
}
"""
