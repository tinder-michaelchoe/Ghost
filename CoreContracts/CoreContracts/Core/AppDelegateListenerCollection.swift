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

    public init() {}

    public mutating func add(handler: AppDelegateListener) {
        handlers.append(handler)
    }
    
    /// Notify all listeners about application launch.
    /// - Parameters:
    ///   - application: The application instance
    ///   - launchOptions: The launch options dictionary
    /// - Returns: True if all listeners returned true (or if no listeners), false if any listener returned false
    public func notifyDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var allSucceeded = true
        execute { listener in
            let result = listener.application(application, didFinishLaunchingWithOptions: launchOptions)
            if !result {
                allSucceeded = false
            }
        }
        return allSucceeded
    }
    
    /// Notify all listeners about scene configuration request.
    /// - Parameters:
    ///   - application: The application instance
    ///   - connectingSceneSession: The scene session being connected
    ///   - options: Connection options
    /// - Returns: The first non-nil configuration returned by a listener, or nil if none provided
    public func notifyConfigurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
        var configuration: UISceneConfiguration?
        execute { listener in
            if configuration == nil {
                configuration = listener.application(application, configurationForConnecting: connectingSceneSession, options: options)
            }
        }
        return configuration
    }
    
    /// Notify all listeners about discarded scene sessions.
    /// - Parameters:
    ///   - application: The application instance
    ///   - sceneSessions: The set of discarded scene sessions
    public func notifyDidDiscardSceneSessions(_ application: UIApplication, sceneSessions: Set<UISceneSession>) {
        execute { listener in
            listener.application(application, didDiscardSceneSessions: sceneSessions)
        }
    }
}

