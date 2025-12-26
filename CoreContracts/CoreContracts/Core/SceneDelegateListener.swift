//
//  SceneDelegateListener.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/25/25.
//

import UIKit

/// Protocol for modules that want to listen to SceneDelegate lifecycle events.
public protocol SceneDelegateListener: AnyObject {
    init()
    
    /// Called when a scene is about to connect to a session.
    /// - Parameters:
    ///   - scene: The scene that is connecting
    ///   - session: The scene session being connected
    ///   - options: Connection options
    /// - Returns: An optional ServiceManagerProtocol to use for app initialization, or nil if not providing one
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> ServiceManagerProtocol?
    
    /// Called when the scene has moved from an inactive state to an active state.
    /// - Parameter scene: The scene that became active
    func sceneDidBecomeActive(_ scene: UIScene)
    
    /// Called when the scene will move from an active state to an inactive state.
    /// - Parameter scene: The scene that will resign active
    func sceneWillResignActive(_ scene: UIScene)
    
    /// Called when the scene transitions from the background to the foreground.
    /// - Parameter scene: The scene entering foreground
    func sceneWillEnterForeground(_ scene: UIScene)
    
    /// Called when the scene transitions from the foreground to the background.
    /// - Parameter scene: The scene entering background
    func sceneDidEnterBackground(_ scene: UIScene)
    
    /// Called when the scene is being released by the system.
    /// - Parameter scene: The scene that disconnected
    func sceneDidDisconnect(_ scene: UIScene)
}

public extension SceneDelegateListener {
    /// Default implementation returns nil (no ServiceManager provided).
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> ServiceManagerProtocol? {
        return nil
    }
    
    /// Default implementation does nothing.
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Default: no-op
    }
    
    /// Default implementation does nothing.
    func sceneWillResignActive(_ scene: UIScene) {
        // Default: no-op
    }
    
    /// Default implementation does nothing.
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Default: no-op
    }
    
    /// Default implementation does nothing.
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Default: no-op
    }
    
    /// Default implementation does nothing.
    func sceneDidDisconnect(_ scene: UIScene) {
        // Default: no-op
    }
}

