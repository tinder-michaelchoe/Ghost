//
//  SceneDelegate.swift
//  Ghost
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var coordinator: AppCoordinator?
    
    /// Reference to AppDelegate to access bootstrap coordinator.
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
    
    /// Collection of SceneDelegate listeners discovered from manifests.
    private lazy var listenerCollection: SceneDelegateListenerCollection = {
        var collection = SceneDelegateListenerCollection()
        
        // Register all listeners from AppManifest
        let listenerTypes = AppManifest.sceneDelegateListeners
        for listenerType in listenerTypes {
            let listener = listenerType.init()
            collection.add(handler: listener)
        }
        
        return collection
    }()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Step 1: Get ServiceManager from BootstrapCoordinator (with bootstrap services already registered)
        let serviceManager = appDelegate?.bootstrapServiceManager ?? ServiceManager()
        
        // Step 2: Create AppCoordinator with bootstrap ServiceManager
        coordinator = AppCoordinator(serviceManager: serviceManager)
        
        // Step 3: Initialize module system asynchronously
        Task {
            await initializeApp(
                windowScene: windowScene,
                scene: scene,
                session: session,
                connectionOptions: connectionOptions
            )
        }
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        // Handle URLs when app is already running
        print("[SceneDelegate] openURLContexts called with \(urlContexts.count) URL(s)")
        for context in urlContexts {
            print("[SceneDelegate] URL: \(context.url)")
        }
        listenerCollection.notifyOpenURLContexts(scene, urlContexts: urlContexts)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Notify all listeners
        listenerCollection.notifyDidDisconnect(scene)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Notify all listeners
        listenerCollection.notifyDidBecomeActive(scene)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Notify all listeners
        listenerCollection.notifyWillResignActive(scene)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Notify all listeners
        listenerCollection.notifyWillEnterForeground(scene)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Notify all listeners
        listenerCollection.notifyDidEnterBackground(scene)
    }
}

extension SceneDelegate {

    /// Configure all listeners with the service resolver.
    /// Called after services are registered so listeners can obtain their dependencies.
    private func configureListeners() {
        guard let resolver = coordinator?.serviceManager.serviceContainer else { return }
        listenerCollection.configureAll(with: resolver)
    }

    private func initializeApp(
        windowScene: UIWindowScene,
        scene: UIScene,
        session: UISceneSession,
        connectionOptions: UIScene.ConnectionOptions
    ) async {
        guard let coordinator else {
            return
        }
        
        do {
            // Step 1: Initialize (services → UI providers → lifecycle participants)
            _ = try await coordinator.initialize(manifest: AppManifest.self)

            await coordinator.runPhase(.prewarm)
            await coordinator.runPhase(.launch)

            // Step 2: Configure listeners with service resolver (NOW services are available)
            configureListeners()
            
            // Step 3: Notify scene listeners about willConnect (BEFORE phases run)
            _ = listenerCollection.notifyWillConnect(scene, session: session, options: connectionOptions)
            
            // Step 4: Run lifecycle phases
            await coordinator.runPhase(.sceneConnect)
            
            // Step 5: Build UI
            let mainViewContributions = coordinator.uiManager.contributions(for: AppUISurface.mainView)
            print("🔍 Found \(mainViewContributions.count) contribution(s)")

            guard let resolved = mainViewContributions.first else {
                print("⚠️ No main view contribution found")
                return
            }

            let anyVC = resolved.makeViewController()
            guard let rootViewController = anyVC.build() as? UIViewController else {
                print("⚠️ Failed to build main view controller")
                return
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                window?.rootViewController = rootViewController
                window?.makeKeyAndVisible()
            }
            
            // Step 6: Run post-UI phase
            await coordinator.runPhase(.postUI)
            
            // Step 7: Dump all orchestrator states for debugging/analytics
            // This showcases centralized visibility into all registered components
            coordinator.dumpAllOrchestrators()
            
            // Also dump the listener collections
            listenerCollection.dumpListeners()
            
            print("✅ App initialized successfully")
        } catch {
            print("❌ Failed to initialize app: \(error)")
            // In production, you might want to show an error screen
        }
    }
}
