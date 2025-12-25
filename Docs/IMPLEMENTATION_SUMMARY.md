# Hybrid Module System Implementation Summary

## Overview

This implementation replaces the monolithic `AppPlugin` protocol with separate, focused protocols that modules can conform to based on what they provide. This improves maintainability, clarity, and follows the Interface Segregation Principle.

## Architecture

### Core Protocols (in CoreContracts)

1. **`ModuleIdentity`** (Optional)
   - Provides `id: String` and `dependencies: [any ModuleIdentity.Type]`
   - Used for dependency resolution and ordering
   - Modules only conform if they need identity/dependencies

2. **`ServiceProvider`**
   - `registerServices(_ registry: ServiceRegistry)`
   - For modules that register services

3. **`UIProvider`**
   - `registerUI(_ registry: UIRegistry)`
   - For modules that contribute UI (tabs, settings, etc.)

4. **`LifecycleParticipant`**
   - `run(phase: LifecyclePhase, context: AppContext) async`
   - For modules that need to participate in lifecycle phases

### Module Examples

#### Service-Only Module
```swift
public final class LoggingServiceProvider: ServiceProvider, LifecycleParticipant, ModuleIdentity {
    public static let id: String = "com.ghost.logging"
    public static let dependencies: [any ModuleIdentity.Type] = []
    
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

#### UI-Only Module
```swift
public final class HomeUIProvider: UIProvider, ModuleIdentity {
    public static let id: String = "com.ghost.home"
    public static let dependencies: [any ModuleIdentity.Type] = [
        LoggingServiceProvider.self
    ]
    
    public func registerUI(_ registry: UIRegistry) {
        // Register UI contributions
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

### ModuleManager

The `ModuleManager` replaces `PluginManager` and:
- Accepts separate arrays for each provider type
- Handles dependency resolution for modules with `ModuleIdentity`
- Registers contributions in parallel using TaskGroup
- Manages lifecycle phases for `LifecycleParticipant` modules

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
- All modules now use the separate protocols
- `PluginManager` replaced by `ModuleManager`
- `PluginManifest` replaced by `ModuleManifest`

## Files Created/Modified

### CoreContracts
- `ModuleIdentity.swift` - Identity and dependency protocol
- `ServiceProvider.swift` - Service registration protocol
- `UIProvider.swift` - UI contribution protocol
- `LifecycleParticipant.swift` - Lifecycle participation protocol

### Ghost App
- `ModuleManager.swift` - New manager using separate protocols
- `ModuleManifest.swift` - Manifest aggregating all modules
- `HomeUIProvider.swift` - Example UI-only module
- `SceneDelegate.swift` - Updated to use ModuleManager

### AppFoundation
- `AppFoundation+ModuleProvider.swift` - Module discovery for AppFoundation
- `LoggingServiceProvider.swift` - Updated to use new protocols
- `AnalyticsServiceProvider.swift` - Updated to use new protocols

