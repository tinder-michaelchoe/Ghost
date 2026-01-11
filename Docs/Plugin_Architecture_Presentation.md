# Ghost App Plugin Architecture
## A Modular Approach to iOS Development

---

# Agenda

1. **Why Plugin Architecture?** - The problem we're solving
2. **Architecture Overview** - How it all fits together
3. **Integration Points** - Tab bar, widgets, deeplinks
4. **Lifecycle Management** - AppDelegate & SceneDelegate
5. **Ground Rules** - Contracts for external developers
6. **Testing** - Mock injection and test strategies
7. **Live Example** - Building a feature module
8. **Benefits** - For platform team and feature teams

---

# Part 1: Why Plugin Architecture?

---

## The Monolith Problem

### Before: Tight Coupling

```
┌─────────────────────────────────────────────┐
│                  AppDelegate                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ Weather │ │   Art   │ │ Sports  │ ...   │
│  │  knows  │ │  knows  │ │  knows  │       │
│  │ TabBar  │ │ TabBar  │ │ TabBar  │       │
│  └────┬────┘ └────┬────┘ └────┬────┘       │
│       │           │           │             │
│       └───────────┴───────────┘             │
│              Hard-coded                     │
└─────────────────────────────────────────────┘
```

**Problems:**
- Every feature knows about every other feature
- AppDelegate becomes a god object
- Build times scale linearly with features
- Merge conflicts on shared files
- Can't build/test features in isolation

---

## The Plugin Solution

### After: Loose Coupling

```
┌─────────────────────────────────────────────┐
│              Platform Kernel                │
│  ┌─────────────────────────────────────┐   │
│  │   ServiceManager + UIManager        │   │
│  │   LifecycleManager + Coordinators   │   │
│  └─────────────────────────────────────┘   │
└──────────────────┬──────────────────────────┘
                   │ Protocols (CoreContracts)
       ┌───────────┼───────────┐
       ▼           ▼           ▼
   ┌───────┐   ┌───────┐   ┌───────┐
   │Weather│   │  Art  │   │Sports │
   │Module │   │Module │   │Module │
   └───────┘   └───────┘   └───────┘

   Each module only knows about CoreContracts
```

**Benefits:**
- Features are isolated
- Build in parallel
- Test independently
- Ship on different cadences

---

## Ownership Model

| Component | Owner | Responsibilities |
|-----------|-------|------------------|
| Ghost App Target | Platform | App lifecycle, coordination |
| CoreContracts | Platform | Protocols, contracts, types |
| AppFoundation | Platform | Logging, analytics, core utilities |
| NetworkClient | Platform | HTTP client, caching |
| Persistence | Platform | Data storage |
| TabBar | Platform | Navigation infrastructure |
| **Feature Modules** | **Feature Teams** | **Business logic, UI** |

---

# Part 2: Architecture Overview

---

## The Manifest System

Every module declares what it provides through a **Manifest**:

```swift
public enum WeatherManifest: Manifest {

    // Services this module provides
    public static var serviceProviders: [ServiceProvider.Type] {
        [WeatherServiceProvider.self]
    }

    // UI contributions (widgets, tabs)
    public static var uiProviders: [UIProvider.Type] {
        [WeatherUIProvider.self]
    }

    // Lifecycle event handlers
    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [WeatherSceneDelegateListener.self]
    }
}
```

**Key insight:** Modules *declare* what they provide, the platform *discovers* and *orchestrates*.

---

## Manifest Aggregation

```
AppManifest (Ghost Target)
    │
    ├── Core
    │   ├── TabBarManifest
    │   ├── DeeplinkingManifest
    │   └── AppFoundationManifest
    │
    └── Features
        ├── WeatherManifest
        ├── ArtManifest
        ├── SportsManifest
        └── DashboardManifest
```

All manifests are aggregated in one place - **the only file feature teams touch in Ghost target**.

```swift
// AppManifest.swift - Platform owned
static var all: [Manifest.Type] {
    core + features
}

static var features: [Manifest.Type] {
    [WeatherManifest.self, ArtManifest.self, ...]
}
```

