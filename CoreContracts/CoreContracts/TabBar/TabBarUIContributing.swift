//
//  TabBarUICotributing.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/31/25.
//

import SwiftUI
import UIKit

public protocol TabBarUIContributing: UIRegistryContributing {
    
    func contribute(
        to surface: TabBarUISurface,
        title: String,
        normalIcon: String,
        selectedIcon: String?,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    )
    
    func contribute<V: View>(
        to surface: TabBarUISurface,
        title: String,
        normalIcon: String,
        selectedIcon: String?,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    )
}

public extension TabBarUIContributing {
    func contribute(
        to surface: TabBarUISurface,
        title: String,
        normalIcon: String,
        selectedIcon: String?,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    ) {
        contribute(
            to: surface,
            contribution: TabBarContribution(
                title: title,
                normalIcon: normalIcon,
                selectedIcon: selectedIcon
            ),
            factory: factory
        )
    }

    // MARK: - SwiftUI Inline

    /// Register a SwiftUI contribution with just an ID (no custom metadata).
    func contribute<V: View>(
        to surface: TabBarUISurface,
        title: String,
        normalIcon: String,
        selectedIcon: String?,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    ) {
        contribute(
            to: surface,
            contribution: TabBarContribution(
                title: title,
                normalIcon: normalIcon,
                selectedIcon: selectedIcon
            ),
            factory: factory
        )
    }
}

struct TabBarContribution: ViewContribution, TabBarItemProviding, Sendable {
    let id: ViewContributionID
    let tabBarTitle: String?
    let tabBarIconSystemName: String?
    
    init(
        title: String,
        normalIcon: String,
        selectedIcon: String?
    ) {
        self.id = ViewContributionID(rawValue: title)
        self.tabBarTitle = title
        self.tabBarIconSystemName = normalIcon
    }
}
