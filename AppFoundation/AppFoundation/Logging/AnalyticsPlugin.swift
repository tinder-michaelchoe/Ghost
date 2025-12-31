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
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(AnalyticsService.self) { _ in
            // Get all registered logging services
            // For now, create with default loggers
            // In a more sophisticated system, you might query the service container
            // for all LoggingService instances
            AnalyticsServiceImpl(loggers: [
                ConsoleLogger(),
                FileLogger()
            ])
        }
    }
    
    public func run(phase: LifecyclePhase, context: AppContext) async {
        if phase == .postUI {
            if let analytics = context.services.resolve(AnalyticsService.self) {
                analytics.start()
                analytics.track("app_launched", parameters: nil)
            }
        }
    }
}
