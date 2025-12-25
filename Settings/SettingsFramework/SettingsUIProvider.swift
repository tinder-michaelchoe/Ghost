//
//  SettingsUIProvider.swift
//  Settings
//
//  Created by mexicanpizza on 12/24/25.
//

import Foundation
import CoreContracts
import SwiftUI

/// Contribution for the home tab that provides a SwiftUI view with tab bar metadata.
struct HomeTabContribution: SwiftUIViewContribution, TabBarItemProviding {
    let id: ViewContributionID
    let tabBarTitle: String?
    let tabBarIconSystemName: String?
    
    init(
        id: ViewContributionID = ViewContributionID(rawValue: "settings-tab-item"),
        title: String? = "Settings",
        iconSystemName: String? = "gear"
    ) {
        self.id = id
        self.tabBarTitle = title
        self.tabBarIconSystemName = iconSystemName
    }
    
    func makeSwiftUIView(context: AppContext) -> AnySwiftUIView {
        AnySwiftUIView {
            AnyView(SettingsView())
        }
    }
}

/// UI provider that contributes a TabBarController to the mainView surface.
public final class SettingsUIProvider: UIProvider, ModuleIdentity {
    public static let id: String = "com.ghost.staticExamples"
    public static let dependencies: [any ModuleIdentity.Type] = []
    
    public init() {}
    
    public func registerUI(_ registry: UIRegistry) async {
        let contribution = HomeTabContribution()
        await registry.contributeAsync(to: TabBarUISurface.settings, item: contribution)
    }
}
