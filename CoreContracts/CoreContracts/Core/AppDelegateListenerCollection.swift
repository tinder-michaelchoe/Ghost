//
//  AppDelegateListenerCollection.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

import UIKit

/// A collection of AppDelegateListener instances that can be notified of AppDelegate events.
public struct AppDelegateListenerCollection: HandlerCollection {
    public typealias EventHandler = AppDelegateListener

    public private(set) var handlers: [AppDelegateListener] = []
    
    /// Stores type names for logging purposes
    private var handlerTypeNames: [String] = []

    public init() {
        log("🏗️ AppDelegateListenerCollection initialized")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[AppDelegateListeners] [\(timestamp)] \(message)")
    }

    public mutating func add(handler: AppDelegateListener) {
        let typeName = String(describing: type(of: handler))
        handlers.append(handler)
        handlerTypeNames.append(typeName)
        log("📋 Added listener: \(typeName) (total: \(handlers.count))")
    }
    
    /// Notify all listeners about application launch.
    /// - Parameters:
    ///   - application: The application instance
    ///   - launchOptions: The launch options dictionary
    /// - Returns: True if all listeners returned true (or if no listeners), false if any listener returned false
    public func notifyDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        log("📣 Broadcasting: didFinishLaunchingWithOptions to \(handlers.count) listener(s)")
        
        var allSucceeded = true
        for (index, handler) in handlers.enumerated() {
            let listenerStart = CFAbsoluteTimeGetCurrent()
            let result = handler.application(application, didFinishLaunchingWithOptions: launchOptions)
            let duration = (CFAbsoluteTimeGetCurrent() - listenerStart) * 1000
            let typeName = handlerTypeNames[index]
            let status = result ? "✅" : "❌"
            log("  ├── \(status) \(typeName) responded in \(String(format: "%.2f", duration))ms")
            if !result {
                allSucceeded = false
            }
        }
        
        let totalDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        log("📣 Broadcast complete: didFinishLaunchingWithOptions in \(String(format: "%.2f", totalDuration))ms (success: \(allSucceeded))")
        return allSucceeded
    }
    
    /// Notify all listeners about scene configuration request.
    /// - Parameters:
    ///   - application: The application instance
    ///   - connectingSceneSession: The scene session being connected
    ///   - options: Connection options
    /// - Returns: The first non-nil configuration returned by a listener, or nil if none provided
    public func notifyConfigurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
        log("📣 Broadcasting: configurationForConnecting to \(handlers.count) listener(s)")
        var configuration: UISceneConfiguration?
        execute { listener in
            if configuration == nil {
                configuration = listener.application(application, configurationForConnecting: connectingSceneSession, options: options)
            }
        }
        log("📣 Broadcast complete: configurationForConnecting (provided: \(configuration != nil))")
        return configuration
    }
    
    /// Notify all listeners about discarded scene sessions.
    /// - Parameters:
    ///   - application: The application instance
    ///   - sceneSessions: The set of discarded scene sessions
    public func notifyDidDiscardSceneSessions(_ application: UIApplication, sceneSessions: Set<UISceneSession>) {
        log("📣 Broadcasting: didDiscardSceneSessions to \(handlers.count) listener(s)")
        execute { listener in
            listener.application(application, didDiscardSceneSessions: sceneSessions)
        }
        log("📣 Broadcast complete: didDiscardSceneSessions")
    }
    
    /// Dumps all registered listeners for debugging.
    /// Shows the complete listener list from this centralized orchestrator.
    public func dumpListeners() {
        print("")
        print("╔══════════════════════════════════════════════════════════════════╗")
        print("║          APP DELEGATE LISTENERS - REGISTERED HANDLERS            ║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Total Listeners: \(handlers.count.description.padding(toLength: 48, withPad: " ", startingAt: 0))║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        
        for (index, typeName) in handlerTypeNames.enumerated() {
            let prefix = index == handlerTypeNames.count - 1 ? "└──" : "├──"
            print("║ \(prefix) \(typeName.padding(toLength: 61, withPad: " ", startingAt: 0))║")
        }
        
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Events: didFinishLaunching, configForConnecting, didDiscard     ║")
        print("╚══════════════════════════════════════════════════════════════════╝")
        print("")
    }
}

