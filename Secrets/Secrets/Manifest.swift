//
//  Manifest.swift
//  Secrets
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts

public enum SecretsManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [SecretsServiceProvider.self]
    }
}
