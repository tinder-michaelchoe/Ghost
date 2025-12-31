//
//  Manifest.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

public enum ArtManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [ArtServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        [ArtUIProvider.self]
    }
}
