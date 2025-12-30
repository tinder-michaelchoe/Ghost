//
//  Manifest.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts

public enum WeatherManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [WeatherServiceProvider.self]
    }
}