---

## The Five Provider Types

| Provider Type | Purpose | Example |
|--------------|---------|---------|
| `ServiceProvider` | Register services | WeatherService, AnalyticsService |
| `UIProvider` | Contribute UI | Widgets, tab content |
| `LifecycleParticipant` | Run code at phases | Pre-warm caches, start observers |
| `AppDelegateListener` | App-wide events | Push notifications, shortcuts |
| `SceneDelegateListener` | Scene events | Deeplinks, state restoration |

---

## Dependency Injection

Services depend on **protocols**, not implementations:

```swift
public final class WeatherServiceProvider: ServiceProvider {

    public func registerServices(_ registry: ServiceRegistry) {

        // Simple service - no dependencies
        registry.register(WeatherService.self) {
            NWSWeatherService()
        }

        // Service with dependencies
        registry.register(
            WeatherAnalytics.self,
            dependencies: (AnalyticsService.self, WeatherService.self),
            factory: { analytics, weather in
                WeatherAnalyticsImpl(analytics: analytics, weather: weather)
            }
        )
    }
}
```

**Type-safe:** Compiler catches missing dependencies at build time.

---

# Part 3: Integration Points

---

## How Do I Add a Tab?

The TabBar module defines **surfaces** that other modules contribute to:

```swift
// Platform defines the surface
public enum TabBarUISurface: UISurface {
    case home
    case builder
    case dashboard
    case settings
}
```

```swift
// Your module contributes to it
public final class MyFeatureUIProvider: UIProvider {

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(
            to: TabBarUISurface.home,
            contribution: HomeTabContribution(
                title: "Home",
                icon: UIImage(systemName: "house")
            ),
            factory: {
                HomeViewController()
            }
        )
    }
}
```

---

## How Do I Add a Widget?

Dashboard defines a widget surface:

```swift
// Platform defines
public enum DashboardUISurface: UISurface {
    case widgets
}
```

```swift
// Your module contributes
public final class WeatherUIProvider: UIProvider {

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(
            to: DashboardUISurface.widgets,
            contribution: WeatherWidgetContribution(),
            dependencies: (WeatherService.self, LocationService.self),
            factory: { weatherService, locationService in
                WeatherWidgetViewController(
                    weatherService: weatherService,
                    locationService: locationService
                )
            }
        )
    }
}
```

**Note:** Dependencies are injected automatically by the platform.

---

## How Do I Handle Deeplinks?

### Step 1: Implement DeeplinkHandler

```swift
public final class WeatherDeeplinkHandler: DeeplinkHandler {

    public let feature = "weather"  // Matches URL path

    @MainActor
    public func handle(_ deeplink: Deeplink) async -> Bool {
        // ghost://dashboard/weather/city?name=Chicago
        guard deeplink.action == "city",
              let cityName = deeplink.parameter("name") else {
            return false
        }

        await switchToCity(cityName)
        return true
    }
}
```

---

## How Do I Handle Deeplinks? (cont.)

### Step 2: Register in SceneDelegateListener

```swift
public final class WeatherSceneDelegateListener: SceneDelegateListener {

    private var handler: WeatherDeeplinkHandler?

    @MainActor
    public func configure(with resolver: ServiceResolver) {
        guard let deeplinkService = resolver.resolve(DeeplinkService.self),
              let persistence = resolver.resolve(PersistenceService.self) else {
            return
        }

        let handler = WeatherDeeplinkHandler(persistence: persistence)
        self.handler = handler

        deeplinkService.register(handler: handler)
    }
}
```

### Step 3: Declare in Manifest

```swift
public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
    [WeatherSceneDelegateListener.self]
}
```

---

## Deeplink URL Format

```
ghost://[tab]/[feature]/[action]?[parameters]
        ─┬──   ───┬───   ──┬───   ────┬─────
         │        │        │          │
         │        │        │          └─ Query params (key=value)
         │        │        └─ Action within feature
         │        └─ Feature handler to invoke
         └─ Tab to navigate to first
```

