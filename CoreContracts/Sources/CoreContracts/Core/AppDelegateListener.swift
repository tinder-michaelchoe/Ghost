//
//  AppDelegateListener.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

import UIKit

/// Protocol for modules that want to listen to AppDelegate lifecycle events.
public protocol AppDelegateListener: AnyObject {
    init()
    
    /// Called when the application finishes launching.
    /// - Parameters:
    ///   - application: The application instance
    ///   - launchOptions: The launch options dictionary
    /// - Returns: Whether the listener handled the event successfully
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    
    /// Called when a new scene session is being created.
    /// - Parameters:
    ///   - application: The application instance
    ///   - connectingSceneSession: The scene session being connected
    ///   - options: Connection options
    /// - Returns: The scene configuration to use
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration?
    
    /// Called when scene sessions are discarded.
    /// - Parameters:
    ///   - application: The application instance
    ///   - sceneSessions: The set of discarded scene sessions
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
}

public extension AppDelegateListener {
    /// Default implementation returns true (event not handled, continue processing).
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    /// Default implementation returns nil (no configuration provided).
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
        return nil
    }
    
    /// Default implementation does nothing.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Default: no-op
    }
}

