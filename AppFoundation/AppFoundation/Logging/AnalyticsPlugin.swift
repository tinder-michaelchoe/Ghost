//
//  AnalyticsPlugin.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

/// Analytics module that provides analytics service and starts in postUI phase.
/// Conforms to ServiceProvider (registers services) and LifecycleParticipant (starts in postUI).
public final class AnalyticsServiceProvider: ServiceProvider, LifecycleParticipant {
    /// The analytics service instance created during registration
    private var analytics: AnalyticsService?

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        let analytics = AnalyticsServiceImpl(loggers: [
            ConsoleLogger(),
            FileLogger()
        ])
        self.analytics = analytics
        registry.register(AnalyticsService.self) {
            analytics
        }
    }

    public func run(phase: LifecyclePhase) async {
        if phase == .postUI {
            analytics?.start()
            analytics?.track("app_launched", parameters: nil)
        }
    }
}