**Examples:**
- `ghost://dashboard` → Navigate to dashboard
- `ghost://dashboard/weather/city?name=Chicago` → Weather + city
- `ghost://settings/account/delete` → Settings → Account → Delete

---

# Part 4: Lifecycle Management

---

## Complete Initialization Sequence

```
┌─────────────────────────────────────────────────────────┐
│ 1. AppDelegate.didFinishLaunching                       │
│    └─ Bootstrap services (logging, crash reporting)    │
│    └─ Returns immediately                               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ 2. SceneDelegate.willConnectTo                          │
│    ├─ Create window (sync)                              │
│    └─ Start initialization Task (async)                │
│        │                                                │
│        ├─ Register all services                        │
│        ├─ Run .prewarm phase                           │
│        ├─ Run .launch phase ← Deeplink handlers here   │
│        ├─ Run .sceneConnect phase                      │
│        ├─ Build UI from contributions                  │
│        ├─ Set rootViewController                       │
│        ├─ Configure listeners with dependencies        │
│        ├─ Notify listeners of pending URLs             │
│        └─ Run .postUI phase                            │
└─────────────────────────────────────────────────────────┘
```

---

## Lifecycle Phases

| Phase | When | Use For |
|-------|------|---------|
| `.prewarm` | Before main UI | Load config, pre-warm caches |
| `.launch` | App launching | Register deeplink handlers |
| `.sceneConnect` | Scene connected | Scene-specific setup |
| `.postUI` | After UI visible | Start analytics, observers |
| `.backgroundRefresh` | Background task | Sync data, refresh content |

```swift
public final class MyLifecycleParticipant: LifecycleParticipant {

    public func run(phase: LifecyclePhase) async {
        switch phase {
        case .prewarm:
            await preloadCriticalData()
        case .postUI:
            startAnalyticsSession()
        default:
            break
        }
    }
}
```

---

## SceneDelegateListener Events

```swift
public protocol SceneDelegateListener: AnyObject {

    // Called after services registered, before events
    func configure(with resolver: ServiceResolver)

    // Scene lifecycle
    func scene(_:willConnectTo:options:) -> ServiceManagerProtocol?
    func scene(_:openURLContexts:)  // Deeplinks when running
    func sceneDidBecomeActive(_:)
    func sceneWillResignActive(_:)
    func sceneWillEnterForeground(_:)
    func sceneDidEnterBackground(_:)
    func sceneDidDisconnect(_:)
}
```

All methods have **default empty implementations** - implement only what you need.

---

## Why Async/Await?

### Before: Delay-based coordination
```swift
// Bad: Magic numbers, race conditions
func handleDeeplink() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        presentSheet()  // Hope the tab switched by now!
    }
}
```

### After: Explicit async coordination
```swift
// Good: Explicit waiting, no magic numbers
func handle(_ deeplink: Deeplink) async -> Bool {
    guard let presenter = await navigationService.switchToTab("dashboard") else {
        return false
    }
    presenter.present(sheet, animated: true)
    return true
}
```

---

# Part 5: Ground Rules for External Developers

---

## The Contract

### You Provide:

1. **A Manifest** declaring your module's capabilities
2. **ServiceProviders** for your business logic
3. **UIProviders** for your UI contributions
4. **Listeners** for lifecycle events you care about

### Platform Provides:

1. **Discovery** of your manifest
2. **Dependency resolution** for your services
3. **UI surface orchestration** for your contributions
4. **Lifecycle coordination** for your listeners

---

## Rules of Engagement

### DO:

✅ Depend only on protocols from `CoreContracts`
✅ Declare all dependencies explicitly in providers
✅ Use async/await for coordination
✅ Register deeplink handlers during `.configure(with:)`
✅ Keep your Manifest as the single source of truth

### DON'T:

❌ Import other feature modules directly
❌ Access UIApplication.shared for navigation
❌ Use NotificationCenter for cross-module communication
❌ Hard-code delays for timing coordination
❌ Create singletons for service access

---

## Service Boundaries

### What You Can Depend On:

