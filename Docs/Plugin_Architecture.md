# Ghost App Plugin Architecture

This document describes the modular plugin architecture used in the Ghost app and provides guidance for adding new plugins.

## Overview

The architecture uses a **declarative manifest system** where each module declares what it provides:
- **Services** - Business logic, data access, APIs
- **UI Contributions** - Views, view controllers, widgets
- **Lifecycle Participants** - Code that runs at specific app phases
- **Delegate Listeners** - Code that responds to AppDelegate/SceneDelegate events

```
┌─────────────────────────────────────────────────────────────┐
│                        AppManifest                          │
│  (Aggregates all module manifests)                          │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ WeatherManifest│    │ TabBarManifest│    │ ArtManifest   │
├───────────────┤    ├───────────────┤    ├───────────────┤
│ Services: [1] │    │ Services: [1] │    │ Services: [1] │
│ UI: [1]       │    │ UI: [1]       │    │ UI: [1]       │
│ Listeners: [1]│    │ Listeners: [] │    │ Listeners: [] │
└───────────────┘    └───────────────┘    └───────────────┘
```

## Core Protocols

### 1. Manifest

The central declaration for a module. Defines what the module contributes.

```swift
public protocol Manifest {
    static var serviceProviders: [ServiceProvider.Type] { get }
    static var uiProviders: [UIProvider.Type] { get }
    static var lifecycleParticipants: [LifecycleParticipant.Type] { get }
    static var appDelegateListeners: [AppDelegateListener.Type] { get }
    static var sceneDelegateListeners: [SceneDelegateListener.Type] { get }
}
```

All properties have default empty implementations, so you only declare what you need.

### 2. ServiceProvider

Registers services with the dependency injection container.

```swift
public protocol ServiceProvider {
    init()
    func registerServices(_ registry: ServiceRegistry)
}
```

### 3. UIProvider

Contributes UI elements to surfaces (tabs, widgets, main view).

```swift
public protocol UIProvider {
    init()
    func registerUI(_ registry: UIRegistryContributing)
}
```

### 4. LifecycleParticipant

Runs code at specific app lifecycle phases.

```swift
public protocol LifecycleParticipant {
    init()
    func run(phase: LifecyclePhase) async
}
```

Phases: `prewarm` → `launch` → `sceneConnect` → `postUI` → `backgroundRefresh`

### 5. SceneDelegateListener

Responds to scene lifecycle events and receives dependency injection.

```swift
public protocol SceneDelegateListener: AnyObject {
    init()
    func configure(with resolver: ServiceResolver)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) -> ServiceManagerProtocol?
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>)
    // ... other scene lifecycle methods
}
```

---

## Adding a New Plugin: Step-by-Step

### Step 1: Create the Manifest

Create a `Manifest.swift` file in your module:

```swift
import CoreContracts

public enum MyFeatureManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [MyFeatureServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        [MyFeatureUIProvider.self]
    }
}
```

### Step 2: Create ServiceProvider (if you have services)

```swift
public final class MyFeatureServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(MyFeatureService.self) {
            MyFeatureServiceImpl()
        }
    }
}
```

**With dependencies:**

```swift
registry.register(
    MyFeatureService.self,
    dependencies: (NetworkService.self, PersistenceService.self)
) { network, persistence in
    MyFeatureServiceImpl(network: network, persistence: persistence)
}
```

### Step 3: Create UIProvider (if you contribute UI)

**For a tab:**

```swift
public final class MyFeatureUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        guard let registry = registry as? TabBarUIContributing else { return }
        registry.contribute(
            to: .myTab,
            title: "My Feature",
            normalIcon: "star.fill",
            selectedIcon: nil,
            factory: { MyFeatureViewController() }
        )
    }
}
```

**For a widget with dependencies:**

```swift
registry.contribute(
    to: DashboardUISurface.widgets,
    contribution: MyWidgetContribution(),
    dependencies: (MyService.self, PersistenceService.self),
    factory: { myService, persistence in
        MyWidgetViewController(service: myService, persistence: persistence)
    }
)
```

### Step 4: Create SceneDelegateListener (if you need service access at runtime)

Use this when you need to:
- Register deeplink handlers
- Access services after app initialization
- Respond to URL opens

```swift
public final class MyFeatureSceneDelegateListener: SceneDelegateListener {
    private var myHandler: MyDeeplinkHandler?

    public required init() {}

    @MainActor
    public func configure(with resolver: ServiceResolver) {
        guard let myService = resolver.resolve(MyService.self),
              let deeplinkService = resolver.resolve(DeeplinkService.self) else {
            return
        }

        let handler = MyDeeplinkHandler(service: myService)
        self.myHandler = handler
        deeplinkService.register(handler: handler)
    }
}
```

### Step 5: Register in AppManifest

Add your manifest to the appropriate feature group in `Ghost/Kernel/AppManifest.swift`:

```swift
static var myFeature: [Manifest.Type] {
    [
        MyFeatureManifest.self,
        // ... other related manifests
    ]
}
```

And include the group in `allManifests`:

```swift
private static let allManifests: [Manifest.Type] = [
    core,
    dashboardFeature,
    myFeature  // Add here
].flatMap({ $0 })
```

---

## Common Patterns

