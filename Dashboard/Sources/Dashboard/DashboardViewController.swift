//
//  DashboardViewController.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import UIKit

// MARK: - Dashboard View Controller

final class DashboardViewController: UIViewController {

    // MARK: - Properties

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Widget>!
    private let layoutProvider = WidgetLayoutProvider()

    private var widgets: [Widget] = []

    // MARK: - Section

    private enum Section: Hashable {
        case main
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Dashboard"

        setupCollectionView()
        setupDataSource()
        loadSampleWidgets()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self else { return nil }
            return self.layoutProvider.createSection(for: self.widgets, environment: environment)
        }
    }

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WidgetCell, Widget> { cell, indexPath, widget in
            cell.configure(with: widget)
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, widget in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: widget)
        }
    }

    // MARK: - Data

    private func loadSampleWidgets() {
        // Sample widgets to demonstrate different sizes and priorities
        widgets = [
            Widget(id: "weather", size: .medium, title: "Weather", priorityTier: .primary),
            Widget(id: "calendar", size: .small, title: "Calendar", priorityTier: .primary),
            Widget(id: "reminders", size: .tall, title: "Reminders", priorityTier: .secondary),
            Widget(id: "music", size: .small, title: "Music", priorityTier: .tertiary),
            Widget(id: "photos", size: .large, title: "Photos", priorityTier: .secondary),
            Widget(id: "notes", size: .medium, title: "Notes", priorityTier: .secondary),
            Widget(id: "fitness", size: .small, title: "Fitness", priorityTier: .tertiary),
            Widget(id: "stocks", size: .small, title: "Stocks", priorityTier: .tertiary),
        ].sortedForLayout()

        applySnapshot()
    }

    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Widget>()
        snapshot.appendSections([.main])
        snapshot.appendItems(widgets)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)

        // Invalidate layout when widgets change to recalculate positions
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionViewDelegate

extension DashboardViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let widget = dataSource.itemIdentifier(for: indexPath) else { return }
        print("Selected widget: \(widget.title)")
    }
}

// MARK: - Widget Cell

final class WidgetCell: UICollectionViewCell {

    // MARK: - Properties

    private var isFlipped = false
    private var hasBackView = false
    private var backViewController: UIViewController?

    private let frontView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private let backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(frontView)
        contentView.addSubview(backView)

        frontView.addSubview(titleLabel)
        frontView.addSubview(iconView)

        NSLayoutConstraint.activate([
            frontView.topAnchor.constraint(equalTo: contentView.topAnchor),
            frontView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            frontView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            frontView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            backView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),

            iconView.centerXAnchor.constraint(equalTo: frontView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: frontView.centerYAnchor, constant: 10),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Actions

    @objc private func handleDoubleTap() {
        if hasBackView {
            flip()
        } else {
            wiggle()
        }
    }

    private func flip() {
        let fromView = isFlipped ? backView : frontView
        let toView = isFlipped ? frontView : backView

        let direction: UIView.AnimationOptions = isFlipped ? .transitionFlipFromLeft : .transitionFlipFromRight

        UIView.transition(
            from: fromView,
            to: toView,
            duration: 0.5,
            options: [direction, .showHideTransitionViews]
        ) { [weak self] _ in
            self?.isFlipped.toggle()
        }
    }

    /// Performs a wiggle animation (slight flip back and forth) to indicate the widget isn't flippable
    private func wiggle() {
        let perspective: CGFloat = 1.0 / 500.0
        var transform = CATransform3DIdentity
        transform.m34 = perspective

        // Animate a slight rotation back and forth on the Y axis
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.duration = 0.4
        animation.values = [
            NSValue(caTransform3D: transform),
            NSValue(caTransform3D: CATransform3DRotate(transform, .pi / 12, 0, 1, 0)),
            NSValue(caTransform3D: CATransform3DRotate(transform, -.pi / 16, 0, 1, 0)),
            NSValue(caTransform3D: CATransform3DRotate(transform, .pi / 24, 0, 1, 0)),
            NSValue(caTransform3D: transform)
        ]
        animation.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]

        contentView.layer.add(animation, forKey: "wiggle")
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset to front view when cell is reused
        if isFlipped {
            frontView.isHidden = false
            backView.isHidden = true
            isFlipped = false
        }
        // Clear back view content
        backViewController?.view.removeFromSuperview()
        backViewController = nil
        hasBackView = false
    }

    // MARK: - Configure

    func configure(with widget: Widget, hasBackView: Bool = false) {
        self.hasBackView = hasBackView
        titleLabel.text = widget.title

        // Set icon based on widget id
        let iconName: String
        let iconColor: UIColor

        switch widget.id {
        case "weather":
            iconName = "sun.max.fill"
            iconColor = .systemOrange
        case "calendar":
            iconName = "calendar"
            iconColor = .systemRed
        case "reminders":
            iconName = "checklist"
            iconColor = .systemBlue
        case "music":
            iconName = "music.note"
            iconColor = .systemPink
        case "photos":
            iconName = "photo.stack"
            iconColor = .systemPurple
        case "notes":
            iconName = "note.text"
            iconColor = .systemYellow
        case "fitness":
            iconName = "figure.run"
            iconColor = .systemGreen
        case "stocks":
            iconName = "chart.line.uptrend.xyaxis"
            iconColor = .systemTeal
        default:
            iconName = "square.grid.2x2"
            iconColor = .systemGray
        }

        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = iconColor
        frontView.backgroundColor = iconColor.withAlphaComponent(0.15)
    }

    /// Configure the back view with a view controller
    func configureBackView(with viewController: UIViewController) {
        hasBackView = true
        backViewController = viewController

        let view = viewController.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: backView.topAnchor),
            view.leadingAnchor.constraint(equalTo: backView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: backView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: backView.bottomAnchor)
        ])
    }
}