```swift
// CoreContracts protocols - ALLOWED
import CoreContracts

registry.register(
    MyService.self,
    dependencies: (
        NetworkClient.self,      // Platform service ✅
        PersistenceService.self, // Platform service ✅
        LoggingService.self      // Platform service ✅
    ),
    factory: { network, persistence, logging in
        MyServiceImpl(...)
    }
)
```

### What You Cannot Do:

```swift
// Direct import of another feature - NOT ALLOWED
import Weather  // ❌

let weatherService = WeatherServiceImpl()  // ❌ Direct instantiation
```

---

## Cross-Module Communication

### Option 1: Shared Protocol (Recommended)

```swift
// In CoreContracts (platform-owned)
public protocol WeatherDataProvider {
    func currentTemperature() async -> Double?
}

// Weather module implements it
// Sports module depends on it (protocol only)
```

### Option 2: Deeplinks

```swift
// Sports module wants weather data
let url = URL(string: "ghost://dashboard/weather/current")!
UIApplication.shared.open(url)
```

### Option 3: Service Events (via Platform)

Platform can provide event bus protocols if needed.

---

# Part 6: Testing

---

## Why Testing Is Easier Now

### Before: Testing Required the Whole App

```swift
// Old way: Need to boot entire app to test one service
class WeatherTests: XCTestCase {
    var app: XCUIApplication!

    func testWeather() {
        app.launch()  // Loads EVERYTHING
        // Hope nothing else interferes...
    }
}
```

### After: Test in Complete Isolation

```swift
// New way: Instantiate exactly what you need
class WeatherTests: XCTestCase {
    func testWeather() async {
        let service = NWSWeatherService(network: MockNetwork())
        // Test with zero app dependencies
    }
}
```

---

## The Testing Pyramid

```
                    ┌─────────┐
                    │   E2E   │  Few: Full app integration
                   ─┴─────────┴─
                 ┌───────────────┐
                 │  Integration  │  Some: Module + real deps
                ─┴───────────────┴─
              ┌───────────────────────┐
              │     Unit Tests        │  Many: Isolated classes
              └───────────────────────┘
```

**Plugin architecture makes unit tests trivial** - services have no hidden dependencies.

---

## Creating Mock Dependencies

### Step 1: Protocol-Based Design (Already Done!)

```swift
// CoreContracts defines the protocol
public protocol NetworkClient {
    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T
}

// Your service depends on the PROTOCOL
public final class NWSWeatherService: WeatherService {
    private let network: NetworkClient  // Protocol, not concrete type

    public init(network: NetworkClient) {
        self.network = network
    }
}
```

---

## Creating Mock Dependencies (cont.)

### Step 2: Create Mocks in Your Test Target

```swift
// In WeatherTests/Mocks/MockNetworkClient.swift
final class MockNetworkClient: NetworkClient {

    // Control what the mock returns
    var mockResponse: Any?
    var mockError: Error?
    var capturedRequests: [URLRequest] = []

    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        capturedRequests.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            fatalError("Mock not configured for type \(T.self)")
        }
        return response
    }
}
```

---

## Unit Testing Services

```swift
final class WeatherServiceTests: XCTestCase {

    var sut: NWSWeatherService!  // System Under Test
    var mockNetwork: MockNetworkClient!
    var mockPersistence: MockPersistenceService!

    override func setUp() {
        mockNetwork = MockNetworkClient()
        mockPersistence = MockPersistenceService()

        // Direct instantiation - no container needed!
        sut = NWSWeatherService(
            network: mockNetwork,
            persistence: mockPersistence
        )
    }

    func testFetchWeather_Success() async throws {
        // Arrange
        mockNetwork.mockResponse = WeatherResponse(temp: 72, condition: "Sunny")

        // Act
        let weather = try await sut.fetchWeather(for: .newYork)

        // Assert
        XCTAssertEqual(weather.temperature, 72)
        XCTAssertEqual(mockNetwork.capturedRequests.count, 1)
    }

    func testFetchWeather_NetworkError_ReturnsCached() async throws {
        // Arrange
        mockNetwork.mockError = URLError(.notConnectedToInternet)
        mockPersistence.mockCachedWeather = WeatherResponse(temp: 68, condition: "Cloudy")

        // Act
        let weather = try await sut.fetchWeather(for: .newYork)

        // Assert
        XCTAssertEqual(weather.temperature, 68)  // Fell back to cache
    }
}
```

