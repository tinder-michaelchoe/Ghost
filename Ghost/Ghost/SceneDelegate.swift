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
    private let moduleManager: ModuleManager = ModuleManager()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Initialize module system asynchronously
        Task {
            await initializeApp(windowScene: windowScene)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

extension SceneDelegate {
    private func initializeApp(windowScene: UIWindowScene) async {
        do {
            // Register all modules from manifest
            try await moduleManager.registerModules(
                serviceProviders: ModuleManifest.serviceProviders,
                uiProviders: ModuleManifest.uiProviders,
                lifecycleParticipants: ModuleManifest.lifecycleParticipants
            )
            
            // Run lifecycle phases
            await moduleManager.runPhase(.prewarm)
            await moduleManager.runPhase(.launch)
            
            // Get context and UI registry
            guard let context = moduleManager.getContext() else {
                print("⚠️ Failed to get app context")
                return
            }
            
            let uiRegistry = moduleManager.getUIRegistry()
            
            // Build UI
            await moduleManager.runPhase(.sceneConnect)
            
            // Get main view contribution
            print("🔍 SceneDelegate: Querying for AppUISurface.mainView contributions...")
            let mainViewContributions = await uiRegistry.getContributions(for: AppUISurface.mainView)
            print("🔍 SceneDelegate: Found \(mainViewContributions.count) contribution(s) for AppUISurface.mainView")
            
            guard let mainViewContribution = mainViewContributions.first else {
                print("⚠️ No main view contribution found")
                return
            }
            
            print("✅ SceneDelegate: Building view controller from contribution: \(mainViewContribution.id.rawValue)")
            
            var rootViewController: UIViewController?
            // Build the main view controller from contribution
            if let uiKitContrib = mainViewContribution as? UIKitViewContribution {
                print("✅ SceneDelegate: Using UIKitViewContribution")
                let anyVC = uiKitContrib.makeViewController(context: context)
                rootViewController = anyVC.build() as? UIViewController
                print("✅ SceneDelegate: View controller built: \(type(of: rootViewController))")
            } else if let swiftUIContrib = mainViewContribution as? SwiftUIViewContribution {
                print("✅ SceneDelegate: Using SwiftUIViewContribution")
                let swiftUIView = swiftUIContrib.makeSwiftUIView(context: context).build()
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
            await moduleManager.runPhase(.postUI)
            
            print("✅ App initialized successfully")
        } catch {
            print("❌ Failed to initialize app: \(error)")
            // In production, you might want to show an error screen
        }
    }
}
