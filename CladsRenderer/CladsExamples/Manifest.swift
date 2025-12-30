//
//  Manofest.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts

public enum CladsExamplesManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [
            CladsExamplesUIProvider.self
        ]
    }
}