---

## Testing Deeplink Handlers

```swift
final class WeatherDeeplinkHandlerTests: XCTestCase {

    var sut: WeatherDeeplinkHandler!
    var mockPersistence: MockPersistenceService!

    override func setUp() {
        mockPersistence = MockPersistenceService()
        sut = WeatherDeeplinkHandler(persistence: mockPersistence)
    }

    func testHandle_CityAction_SetsLocation() async {
        // Arrange
        let url = URL(string: "ghost://dashboard/weather/city?name=Chicago")!
        let deeplink = Deeplink(url: url)!

        // Act
        let handled = await sut.handle(deeplink)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPersistence.savedLocation?.name, "Chicago")
    }

    func testHandle_UnknownAction_ReturnsFalse() async {
        // Arrange
        let url = URL(string: "ghost://dashboard/weather/unknown")!
        let deeplink = Deeplink(url: url)!

        // Act
        let handled = await sut.handle(deeplink)

        // Assert
        XCTAssertFalse(handled)
    }
}
```

---

## Integration Testing with Test Container

For tests that need multiple real services working together:

```swift
final class WeatherIntegrationTests: XCTestCase {

    var container: TestServiceContainer!

    override func setUp() {
        container = TestServiceContainer()

        // Register real services
        container.register(PersistenceService.self) {
            InMemoryPersistenceService()  // Real impl, in-memory storage
        }

        // Register mocks for external dependencies
        container.register(NetworkClient.self) {
            MockNetworkClient()
        }

        // Register the service under test with real dependencies
        container.register(WeatherService.self) {
            NWSWeatherService(
                network: container.resolve(NetworkClient.self)!,
                persistence: container.resolve(PersistenceService.self)!
            )
        }
    }

    func testWeatherServiceIntegration() async throws {
        let weatherService = container.resolve(WeatherService.self)!
        let persistence = container.resolve(PersistenceService.self)!

        // Test that weather service correctly persists data
        _ = try await weatherService.fetchWeather(for: .chicago)

        let cached = persistence.getCachedWeather(for: .chicago)
        XCTAssertNotNil(cached)
    }
}
```

---

## Testing UIProviders

```swift
final class WeatherUIProviderTests: XCTestCase {

    func testRegisterUI_ContributesToWidgetSurface() {
        // Arrange
        let mockRegistry = MockUIRegistry()
        let provider = WeatherUIProvider()

        // Act
        provider.registerUI(mockRegistry)

        // Assert
        XCTAssertEqual(mockRegistry.contributions.count, 1)

        let contribution = mockRegistry.contributions.first!
        XCTAssertEqual(contribution.surface, DashboardUISurface.widgets)
        XCTAssertEqual(contribution.id, "weather-widget")
    }
}

// Mock registry captures registrations
final class MockUIRegistry: UIRegistryContributing {
    var contributions: [(surface: Any, id: String)] = []

    func contribute<S: UISurface, C: ViewContribution>(
        to surface: S,
        contribution: C,
        factory: @escaping () -> UIViewController
    ) {
        contributions.append((surface, contribution.id))
    }
    // ... other overloads
}
```

---

## Testing View Controllers

```swift
final class WeatherWidgetViewControllerTests: XCTestCase {

    var sut: WeatherWidgetViewController!
    var mockService: MockWeatherService!

    override func setUp() {
        mockService = MockWeatherService()
        sut = WeatherWidgetViewController(service: mockService)
    }

    func testViewDidLoad_FetchesWeather() async {
        // Arrange
        mockService.mockWeather = WeatherResponse(temp: 75, condition: "Sunny")

        // Act
        sut.loadViewIfNeeded()
        await Task.yield()  // Let async work complete

        // Assert
        XCTAssertTrue(mockService.fetchWeatherCalled)
    }

    func testDisplaysTemperature() async {
        // Arrange
        mockService.mockWeather = WeatherResponse(temp: 75, condition: "Sunny")

        // Act
        sut.loadViewIfNeeded()
        await Task.yield()

        // Assert
        XCTAssertEqual(sut.temperatureLabel.text, "75°")
    }
}
```

