//
//  AppDelegate.swift
//  Ghost
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// Bootstrap coordinator that registers critical services first.
    private let bootstrapCoordinator = BootstrapCoordinator()
    
    /// Collection of AppDelegate listeners discovered from manifests.
    private lazy var listenerCollection: AppDelegateListenerCollection = {
        var collection = AppDelegateListenerCollection()
        
        // Register all listeners from AppManifest (excluding BootstrapCoordinator)
        let listenerTypes = AppManifest.appDelegateListeners
        for listenerType in listenerTypes {
            let listener = listenerType.init()
            collection.add(handler: listener)
        }
        
        return collection
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("🚀 AppDelegate: didFinishLaunchingWithOptions")
        
        // Step 1: Register bootstrap services FIRST (synchronously)
        let bootstrapProviders = BootstrapManifest.bootstrapServiceProviders
        bootstrapCoordinator.registerBootstrapServices(providers: bootstrapProviders)
        print("✅ AppDelegate: Bootstrap services registered")
        
        // Step 2: Notify all other AppDelegate listeners
        let allSucceeded = listenerCollection.notifyDidFinishLaunching(application, launchOptions: launchOptions)
        print("✅ AppDelegate: All listeners notified")
        
        return allSucceeded
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Notify all registered listeners and get configuration if provided
        if let configuration = listenerCollection.notifyConfigurationForConnecting(application, connectingSceneSession: connectingSceneSession, options: options) {
            return configuration
        }
        
        // Default configuration if no listener provided one
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    /// Get the bootstrap coordinator's ServiceManager.
    /// Called by SceneDelegate to get the ServiceManager with bootstrap services.
    var bootstrapServiceManager: ServiceManager? {
        bootstrapCoordinator.serviceManager
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Notify all registered listeners
        listenerCollection.notifyDidDiscardSceneSessions(application, sceneSessions: sceneSessions)
    }


}

