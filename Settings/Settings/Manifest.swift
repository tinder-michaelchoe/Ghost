//
//  Manifest.swift
//  Settings
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts

public enum SettingsManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [
            SettingsUIProvider.self
        ]
    }
}
