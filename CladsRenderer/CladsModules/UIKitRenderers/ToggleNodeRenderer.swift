//
//  ToggleNodeRenderer.swift
//  CladsModules
//
//  Renders toggle nodes to UISwitch.
//

import CLADS
import Combine
import SwiftUI
import UIKit

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
