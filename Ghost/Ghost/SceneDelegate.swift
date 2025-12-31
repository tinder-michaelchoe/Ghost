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
            await initializeApp(windowScene: windowScene)
            
            // Step 4: Notify SceneDelegate listeners (after AppCoordinator is created)
            _ = listenerCollection.notifyWillConnect(scene, session: session, options: connectionOptions)
        }
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
    private func initializeApp(windowScene: UIWindowScene) async {
        guard let coordinator else {
            return
        }
        
        do {
            // Initialize app through coordinator (orchestrates: services → context → UI → lifecycle)
            let context = try await coordinator.initialize(manifest: AppManifest.self)
            
            // Run lifecycle phases (coordinator manages context internally)
            await coordinator.runPhase(.prewarm)
            await coordinator.runPhase(.launch)
            
            // Build UI
            await coordinator.runPhase(.sceneConnect)
            
            // Get main view contribution (direct access to UI manager)
            let mainViewContributions = coordinator.uiManager.contributions(for: AppUISurface.mainView)
            print("🔍 Found \(mainViewContributions.count) contribution(s)")

            guard let mainViewContribution = mainViewContributions.first else {
                print("⚠️ No main view contribution found")
                return
            }
            
            var rootViewController: UIViewController?
            // Build the main view controller from contribution
            if let uiKitContrib = mainViewContribution as? UIKitViewContribution {
                let anyVC = uiKitContrib.makeViewController(context: context)
                rootViewController = anyVC.build() as? UIViewController
            } else if let swiftUIContrib = mainViewContribution as? SwiftUIViewContribution {
                let swiftUIView = swiftUIContrib.makeSwiftUIView(context: context)
                rootViewController = UIHostingController(rootView: swiftUIView)
            } else {
                print("⚠️ No view builder for main view")
                return
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                window?.rootViewController = rootViewController
                window?.makeKeyAndVisible()
            }
            
            // Run post-UI phase
            await coordinator.runPhase(.postUI)
            
            print("✅ App initialized successfully")
        } catch {
            print("❌ Failed to initialize app: \(error)")
            // In production, you might want to show an error screen
        }
    }
}
