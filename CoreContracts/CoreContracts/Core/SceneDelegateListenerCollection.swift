//
//  SceneDelegateListenerCollection.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/25/25.
//

import UIKit

/// A collection of SceneDelegateListener instances that can be notified of SceneDelegate events.
public struct SceneDelegateListenerCollection: HandlerCollection {
    public typealias EventHandler = SceneDelegateListener

    public private(set) var handlers: [SceneDelegateListener] = []

    public init() {}

    public mutating func add(handler: SceneDelegateListener) {
        handlers.append(handler)
    }

    /// Configure all listeners with the service resolver.
    /// Called after services are registered so listeners can obtain their dependencies.
    /// - Parameter resolver: The service resolver to pass to listeners
    public func configureAll(with resolver: ServiceResolver) {
        execute { listener in
            listener.configure(with: resolver)
        }
    }

    /// Notify all listeners about scene connection.
    /// - Parameters:
    ///   - scene: The scene that is connecting
    ///   - session: The scene session being connected
    ///   - options: Connection options
    /// - Returns: The first non-nil ServiceManagerProtocol returned by a listener, or nil if none provided
    public func notifyWillConnect(_ scene: UIScene, session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> ServiceManagerProtocol? {
        var serviceManager: ServiceManagerProtocol?
        execute { listener in
            if serviceManager == nil {
                serviceManager = listener.scene(scene, willConnectTo: session, options: connectionOptions)
            }
        }
        return serviceManager
    }
    
    /// Notify all listeners about scene becoming active.
    /// - Parameter scene: The scene that became active
    public func notifyDidBecomeActive(_ scene: UIScene) {
        execute { listener in
            listener.sceneDidBecomeActive(scene)
        }
    }
    
    /// Notify all listeners about scene resigning active.
    /// - Parameter scene: The scene that will resign active
    public func notifyWillResignActive(_ scene: UIScene) {
        execute { listener in
            listener.sceneWillResignActive(scene)
        }
    }
    
    /// Notify all listeners about scene entering foreground.
    /// - Parameter scene: The scene entering foreground
    public func notifyWillEnterForeground(_ scene: UIScene) {
        execute { listener in
            listener.sceneWillEnterForeground(scene)
        }
    }
    
    /// Notify all listeners about scene entering background.
    /// - Parameter scene: The scene entering background
    public func notifyDidEnterBackground(_ scene: UIScene) {
        execute { listener in
            listener.sceneDidEnterBackground(scene)
        }
    }
    
    /// Notify all listeners about scene disconnecting.
    /// - Parameter scene: The scene that disconnected
    public func notifyDidDisconnect(_ scene: UIScene) {
        execute { listener in
            listener.sceneDidDisconnect(scene)
        }
    }

    /// Notify all listeners about URLs to open.
    /// - Parameters:
    ///   - scene: The scene receiving the URLs
    ///   - urlContexts: The URL contexts containing the URLs to open
    public func notifyOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>) {
        execute { listener in
            listener.scene(scene, openURLContexts: urlContexts)
        }
    }
}

