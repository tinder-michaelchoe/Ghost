//
//  Manifest.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts

public enum DashboardManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [DashboardUIProvider.self]
    }
}
