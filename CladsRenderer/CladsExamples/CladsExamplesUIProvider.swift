//
//  StaticExamplesUIProvider.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/24/25.
//

import Foundation
import CoreContracts
import SwiftUI

// MARK: - Clads Examples UI Provider

/// UI provider that contributes the static examples view to the home tab.
public final class CladsExamplesUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        guard let registry = registry as? TabBarUIContributing else { return }
        registry.contribute(
            to: .home,
            title: "CLADS",
            normalIcon: "scribble.variable",
            selectedIcon: nil,
            factory: { CladsExamplesView() }
        )
    }
}
