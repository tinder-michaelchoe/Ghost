//
//  StaticExamplesUIProvider.swift
//  StaticExamples
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
        id: ViewContributionID = ViewContributionID(rawValue: "home-tab-item"),
        title: String? = "Static",
        iconSystemName: String? = "scribble.variable"
    ) {
        self.id = id
        self.tabBarTitle = title
        self.tabBarIconSystemName = iconSystemName
    }
    
    func makeSwiftUIView(context: AppContext) -> AnyView {
        AnyView(CladsExamplesView())
    }
}

/// UI provider that contributes a TabBarController to the mainView surface.
public final class CladsExamplesUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistryContributing) async {
        let contribution = HomeTabContribution()
        registry.contribute(to: TabBarUISurface.home, item: contribution)
    }
}