### Pattern 1: Service + UI Module

Most common pattern. Provides a service and contributes UI.

```
MyFeature/
├── Manifest.swift           # MyFeatureManifest
├── Service/
│   ├── MyFeatureService.swift      # Protocol
│   └── MyFeatureServiceImpl.swift  # Implementation
└── UI/
    ├── MyFeatureUIProvider.swift
    └── MyFeatureViewController.swift
```

**Lines of boilerplate:** ~25

### Pattern 2: Service + Deeplink Handler

For modules that handle deeplinks.

```
MyFeature/
├── Manifest.swift           # Declares service + listener
├── MyFeatureService.swift
├── MyFeatureDeeplinkHandler.swift
└── MyFeatureSceneDelegateListener.swift
```

**Lines of boilerplate:** ~50

### Pattern 3: Pure Service Module

No UI, just provides a service for other modules.

```
MyService/
├── Manifest.swift
└── MyServiceProvider.swift
```

**Lines of boilerplate:** ~15

---

## Deeplink Handler Pattern

To handle deeplinks like `ghost://mytab/myfeature/action?param=value`:

### 1. Create the Handler

```swift
public final class MyFeatureDeeplinkHandler: DeeplinkHandler {
    public let feature = "myfeature"  // Matches path component

    private let myService: MyService

    public init(myService: MyService) {
        self.myService = myService
    }

    @MainActor
    public func handle(_ deeplink: Deeplink) -> Bool {
        guard deeplink.action == "action" else { return false }

        if let param = deeplink.parameter("param") {
            myService.doSomething(with: param)
            return true
        }
        return false
    }
}
```

### 2. Register via SceneDelegateListener

```swift
public final class MyFeatureSceneDelegateListener: SceneDelegateListener {
    private var handler: MyFeatureDeeplinkHandler?

    public required init() {}

    @MainActor
    public func configure(with resolver: ServiceResolver) {
        guard let myService = resolver.resolve(MyService.self),
              let deeplinkService = resolver.resolve(DeeplinkService.self) else {
            return
        }

        let handler = MyFeatureDeeplinkHandler(myService: myService)
        self.handler = handler
        deeplinkService.register(handler: handler)
    }
}
```

### 3. Add listener to Manifest

```swift
public enum MyFeatureManifest: Manifest {
    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [MyFeatureSceneDelegateListener.self]
    }
}
```

---

## Current Architecture Pain Points

### 1. SceneDelegateListener is verbose
- 7+ methods even though most are no-ops
- Required just to get `ServiceResolver` access

### 2. LifecycleParticipant can't access services
- Must use SceneDelegateListener instead for service injection
- Inconsistent with other patterns

### 3. Manual listener configuration
- SceneDelegate manually calls `configureListeners()`
- Extra step that could be automatic

### 4. No simple service registration
- Even single-line services need a full ServiceProvider class

---

## Initialization Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. AppDelegate.didFinishLaunching                            │
│    └── Bootstrap services registered                         │
├──────────────────────────────────────────────────────────────┤
│ 2. SceneDelegate.scene(willConnectTo:)                       │
│    └── Start async initialization                            │
├──────────────────────────────────────────────────────────────┤
│ 3. AppCoordinator.initialize()                               │
│    ├── Register all ServiceProviders                         │
│    ├── Register all UIProviders                              │
│    └── Register all LifecycleParticipants                    │
├──────────────────────────────────────────────────────────────┤
│ 4. LifecycleManager.runPhase(.prewarm)                       │
├──────────────────────────────────────────────────────────────┤
│ 5. LifecycleManager.runPhase(.launch)                        │
├──────────────────────────────────────────────────────────────┤
│ 6. LifecycleManager.runPhase(.sceneConnect)                  │
├──────────────────────────────────────────────────────────────┤
│ 7. Build UI (TabBarController, etc.)                         │
├──────────────────────────────────────────────────────────────┤
│ 8. configureListeners() - inject ServiceResolver             │
├──────────────────────────────────────────────────────────────┤
│ 9. notifyWillConnect() - handle cold-launch URLs             │
├──────────────────────────────────────────────────────────────┤
│ 10. LifecycleManager.runPhase(.postUI)                       │
└──────────────────────────────────────────────────────────────┘
```

---

## File Naming Conventions

| Type | Naming Pattern | Example |
|------|----------------|---------|
| Manifest | `Manifest.swift` | `Weather/Manifest.swift` |
| ServiceProvider | `*ServiceProvider.swift` | `WeatherServiceProvider.swift` |
| UIProvider | `*UIProvider.swift` | `WeatherUIProvider.swift` |
| Listener | `*SceneDelegateListener.swift` | `WeatherSceneDelegateListener.swift` |
| Deeplink Handler | `*DeeplinkHandler.swift` | `WeatherDeeplinkHandler.swift` |

---

## Quick Reference: Minimum Viable Plugin

The absolute minimum to add a new service:

```swift
// MyModule/Manifest.swift
import CoreContracts

public enum MyModuleManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [MyServiceProvider.self]
    }
}

public final class MyServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(MyService.self) { MyServiceImpl() }
    }
}
```

Then add to `AppManifest.swift`:
```swift
MyModuleManifest.self
```

**Total: ~15 lines + 1 line in AppManifest**
