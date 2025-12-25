//
//  Manofest.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts

public enum StaticExamplesManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [
            StaticExamplesUIProvider.self
        ]
    }
}
