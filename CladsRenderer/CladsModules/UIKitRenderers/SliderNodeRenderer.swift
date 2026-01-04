//
//  SliderNodeRenderer.swift
//  CladsModules
//
//  Renders slider nodes to UISlider.
//

import CLADS
import Combine
import SwiftUI
import UIKit

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
