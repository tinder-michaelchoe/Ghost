//
//  AnalyticsService.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//

/// Protocol for analytics service
public protocol AnalyticsService: Sendable {
    func track(_ event: String, parameters: [String: Any]?)
    func start()
}
