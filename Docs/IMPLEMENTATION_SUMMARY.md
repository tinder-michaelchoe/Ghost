# Hybrid Module System Implementation Summary

## Overview

This implementation replaces the monolithic `AppPlugin` protocol with separate, focused protocols that modules can conform to based on what they provide. This improves maintainability, clarity, and follows the Interface Segregation Principle.

## Architecture

### Core Protocols (in CoreContracts)

1. **`ServiceProvider`**
   - `registerServices(_ registry: ServiceRegistry)`
   - For providers that register services
   - Services resolve dependencies at runtime via `AppContext`

2. **`UIProvider`**
   - `registerUI(_ registry: UIRegistry) async`
   - For providers that contribute UI (tabs, settings, etc.)

3. **`LifecycleParticipant`**
   - `run(phase: LifecyclePhase, context: AppContext) async`
   - For providers that need to participate in lifecycle phases

### Provider Examples

#### Service-Only Provider
```swift
public final class LoggingServiceProvider: ServiceProvider, LifecycleParticipant {
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(LoggingService.self, factory: { _ in
            ConsoleLogger()
        })
    }
    
    public func run(phase: LifecyclePhase, context: AppContext) async {
        // Lifecycle work
    }
}
```

#### UI-Only Provider
```swift
public final class HomeUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistry) async {
        // Register UI contributions
        // Can resolve services via context if needed
    }
}
```

#### Service with Dependencies
```swift
public final class AnalyticsServiceProvider: ServiceProvider {
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(AnalyticsService.self, factory: { context in
            // Resolve dependencies at runtime
            let logger = await context.services.resolve(LoggingService.self)!
            return AnalyticsServiceImpl(logger: logger)
        })
    }
}
```

### Discovery Mechanism

#### AppFoundation Modules
```swift
public enum AppFoundationModules {
    public static var serviceProviders: [ServiceProvider.Type] { [...] }
    public static var uiProviders: [UIProvider.Type] { [...] }
    public static var lifecycleParticipants: [LifecycleParticipant.Type] { [...] }
}
```

#### App Manifest
```swift
enum ModuleManifest {
    static var serviceProviders: [ServiceProvider.Type] {
        var providers: [ServiceProvider.Type] = []
        providers.append(contentsOf: AppFoundationModules.serviceProviders)
        // Add app-specific providers
        return providers
    }
    // Similar for other provider types
}
```

### AppCoordinator and Managers

The app uses a coordinator pattern with specialized managers:

**AppCoordinator** orchestrates initialization:
- Handles initialization sequence: services → context → UI → lifecycle
- Exposes managers for runtime access
- Manages AppContext lifecycle

**ServiceManager** manages service registration and resolution:
- Registers ServiceProvider instances
- Provides service resolution via ServiceContainer

**UIManager** manages UI contribution registration and querying:
- Registers UIProvider instances
- Provides UI contribution queries

**LifecycleManager** manages lifecycle participant execution:
- Registers LifecycleParticipant instances
- Executes lifecycle phases

Services handle their own dependencies at runtime via `AppContext`.

### Benefits

1. **Clear Intent**: Protocol conformance immediately shows what a module provides
2. **No Empty Implementations**: Modules only implement what they need
3. **Better Testability**: Test individual protocols in isolation
4. **Flexible Composition**: Modules can mix and match protocols
5. **Independent Evolution**: Add new provider types without changing existing code
6. **Type Safety**: Compiler enforces what each module provides
7. **Scalability**: Easier to manage as the system grows

### Migration Complete

- Old `AppPlugin` protocol has been removed
- All providers now use the separate protocols
- `PluginManager` replaced by `AppCoordinator` with specialized managers
- `PluginManifest` replaced by `AppManifest`
- `ModuleIdentity` removed - services resolve dependencies at runtime

## Files Created/Modified

### CoreContracts
- `ServiceProvider.swift` - Service registration protocol
- `UIProvider.swift` - UI contribution protocol
- `LifecycleParticipant.swift` - Lifecycle participation protocol

### Ghost App
- `AppCoordinator.swift` - Orchestrates initialization and exposes managers
- `ServiceManager.swift` - Manages service registration and resolution
- `UIManager.swift` - Manages UI contribution registration and querying
- `LifecycleManager.swift` - Manages lifecycle participant execution
- `AppManifest.swift` - Manifest aggregating all providers
- `SceneDelegate.swift` - Updated to use AppCoordinator

### AppFoundation
- `AppFoundation+ModuleProvider.swift` - Module discovery for AppFoundation
- `LoggingServiceProvider.swift` - Updated to use new protocols
- `AnalyticsServiceProvider.swift` - Updated to use new protocols

