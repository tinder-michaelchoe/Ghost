//
//  UIKitHelpers.swift
//  CLADS
//
//  Helper types for UIKit rendering used by CladsUIKitView.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Bound TextField

/// UITextField that binds to a StateStore path
public final class BoundTextField: UITextField, UITextFieldDelegate {
    private let bindingPath: String?
    private let stateStore: StateStore
    private var cancellable: AnyCancellable?

    public init(bindingPath: String?, stateStore: StateStore) {
        self.bindingPath = bindingPath
        self.stateStore = stateStore
        super.init(frame: .zero)
        delegate = self
        setupBinding()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBinding() {
        guard let path = bindingPath else { return }

        // Initial value
        Task { @MainActor in
            if let value = stateStore.get(path) as? String {
                text = value
            }
        }

        // Observe changes
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc private func textChanged() {
        guard let path = bindingPath else { return }
        Task { @MainActor in
            stateStore.set(path, value: text ?? "")
        }
    }
}

// MARK: - Bound Switch

/// UISwitch that binds to a StateStore path
public final class BoundSwitch: UISwitch {
    private let bindingPath: String?
    private let stateStore: StateStore

    public init(bindingPath: String?, stateStore: StateStore) {
        self.bindingPath = bindingPath
        self.stateStore = stateStore
        super.init(frame: .zero)
        setupBinding()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBinding() {
        guard let path = bindingPath else { return }

        // Initial value
        Task { @MainActor in
            if let value = stateStore.get(path) as? Bool {
                isOn = value
            }
        }

        // Observe changes from switch
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc private func valueChanged() {
        guard let path = bindingPath else { return }
        Task { @MainActor in
            stateStore.set(path, value: isOn)
        }
    }
}

// MARK: - Bound Slider

/// UISlider that binds to a StateStore path
public final class BoundSlider: UISlider {
    private let bindingPath: String?
    private let stateStore: StateStore

    public init(bindingPath: String?, minValue: Double, maxValue: Double, stateStore: StateStore) {
        self.bindingPath = bindingPath
        self.stateStore = stateStore
        super.init(frame: .zero)
        self.minimumValue = Float(minValue)
        self.maximumValue = Float(maxValue)
        setupBinding()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBinding() {
        guard let path = bindingPath else { return }

        // Initial value
        Task { @MainActor in
            if let value = stateStore.get(path) as? Double {
                self.value = Float(value)
            } else if let value = stateStore.get(path) as? Int {
                self.value = Float(value)
            }
        }

        // Observe changes from slider
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc private func valueChanged() {
        guard let path = bindingPath else { return }
        Task { @MainActor in
            stateStore.set(path, value: Double(value))
        }
    }
}

// MARK: - Gradient View

/// UIView that renders a gradient using CAGradientLayer
public final class GradientView: UIView {
    private let node: GradientNode
    private let colorScheme: RenderColorScheme

    override public class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    public init(node: GradientNode, colorScheme: RenderColorScheme) {
        self.node = node
        self.colorScheme = colorScheme
        super.init(frame: .zero)
        setupGradient()
        registerForUserInterfaceStyleChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerForUserInterfaceStyleChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: GradientView, _: UITraitCollection) in
            self?.updateColors()
        }
    }

    private func setupGradient() {
        updateColors()
        gradientLayer.startPoint = node.startPoint.cgPoint
        gradientLayer.endPoint = node.endPoint.cgPoint
        gradientLayer.locations = node.colors.map { NSNumber(value: Double($0.location)) }
    }

    private func updateColors() {
        let isDark = effectiveIsDarkMode
        gradientLayer.colors = node.colors.map { stop -> CGColor in
            switch stop.color {
            case .fixed(let color):
                return UIColor(color).cgColor
            case .adaptive(let light, let dark):
                return UIColor(isDark ? dark : light).cgColor
            }
        }
    }

    private var effectiveIsDarkMode: Bool {
        switch colorScheme {
        case .light: return false
        case .dark: return true
        case .system: return traitCollection.userInterfaceStyle == .dark
        }
    }
}

// MARK: - UnitPoint Extension

extension UnitPoint {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - Alignment Conversion

extension SwiftUI.Alignment {
    func toUIKit(for layoutType: ContainerNode.LayoutType) -> UIStackView.Alignment {
        switch layoutType {
        case .vstack:
            if horizontal == .leading { return .leading }
            if horizontal == .trailing { return .trailing }
            return .center
        case .hstack:
            if vertical == .top { return .top }
            if vertical == .bottom { return .bottom }
            return .center
        case .zstack:
            return .center  // ZStack doesn't use UIStackView
        }
    }
}