---

## Snapshot Testing (Optional)

```swift
import SnapshotTesting

final class WeatherWidgetSnapshotTests: XCTestCase {

    func testWeatherWidget_Sunny() {
        let mockService = MockWeatherService()
        mockService.mockWeather = WeatherResponse(temp: 75, condition: "Sunny")

        let vc = WeatherWidgetViewController(service: mockService)
        vc.loadViewIfNeeded()

        assertSnapshot(matching: vc, as: .image(on: .iPhone13))
    }

    func testWeatherWidget_Rainy() {
        let mockService = MockWeatherService()
        mockService.mockWeather = WeatherResponse(temp: 58, condition: "Rainy")

        let vc = WeatherWidgetViewController(service: mockService)
        vc.loadViewIfNeeded()

        assertSnapshot(matching: vc, as: .image(on: .iPhone13))
    }
}
```

---

## Test Harness for Full Module Testing

Platform provides a `TestHarness` module for running modules in isolation:

```swift
import TestHarness

final class WeatherModuleTests: XCTestCase {

    var harness: TestHarness!

    override func setUp() async throws {
        harness = TestHarness()

        // Load ONLY your module's manifest
        try await harness.load(manifest: WeatherManifest.self)

        // Override specific services with mocks
        harness.override(NetworkClient.self) { MockNetworkClient() }
    }

    func testModuleInitialization() async {
        // Verify service was registered
        let weatherService = harness.resolve(WeatherService.self)
        XCTAssertNotNil(weatherService)
    }

    func testDeeplinkHandlerRegistered() async {
        // Simulate lifecycle
        await harness.runPhase(.launch)

        // Verify deeplink handler works
        let handled = await harness.handleDeeplink("ghost://dashboard/weather/city?name=NYC")
        XCTAssertTrue(handled)
    }
}
```

---

## Testing Best Practices

### DO:

✅ **Keep services injectable** - All dependencies via initializer
✅ **Create mocks per test target** - Don't share mocks across modules
✅ **Test behaviors, not implementation** - Focus on inputs/outputs
✅ **Use async/await in tests** - Match production code patterns
✅ **Name tests clearly** - `test[Method]_[Scenario]_[Expected]`

### DON'T:

❌ **Don't test the framework** - Trust ServiceContainer works
❌ **Don't mock what you own** - Use real implementations when simple
❌ **Don't test private methods** - Test through public interface
❌ **Don't rely on test order** - Each test should be independent

---

## Test File Organization

```
Weather/
├── Weather/
│   ├── Services/
│   │   └── NWSWeatherService.swift
│   └── UI/
│       └── WeatherWidgetViewController.swift
│
└── WeatherTests/
    ├── Mocks/
    │   ├── MockNetworkClient.swift
    │   ├── MockPersistenceService.swift
    │   └── MockWeatherService.swift
    │
    ├── Services/
    │   └── NWSWeatherServiceTests.swift
    │
    ├── Deeplinks/
    │   └── WeatherDeeplinkHandlerTests.swift
    │
    ├── UI/
    │   └── WeatherWidgetViewControllerTests.swift
    │
    └── Integration/
        └── WeatherIntegrationTests.swift
```

---

## Coverage Expectations

| Layer | Coverage Target | Notes |
|-------|-----------------|-------|
| Services | 80%+ | Core business logic |
| Deeplink Handlers | 90%+ | All URL patterns |
| View Controllers | 60%+ | Focus on logic, not layout |
| Providers | Low priority | Mostly declarative |
| Manifest | Don't test | Just declarations |

---

# Part 8: Live Example

---

## Building a "Sports Scores" Module

### Step 1: Create the Module Structure

