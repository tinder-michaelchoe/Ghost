//
//  AnalyticsService.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/22/25.
//

import CoreContracts

/// Simple analytics implementation
final class AnalyticsServiceImpl: AnalyticsService, @unchecked Sendable {
    private let loggers: HandlerGroup<LoggingService>
    private var isStarted = false
    
    init(loggers: [LoggingService]) {
        self.loggers = HandlerGroup(handlers: loggers)
    }
    
    func track(_ event: String, parameters: [String: Any]?) {
        guard isStarted else { return }
        loggers.execute { logger in
            logger.log("Analytics: \(event) \(parameters?.description ?? "")", level: .info)
            // In a real implementation, this would send to analytics backend
        }
    }
    
    func start() {
        isStarted = true
        loggers.execute { logger in
            logger.start()
        }
    }
}
