//
//  Manifest.swift
//  Builder
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts

public enum BuilderManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [BuilderUIProvider.self]
    }
}
