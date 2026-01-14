# GhostApp

A modular iOS application demonstrating a **declarative plugin architecture** with dependency injection, lifecycle management, and composable UI surfaces.

## Resources

- 📊 [Plugin Architecture Presentation](https://docs.google.com/presentation/d/1Zdmhh7rB7UMUu1pCrhvzjjPw2uMOUAhbzgWOrkJE0wc/edit?slide=id.g3b6a688d96b_0_0#slide=id.g3b6a688d96b_0_0)

## Architecture Overview

GhostApp uses a **thin app shell** pattern where the main app target (`Ghost`) contains minimal code—just the kernel that orchestrates feature modules. All business logic, services, and UI live in separate framework targets that declare their capabilities through **manifests**.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Ghost (App Target)                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                          Kernel                              │ │
│  │  AppDelegate → BootstrapCoordinator → SceneDelegate          │ │
│  │       ↓              ↓                    ↓                  │ │
│  │  AppManifest → ServiceManager → AppCoordinator               │ │
│  │       ↓              ↓               ↓                       │ │
│  │  [Manifests]   [ServiceRegistry]  [UIRegistry]               │ │
│  │                                   [LifecycleManager]         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↑
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ WeatherManifest│   │ DashboardManifest│  │ TabBarManifest│
├───────────────┤    ├───────────────┤    ├───────────────┤
│ Services: [1] │    │ Services: [0] │    │ Services: [1] │
│ UI: [1]       │    │ UI: [1]       │    │ UI: [1]       │
│ Listeners: [1]│    │ Listeners: [] │    │ Listeners: [] │
└───────────────┘    └───────────────┘    └───────────────┘
```

## Core Concepts

### The Thin App Target

The `Ghost` app target is intentionally minimal. It contains:

- **`AppDelegate`** - Entry point that bootstraps critical services and manages `AppDelegateListener` collection
- **`SceneDelegate`** - Orchestrates async initialization and manages `SceneDelegateListener` collection
- **`Kernel/`** - The orchestration layer:
  - `AppManifest` - Aggregates all module manifests
  - `BootstrapManifest` - Services that must load synchronously at launch
  - `AppCoordinator` - Orchestrates services → UI → lifecycle initialization
  - `ServiceManager` / `ServiceContainer` - Dependency injection container
  - `UIManager` / `UIRegistry` - UI contribution registry
  - `LifecycleManager` - Lifecycle phase orchestration

### Manifests

Manifests are the **declaration layer**. Each feature module declares what it provides through a `Manifest` conformance:

```swift
public protocol Manifest {
    static var serviceProviders: [ServiceProvider.Type] { get }
    static var uiProviders: [UIProvider.Type] { get }
    static var lifecycleParticipants: [LifecycleParticipant.Type] { get }
    static var appDelegateListeners: [AppDelegateListener.Type] { get }
    static var sceneDelegateListeners: [SceneDelegateListener.Type] { get }
}
```

All properties have default empty implementations, so modules only declare what they contribute.

**Example Manifest:**

```swift
public enum WeatherManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [WeatherServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        [WeatherUIProvider.self]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [WeatherSceneDelegateListener.self]
    }
}
```

### Registries

GhostApp uses three primary registries that collect and orchestrate contributions from modules:

#### 1. ServiceRegistry / ServiceManager

Manages dependency injection. Services register themselves and declare dependencies:

```swift
public protocol ServiceRegistry {
    // No dependencies
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    
    // With dependencies (resolved automatically)
    func register<T, each D>(
        _ type: T.Type,
        dependencies: (repeat (each D).Type),
        factory: @escaping (repeat each D) -> T
    )
}
```

#### 2. UIRegistry

Collects UI contributions to various surfaces. Supports both UIKit and SwiftUI:

```swift
public protocol UIRegistryContributing {
    // Query contributions
    func contributions<T: UISurface>(for surface: T) -> [ResolvedContribution]
    
    // Register UIKit view
    func contribute<S: UISurface, C: ViewContribution>(
        to surface: S,
        contribution: C,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    )
    
    // Register SwiftUI view
    func contribute<S: UISurface, C: ViewContribution, V: View>(
        to surface: S,
        contribution: C,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    )
    
    // With dependencies
    func contribute<S: UISurface, C: ViewContribution, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        factory: @escaping @MainActor @Sendable (repeat each D) -> UIViewController
    )
}
```

#### 3. LifecycleManager

Orchestrates app lifecycle phases. Participants run code at specific points:

```swift
public protocol LifecycleParticipant {
    init()
    func run(phase: LifecyclePhase) async
}