```
Sports/
├── Sports/
│   ├── Manifest.swift
│   ├── Services/
│   │   ├── SportsService.swift
│   │   └── SportsServiceProvider.swift
│   ├── UI/
│   │   ├── SportsWidgetViewController.swift
│   │   └── SportsUIProvider.swift
│   └── Deeplinks/
│       ├── SportsDeeplinkHandler.swift
│       └── SportsSceneDelegateListener.swift
└── Sports.xcodeproj
```

---

## Step 2: Define the Manifest

```swift
// Manifest.swift
import CoreContracts

public enum SportsManifest: Manifest {

    public static var serviceProviders: [ServiceProvider.Type] {
        [SportsServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        [SportsUIProvider.self]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [SportsSceneDelegateListener.self]
    }
}
```

**~15 lines of code**

---

## Step 3: Implement ServiceProvider

```swift
// SportsServiceProvider.swift
import CoreContracts

public final class SportsServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(
            SportsService.self,
            dependencies: (NetworkClient.self,),
            factory: { network in
                ESPNSportsService(network: network)
            }
        )
    }
}
```

**~15 lines of code**

---

## Step 4: Implement UIProvider

```swift
// SportsUIProvider.swift
import CoreContracts
import UIKit

public final class SportsUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(
            to: DashboardUISurface.widgets,
            contribution: SportsWidgetContribution(),
            dependencies: (SportsService.self,),
            factory: { sportsService in
                SportsWidgetViewController(service: sportsService)
            }
        )
    }
}
```

**~20 lines of code**

---

## Step 5: Implement Deeplink Handler

```swift
// SportsDeeplinkHandler.swift
import CoreContracts

public final class SportsDeeplinkHandler: DeeplinkHandler {
    public let feature = "sports"

    private let service: SportsService

    init(service: SportsService) {
        self.service = service
    }

    @MainActor
    public func handle(_ deeplink: Deeplink) async -> Bool {
        // ghost://dashboard/sports/team?name=Lakers
        guard deeplink.action == "team",
              let teamName = deeplink.parameter("name") else {
            return false
        }

        await service.setFavoriteTeam(teamName)
        return true
    }
}
```

---

## Step 6: Register in AppManifest

```swift
// In Ghost/AppManifest.swift (one-line change)
static var features: [Manifest.Type] {
    [
        WeatherManifest.self,
        ArtManifest.self,
        SportsManifest.self,  // ← Add this line
        DashboardManifest.self
    ]
}
```

**Total boilerplate: ~50-70 lines**
**Business logic: As much as you need**

---

# Part 9: Benefits

---

## Benefits for Platform Team

### 1. Clear Boundaries
- Platform owns contracts (CoreContracts)
- Features can't break each other
- Changes to platform are explicit protocol changes

### 2. Simplified Maintenance
- AppDelegate/SceneDelegate stay thin
- No feature-specific code in kernel
- Easy to audit what modules provide

### 3. Controlled Evolution
- New capabilities = new protocols
- Deprecation path is clear
- Breaking changes are compile-time errors

### 4. Performance Control
- Lifecycle phases are deterministic
- Can profile initialization per-phase
- Lazy service instantiation

---

## Benefits for Feature Teams

### 1. Reduced Interface
- Only need to know 5 protocols
- Don't need to understand app lifecycle details
- Clear "fill in the blanks" pattern

### 2. True Isolation
- Build module independently
- Test without app context
- Deploy on your schedule

### 3. Dependency Safety
- Compiler catches missing dependencies
- No runtime crashes from missing services
- Clear what you can depend on

### 4. Self-Service Integration
- Add tab? Implement UIProvider
- Handle deeplink? Implement DeeplinkHandler
- Run at startup? Implement LifecycleParticipant

---

## Benefits for the Organization

### 1. Parallel Development
```
Week 1:  [Platform: Core]  [Weather: Service]  [Sports: Design]
Week 2:  [Platform: UI]    [Weather: Widget]   [Sports: Service]
Week 3:  [Platform: Test]  [Weather: Test]     [Sports: Widget]
         ─────────────────────────────────────────────────────
         All teams work in parallel, no blocking
```

