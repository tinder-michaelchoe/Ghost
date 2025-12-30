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

    private let context: AppContext
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Widget>!
    private let layoutProvider = WidgetLayoutProvider()

    private var widgets: [Widget] = []
    private var widgetContributions: [String: WidgetContribution] = [:]

    // MARK: - Section

    private enum Section: Hashable {
        case main
    }

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
        view.backgroundColor = .systemBackground
        title = "Dashboard"

        setupCollectionView()
        setupDataSource()
        loadWidgets()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true

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
        let cellRegistration = UICollectionView.CellRegistration<WidgetCell, Widget> { [weak self] cell, indexPath, widget in
            guard let self else { return }
            self.configureCell(cell, with: widget)
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, widget in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: widget)
        }
    }

    private func configureCell(_ cell: WidgetCell, with widget: Widget) {
        // Check if we have a contribution for this widget
        if let contribution = widgetContributions[widget.id] {
            let frontVC = contribution.makeFrontViewController(context: context)
            let backVC = contribution.makeBackViewController(context: context)

            cell.configureFrontView(with: frontVC)
            if let backVC {
                cell.configureBackView(with: backVC)
            }

            // Add child view controller management
            addChild(frontVC)
            frontVC.didMove(toParent: self)
            if let backVC {
                addChild(backVC)
                backVC.didMove(toParent: self)
            }
        } else {
            // Fallback to basic configuration for widgets without contributions
            cell.configure(with: widget)
        }
    }

    // MARK: - Data

    private func loadWidgets() {
        // Get widget contributions from the registry
        let contributions = context.uiRegistry.contributions(for: DashboardUISurface.widgets)
            .compactMap { $0 as? WidgetContribution }

        // Store contributions by widget ID for cell configuration
        for contribution in contributions {
            widgetContributions[contribution.id.rawValue] = contribution
        }

        // Create widget models from contributions
        widgets = contributions.map { $0.widget }.sortedForLayout()

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

// MARK: - UICollectionViewDragDelegate

extension DashboardViewController: UICollectionViewDragDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard let widget = dataSource.itemIdentifier(for: indexPath) else { return [] }

        let itemProvider = NSItemProvider(object: widget.id as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = widget

        return [dragItem]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dragPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }

        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(
            roundedRect: cell.contentView.bounds,
            cornerRadius: 16
        )
        parameters.backgroundColor = .clear
        return parameters
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dragSessionWillBegin session: UIDragSession
    ) {
        // Add haptic feedback when drag begins
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dragSessionDidEnd session: UIDragSession
    ) {
        // Invalidate layout to reflow widgets after drag ends
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionViewDropDelegate

extension DashboardViewController: UICollectionViewDropDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        guard collectionView.hasActiveDrag else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath,
              let widget = item.dragItem.localObject as? Widget else {
            return
        }

        // Perform the reorder
        collectionView.performBatchUpdates {
            widgets.remove(at: sourceIndexPath.item)
            widgets.insert(widget, at: destinationIndexPath.item)

            var snapshot = NSDiffableDataSourceSnapshot<Section, Widget>()
            snapshot.appendSections([.main])
            snapshot.appendItems(widgets)
            dataSource.apply(snapshot, animatingDifferences: false)
        } completion: { [weak self] _ in
            // Invalidate layout to reflow widgets based on new positions
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }

        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)

        // Haptic feedback on drop
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

// MARK: - Widget Cell

final class WidgetCell: UICollectionViewCell {

    // MARK: - Properties

    private var isFlipped = false
    private var hasBackView = false
    private var frontViewController: UIViewController?
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
        // Clear front view content (except for the placeholder UI)
        frontViewController?.willMove(toParent: nil)
        frontViewController?.view.removeFromSuperview()
        frontViewController?.removeFromParent()
        frontViewController = nil
        // Clear back view content
        backViewController?.willMove(toParent: nil)
        backViewController?.view.removeFromSuperview()
        backViewController?.removeFromParent()
        backViewController = nil
        hasBackView = false
        // Show placeholder UI
        titleLabel.isHidden = false
        iconView.isHidden = false
    }

    // MARK: - Configure

    func configure(with widget: Widget, hasBackView: Bool = false) {
        self.hasBackView = hasBackView
        titleLabel.text = widget.title
        titleLabel.isHidden = false
        iconView.isHidden = false

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

    /// Configure the front view with a view controller
    func configureFrontView(with viewController: UIViewController) {
        frontViewController = viewController
        // Hide placeholder UI
        titleLabel.isHidden = true
        iconView.isHidden = true

        let view = viewController.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        frontView.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: frontView.topAnchor),
            view.leadingAnchor.constraint(equalTo: frontView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: frontView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: frontView.bottomAnchor)
        ])
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
