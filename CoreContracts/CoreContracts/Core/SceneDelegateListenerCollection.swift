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
    
    /// Stores type names for logging purposes
    private var handlerTypeNames: [String] = []

    public init() {
        log("🏗️ SceneDelegateListenerCollection initialized")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[SceneDelegateListeners] [\(timestamp)] \(message)")
    }

    public mutating func add(handler: SceneDelegateListener) {
        let typeName = String(describing: type(of: handler))
        handlers.append(handler)
        handlerTypeNames.append(typeName)
        log("📋 Added listener: \(typeName) (total: \(handlers.count))")
    }

    /// Configure all listeners with the service resolver.
    /// Called after services are registered so listeners can obtain their dependencies.
    /// - Parameter resolver: The service resolver to pass to listeners
    public func configureAll(with resolver: ServiceResolver) {
        let startTime = CFAbsoluteTimeGetCurrent()
        log("⚙️ Configuring \(handlers.count) listener(s) with ServiceResolver")
        
        for (index, handler) in handlers.enumerated() {
            let listenerStart = CFAbsoluteTimeGetCurrent()
            handler.configure(with: resolver)
            let duration = (CFAbsoluteTimeGetCurrent() - listenerStart) * 1000
            let typeName = handlerTypeNames[index]
            log("  ├── ✅ \(typeName) configured in \(String(format: "%.2f", duration))ms")
        }
        
        let totalDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        log("⚙️ Configuration complete in \(String(format: "%.2f", totalDuration))ms")
    }

    /// Notify all listeners about scene connection.
    /// - Parameters:
    ///   - scene: The scene that is connecting
    ///   - session: The scene session being connected
    ///   - options: Connection options
    /// - Returns: The first non-nil ServiceManagerProtocol returned by a listener, or nil if none provided
    public func notifyWillConnect(_ scene: UIScene, session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> ServiceManagerProtocol? {
        log("📣 Broadcasting: willConnectTo to \(handlers.count) listener(s)")
        var serviceManager: ServiceManagerProtocol?
        execute { listener in
            if serviceManager == nil {
                serviceManager = listener.scene(scene, willConnectTo: session, options: connectionOptions)
            }
        }
        log("📣 Broadcast complete: willConnectTo (serviceManager provided: \(serviceManager != nil))")
        return serviceManager
    }
    
    /// Notify all listeners about scene becoming active.
    /// - Parameter scene: The scene that became active
    public func notifyDidBecomeActive(_ scene: UIScene) {
        log("📣 Broadcasting: sceneDidBecomeActive to \(handlers.count) listener(s)")
        execute { listener in
            listener.sceneDidBecomeActive(scene)
        }
        log("📣 Broadcast complete: sceneDidBecomeActive")
    }
    
    /// Notify all listeners about scene resigning active.
    /// - Parameter scene: The scene that will resign active
    public func notifyWillResignActive(_ scene: UIScene) {
        log("📣 Broadcasting: sceneWillResignActive to \(handlers.count) listener(s)")
        execute { listener in
            listener.sceneWillResignActive(scene)
        }
        log("📣 Broadcast complete: sceneWillResignActive")
    }
    
    /// Notify all listeners about scene entering foreground.
    /// - Parameter scene: The scene entering foreground
    public func notifyWillEnterForeground(_ scene: UIScene) {
        log("📣 Broadcasting: sceneWillEnterForeground to \(handlers.count) listener(s)")
        execute { listener in
            listener.sceneWillEnterForeground(scene)
        }
        log("📣 Broadcast complete: sceneWillEnterForeground")
    }
    
    /// Notify all listeners about scene entering background.
    /// - Parameter scene: The scene entering background
    public func notifyDidEnterBackground(_ scene: UIScene) {
        log("📣 Broadcasting: sceneDidEnterBackground to \(handlers.count) listener(s)")
        execute { listener in
            listener.sceneDidEnterBackground(scene)
        }
        log("📣 Broadcast complete: sceneDidEnterBackground")
    }
    
    /// Notify all listeners about scene disconnecting.
    /// - Parameter scene: The scene that disconnected
    public func notifyDidDisconnect(_ scene: UIScene) {
        log("📣 Broadcasting: sceneDidDisconnect to \(handlers.count) listener(s)")
        execute { listener in
            listener.sceneDidDisconnect(scene)
        }
        log("📣 Broadcast complete: sceneDidDisconnect")
    }

    /// Notify all listeners about URLs to open.
    /// - Parameters:
    ///   - scene: The scene receiving the URLs
    ///   - urlContexts: The URL contexts containing the URLs to open
    public func notifyOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>) {
        log("📣 Broadcasting: openURLContexts (\(urlContexts.count) URL(s)) to \(handlers.count) listener(s)")
        execute { listener in
            listener.scene(scene, openURLContexts: urlContexts)
        }
        log("📣 Broadcast complete: openURLContexts")
    }
    
    /// Dumps all registered listeners for debugging.
    /// Shows the complete listener list from this centralized orchestrator.
    public func dumpListeners() {
        print("")
        print("╔══════════════════════════════════════════════════════════════════╗")
        print("║         SCENE DELEGATE LISTENERS - REGISTERED HANDLERS           ║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Total Listeners: \(handlers.count.description.padding(toLength: 48, withPad: " ", startingAt: 0))║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        
        for (index, typeName) in handlerTypeNames.enumerated() {
            let prefix = index == handlerTypeNames.count - 1 ? "└──" : "├──"
            print("║ \(prefix) \(typeName.padding(toLength: 61, withPad: " ", startingAt: 0))║")
        }
        
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Events: willConnect, didBecomeActive, willResignActive, etc.     ║")
        print("╚══════════════════════════════════════════════════════════════════╝")
        print("")
    }
}

