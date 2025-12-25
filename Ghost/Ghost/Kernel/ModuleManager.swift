//
//  ModuleManager.swift
//  Ghost
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation
import CoreContracts

/// Manages module registration, dependency resolution, and lifecycle orchestration.
/// Works with separate provider protocols (ServiceProvider, UIProvider, etc.) instead of a monolithic AppPlugin.
final class ModuleManager {
    private let serviceContainer: ServiceContainerWrapper
    private let uiRegistry: UIRegistryImpl
    
    // Track all registered modules by their identity (if they have one)
    private var moduleInstances: [String: Any] = [:]
    private var modulesWithIdentity: [any ModuleIdentity.Type] = []
    
    // Track providers by type
    private var serviceProviders: [ServiceProvider] = []
    private var uiProviders: [UIProvider] = []
    private var lifecycleParticipants: [LifecycleParticipant] = []
    
    private var context: AppContext?
    
    init() {
        self.serviceContainer = ServiceContainerWrapper()
        self.uiRegistry = UIRegistryImpl()
    }
    
    /// Register modules from various sources.
    /// - Parameters:
    ///   - serviceProviders: Modules that provide services
    ///   - uiProviders: Modules that provide UI
    ///   - lifecycleParticipants: Modules that participate in lifecycle
    func registerModules(
        serviceProviders: [ServiceProvider.Type] = [],
        uiProviders: [UIProvider.Type] = [],
        lifecycleParticipants: [LifecycleParticipant.Type] = []
    ) async throws {
        // Collect all modules with identity for dependency resolution
        var allModulesWithIdentity: [any ModuleIdentity.Type] = []
        
        // Process service providers
        for providerType in serviceProviders {
            let instance = providerType.init() 
            self.serviceProviders.append(instance)
            
            // Track identity if present
            if let identity = providerType as? any ModuleIdentity.Type {
                allModulesWithIdentity.append(identity)
                let id = identity.id
                
                // Check for duplicates
                if moduleInstances[id] != nil {
                    throw ModuleError.duplicateModuleID(id)
                }
                
                moduleInstances[id] = instance
            }
        }
        
        // Process UI providers
        for providerType in uiProviders {
            let instance = providerType.init() 
            self.uiProviders.append(instance)
            
            // Track identity if present
            if let identity = providerType as? any ModuleIdentity.Type {
                allModulesWithIdentity.append(identity)
                let id = identity.id
                
                if moduleInstances[id] == nil {
                    moduleInstances[id] = instance
                }
            }
        }
        
        // Process lifecycle participants
        for participantType in lifecycleParticipants {
            let instance = participantType.init() 
            self.lifecycleParticipants.append(instance)
            
            // Track identity if present
            if let identity = participantType as? any ModuleIdentity.Type {
                allModulesWithIdentity.append(identity)
                let id = identity.id
                
                if moduleInstances[id] == nil {
                    moduleInstances[id] = instance
                }
            }
        }
        
        modulesWithIdentity = allModulesWithIdentity
        
        // Validate dependencies
        try validateDependencies()
        
        // Sort modules with identity by dependency order
        let sortedModules = try topologicalSort()
        
        // Create AppContext
        let config = AppConfig(
            buildInfo: BuildInfo(appVersion: "1.0", buildNumber: "1")
        )
        
        context = AppContext(
            services: ServiceResolverWrapper(container: serviceContainer, context: { [weak self] in self?.context }),
            config: config
        )
        
        guard let context = context else {
            throw ModuleError.contextCreationFailed
        }
        
        // Set context in service container for synchronous resolution
        serviceContainer.setContext(context)
        
        // Register all contributions
        await registerAllContributions()
    }
    
    /// Run all lifecycle participants through a lifecycle phase
    func runPhase(_ phase: LifecyclePhase) async {
        guard let context = context else {
            print("⚠️ No context available for phase \(phase)")
            return
        }
        
        for participant in lifecycleParticipants {
            await participant.run(phase: phase, context: context)
        }
    }
    
    func getUIRegistry() -> UIRegistryImpl {
        return uiRegistry
    }
    
    func getContext() -> AppContext? {
        return context
    }
    
    /// Get contributions for a surface (async)
    func getContributions<T: UISurface>(for surface: T) async -> [any ViewContribution] {
        await uiRegistry.getContributions(for: surface)
    }
    
    // MARK: - Private Helpers
    
    private func registerAllContributions() async {
        // Register services
        for provider in serviceProviders {
            provider.registerServices(self.serviceContainer)
        }
        
        // Register UI - await to ensure contributions are registered
        for provider in uiProviders {
            await provider.registerUI(self.uiRegistry)
        }
    }
    
    private func validateDependencies() throws {
        let moduleIDs = Set(modulesWithIdentity.map { $0.id })
        
        for moduleType in modulesWithIdentity {
            for dependency in moduleType.dependencies {
                let dependencyID = dependency.id
                if !moduleIDs.contains(dependencyID) {
                    throw ModuleError.missingDependency(moduleID: moduleType.id, requiredID: dependencyID)
                }
            }
        }
    }
    
    private func topologicalSort() throws -> [any ModuleIdentity.Type] {
        var sorted: [any ModuleIdentity.Type] = []
        var visited = Set<String>()
        var visiting = Set<String>()
        
        func visit(_ moduleID: String) throws {
            if visiting.contains(moduleID) {
                throw ModuleError.circularDependency(moduleID: moduleID)
            }
            
            if visited.contains(moduleID) {
                return
            }
            
            visiting.insert(moduleID)
            
            guard let moduleType = modulesWithIdentity.first(where: { $0.id == moduleID }) else {
                throw ModuleError.moduleNotFound(moduleID: moduleID)
            }
            
            for dependency in moduleType.dependencies {
                try visit(dependency.id)
            }
            
            visiting.remove(moduleID)
            visited.insert(moduleID)
            sorted.append(moduleType)
        }
        
        for moduleType in modulesWithIdentity {
            try visit(moduleType.id)
        }
        
        return sorted
    }
}

enum ModuleError: Error {
    case duplicateModuleID(String)
    case missingDependency(moduleID: String, requiredID: String)
    case circularDependency(moduleID: String)
    case moduleNotFound(moduleID: String)
    case contextCreationFailed
}

/// Wrapper to provide ServiceResolver that can resolve services with context
private final class ServiceResolverWrapper: ServiceResolver {
    private let container: ServiceContainerWrapper
    
    init(container: ServiceContainerWrapper, context: @escaping () -> AppContext?) {
        self.container = container
    }
    
    func resolve<T>(_ type: T.Type) async -> T? {
        return await container.resolve(type)
    }
}

