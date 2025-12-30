//
//  Manifest.swift
//  NetworkClient
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts

public enum NetworkClientManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [NetworkClientServiceProvider.self]
    }
}