// Phases: prewarm → launch → sceneConnect → postUI → backgroundRefresh
```

#### 4. Delegate Listener Collections

- **`AppDelegateListenerCollection`** - Collects `AppDelegateListener` conformances for app-level events
- **`SceneDelegateListenerCollection`** - Collects `SceneDelegateListener` conformances for scene events

These allow modules to hook into delegate methods without modifying the thin app shell.

---

## Initialization Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. AppDelegate.didFinishLaunching                                │
│    └── BootstrapCoordinator registers critical services          │
│    └── AppDelegateListenerCollection notifies listeners          │
├──────────────────────────────────────────────────────────────────┤
│ 2. SceneDelegate.scene(willConnectTo:)                           │
│    └── Creates AppCoordinator with bootstrap ServiceManager      │
│    └── Starts async initialization                               │
├──────────────────────────────────────────────────────────────────┤
│ 3. AppCoordinator.initialize()                                   │
│    ├── Register all ServiceProviders from manifests              │
│    ├── Set ServiceResolver on UIRegistry                         │
│    ├── Register all UIProviders from manifests                   │
│    └── Register all LifecycleParticipants                        │
├──────────────────────────────────────────────────────────────────┤
│ 4. LifecycleManager.runPhase(.prewarm)                           │
├──────────────────────────────────────────────────────────────────┤
│ 5. LifecycleManager.runPhase(.launch)                            │
├──────────────────────────────────────────────────────────────────┤
│ 6. configureListeners() - inject ServiceResolver into listeners  │
├──────────────────────────────────────────────────────────────────┤
│ 7. SceneDelegateListenerCollection.notifyWillConnect()           │
├──────────────────────────────────────────────────────────────────┤
│ 8. LifecycleManager.runPhase(.sceneConnect)                      │
├──────────────────────────────────────────────────────────────────┤
│ 9. Build UI from UIRegistry contributions                        │
├──────────────────────────────────────────────────────────────────┤
│ 10. LifecycleManager.runPhase(.postUI)                           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Contributing Services

### Step 1: Define the Service Protocol

In `CoreContracts` (or your module if internal):

```swift
public protocol MyService {
    func doSomething() async throws -> Result
}
```

### Step 2: Create the Implementation

```swift
final class MyServiceImpl: MyService {
    private let network: NetworkClient
    
    init(network: NetworkClient) {
        self.network = network
    }
    
    func doSomething() async throws -> Result {
        // Implementation
    }
}
```

### Step 3: Create a ServiceProvider

```swift
public final class MyServiceProvider: ServiceProvider {
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        // No dependencies
        registry.register(MyService.self) {
            MyServiceImpl()
        }
        
        // With dependencies (resolved automatically)
        registry.register(
            MyOtherService.self,
            dependencies: (NetworkClient.self, PersistenceService.self)
        ) { network, persistence in
            MyOtherServiceImpl(network: network, persistence: persistence)
        }
    }
}
```

### Step 4: Add to Manifest

```swift
public enum MyModuleManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [MyServiceProvider.self]
    }
}
```

### Step 5: Register in AppManifest

In `Ghost/Kernel/AppManifest.swift`:

```swift
private static let allManifests: [Manifest.Type] = [
    core,
    dashboardFeature,
    // Add your manifest
].flatMap({ $0 })

static var myFeature: [Manifest.Type] {
    [MyModuleManifest.self]
}
```

---

## Contributing UI Surfaces

### Understanding UISurfaces

A `UISurface` is a slot where modules can contribute UI. Built-in surfaces include:

- `AppUISurface.mainView` - The root view controller
- `TabBarUISurface.dashboard`, `.cladsExamples`, etc. - Tab bar items
- `DashboardUISurface.widgets` - Widget contributions to the dashboard

### Step 1: Create a UIProvider

```swift
public final class MyUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistryContributing) {
        // Simple contribution (no dependencies)
        registry.contribute(
            to: DashboardUISurface.widgets,
            id: "my-widget",
            factory: {
                MyWidgetViewController()
            }
        )
    }
}
```

### Contributing with Dependencies

```swift
public func registerUI(_ registry: UIRegistryContributing) {
    registry.contribute(
        to: DashboardUISurface.widgets,
        contribution: MyWidgetContribution(),
        dependencies: (MyService.self, PersistenceService.self),
        factory: { myService, persistence in
            MyWidgetViewController(
                service: myService,
                persistence: persistence
            )
        }
    )
}
```

### Contributing a Tab

Use `TabBarUIContributing` for tab contributions:

```swift
public func registerUI(_ registry: UIRegistryContributing) {
    guard let registry = registry as? TabBarUIContributing else { return }
    
    registry.contribute(
        to: .myTab,
        title: "My Feature",
        normalIcon: "star.fill",
        selectedIcon: nil,
        factory: {
            MyFeatureViewController()
        }
    )
}
```

### Contributing SwiftUI Views

The registry automatically wraps SwiftUI views:

```swift
registry.contribute(
    to: DashboardUISurface.widgets,
    id: "my-swiftui-widget"
) {
    MySwiftUIWidget()
}
```

### Custom ViewContribution

For rich metadata, create a custom contribution type:

```swift
struct MyWidgetContribution: ViewContribution {
    let id = ViewContributionID(rawValue: "my-widget")
    // Add custom properties as needed
}
```

---

## Defining New UISurfaces

To create a new surface for other modules to contribute to:

```swift
// In CoreContracts or your module
public enum MyFeatureUISurface: UISurface {
    case cards
    case actions
}
```

Then query contributions in your feature:

```swift
let contributions = uiRegistry.contributions(for: MyFeatureUISurface.cards)
for resolved in contributions {
    let viewController = resolved.makeViewController().build() as? UIViewController
    // Use the contributed view
}
```

---

## Handling Deeplinks

### Step 1: Create a DeeplinkHandler

```swift
public final class MyDeeplinkHandler: DeeplinkHandler {
    public let feature = "myfeature"  // Matches ghost://tab/myfeature/...
    
