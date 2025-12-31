//
//  NetworkClientServiceProvider.swift
//  NetworkClient
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import Foundation

/// Service provider that registers the NetworkRequestPerforming service.
public final class NetworkClientServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(NetworkRequestPerforming.self) {
            URLSessionNetworkClient.jsonAPI()
        }
    }
}