### 2. Clear Ownership
- Platform team: Ghost, CoreContracts, Foundation
- Feature teams: Their module only
- No ambiguity about responsibility

### 3. Scalable Architecture
- 5 modules or 50 modules - same pattern
- New team? Hand them the template
- Onboarding time: Days, not weeks

---

## The Reduced Interface Advantage

### Old Way: "Learn the whole app"
- Understand AppDelegate flow
- Know which services exist where
- Learn navigation stack management
- Figure out how to register for events

### New Way: "Implement these protocols"

```swift
// That's it. These 5 protocols are your entire interface.
Manifest              // Declare capabilities
ServiceProvider       // Register services
UIProvider            // Contribute UI
LifecycleParticipant  // Run at phases
SceneDelegateListener // Handle events
```

**The less you need to know, the faster you ship.**

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Coupling | Tight | Loose |
| Testing | Hard | Easy |
| Onboarding | Weeks | Days |
| Build Times | Linear | Parallel |
| Merge Conflicts | Frequent | Rare |
| Feature Independence | None | Complete |

---

# Questions?

## Resources

- `/Docs/Plugin_Architecture.md` - Full architecture guide
- `/Docs/Deeplinking_Architecture.md` - Deeplink system
- `/Docs/AppDelegate_SceneDelegate_Diagram.md` - Lifecycle diagrams
- `CoreContracts/` - All protocol definitions

## Contact

Platform Team: #platform-ios

---

# Appendix

---

## A: Quick Reference - Manifest Protocol

```swift
public protocol Manifest {
    static var serviceProviders: [ServiceProvider.Type] { get }
    static var uiProviders: [UIProvider.Type] { get }
    static var lifecycleParticipants: [LifecycleParticipant.Type] { get }
    static var appDelegateListeners: [AppDelegateListener.Type] { get }
    static var sceneDelegateListeners: [SceneDelegateListener.Type] { get }
}

// All have default empty implementations
```

---

## B: Quick Reference - ServiceProvider

```swift
public protocol ServiceProvider {
    init()
    func registerServices(_ registry: ServiceRegistry)
}

public protocol ServiceRegistry {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)

    func register<T, each D>(
        _ type: T.Type,
        dependencies: (repeat (each D).Type),
        factory: @escaping (repeat each D) -> T
    )
}
```

---

## C: Quick Reference - UIProvider

```swift
public protocol UIProvider {
    init()
    func registerUI(_ registry: UIRegistryContributing)
}

public protocol UIRegistryContributing {
    func contribute<S: UISurface, C: ViewContribution>(
        to surface: S,
        contribution: C,
        factory: @escaping @MainActor () -> UIViewController
    )

    func contribute<S: UISurface, C: ViewContribution, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        factory: @escaping @MainActor (repeat each D) -> UIViewController
    )
}
```

---

## D: Quick Reference - Lifecycle

```swift
public protocol LifecycleParticipant {
    init()
    func run(phase: LifecyclePhase) async
}

public enum LifecyclePhase {
    case prewarm
    case launch
    case sceneConnect
    case postUI
    case backgroundRefresh
}
```

---

## E: Quick Reference - Deeplinks

```swift
public protocol DeeplinkHandler: AnyObject {
    var feature: String { get }
    @MainActor func handle(_ deeplink: Deeplink) async -> Bool
}

public struct Deeplink {
    let scheme: String        // "ghost"
    let tab: String?          // "dashboard"
    let feature: String?      // "weather"
    let action: String?       // "city"
    let queryParameters: [String: String]
}
```

---

## F: Module Checklist

- [ ] Create module folder structure
- [ ] Define `Manifest.swift`
- [ ] Implement `ServiceProvider` (if providing services)
- [ ] Implement `UIProvider` (if contributing UI)
- [ ] Implement `LifecycleParticipant` (if needed)
- [ ] Implement `SceneDelegateListener` (if handling events)
- [ ] Add manifest to `AppManifest.features`
- [ ] Add framework to Ghost target dependencies
- [ ] Write unit tests
- [ ] Document deeplink URLs (if any)