    private let myService: MyService
    
    init(myService: MyService) {
        self.myService = myService
    }
    
    @MainActor
    public func handle(_ deeplink: Deeplink) -> Bool {
        guard deeplink.action == "open" else { return false }
        myService.handleDeeplink(deeplink)
        return true
    }
}
```

### Step 2: Register via SceneDelegateListener

```swift
public final class MySceneDelegateListener: SceneDelegateListener {
    private var handler: MyDeeplinkHandler?
    
    public required init() {}
    
    @MainActor
    public func configure(with resolver: ServiceResolver) {
        guard let myService = resolver.resolve(MyService.self),
              let deeplinkService = resolver.resolve(DeeplinkService.self) else {
            return
        }
        
        let handler = MyDeeplinkHandler(myService: myService)
        self.handler = handler
        deeplinkService.register(handler: handler)
    }
}
```

### Step 3: Add to Manifest

```swift
public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
    [MySceneDelegateListener.self]
}
```

---

## Project Structure

```
GhostApp/
├── Ghost/                      # Thin app target (kernel only)
│   └── Kernel/
│       ├── AppManifest.swift
│       ├── BootstrapManifest.swift
│       ├── AppCoordinator.swift
│       ├── ServiceManager.swift
│       ├── UIRegistry.swift
│       └── LifecycleManager.swift
├── CoreContracts/              # Shared protocols and contracts
│   └── Core/
│       ├── Manifest.swift
│       ├── ServiceProvider.swift
│       ├── UI/
│       └── AppLifecycle/
├── Weather/                    # Feature module
│   ├── Manifest.swift
│   ├── WeatherService.swift
│   └── Widget/
├── Dashboard/                  # Feature module
├── TabBar/                     # Feature module
├── Art/                        # Feature module
└── ...                         # Other feature modules
```

---

## Debugging

The kernel provides comprehensive debugging output. At startup, you'll see:

```
╔══════════════════════════════════════════════════════════════════╗
║          🔮 GHOST APP - ORCHESTRATOR STATE DUMP 🔮               ║
╠══════════════════════════════════════════════════════════════════╣
║  SERVICE CONTAINER - REGISTERED SERVICES                         ║
║  UI REGISTRY - REGISTERED CONTRIBUTIONS                          ║
║  LIFECYCLE MANAGER - REGISTERED PARTICIPANTS                     ║
╚══════════════════════════════════════════════════════════════════╝
```

This centralized visibility shows all registered services, UI contributions, and their dependencies.

---

## Module Checklist

When creating a new feature module:

- [ ] Create `Manifest.swift` conforming to `Manifest`
- [ ] Create `ServiceProvider` if providing services
- [ ] Create `UIProvider` if contributing UI
- [ ] Create `LifecycleParticipant` if needing lifecycle hooks
- [ ] Create `SceneDelegateListener` if handling deeplinks or needing service injection at runtime
- [ ] Add manifest to `AppManifest.swift`
- [ ] Add framework target to Xcode workspace

---

## Design Principles

1. **Declarative over Imperative** - Modules declare what they provide; the kernel handles orchestration
2. **Dependency Inversion** - Depend on protocols in `CoreContracts`, not concrete implementations
3. **Thin Shell** - App target contains only orchestration; all features live in modules
4. **Explicit Dependencies** - Dependencies are declared at registration time, enabling validation
5. **Composable Surfaces** - Any module can define surfaces for others to contribute to

---

## License

[Your License Here]
