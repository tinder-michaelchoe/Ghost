# Deep Linking Architecture

This document describes the complete deep linking system for the Ghost app, including iOS system processes, app architecture integration, type definitions, and flow diagrams.

---

## Table of Contents

1. [Overview](#overview)
2. [URL Scheme Format](#url-scheme-format)
3. [iOS System Process](#ios-system-process)
4. [App Architecture Integration](#app-architecture-integration)
5. [Type Definitions](#type-definitions)
6. [Flow Diagrams](#flow-diagrams)
7. [Registration Process](#registration-process)
8. [Handler Implementation Guide](#handler-implementation-guide)
9. [File Changes Summary](#file-changes-summary)

---

## Overview

Deep linking allows external sources (Safari, other apps, push notifications, Shortcuts) to open the Ghost app and navigate to specific content using custom URL schemes.

**URL Scheme:** `ghost://`

**URL Format:** `ghost://[tab]/[feature]/[action]?[params]`

**Example URLs:**
- `ghost://dashboard` - Navigate to dashboard tab
- `ghost://dashboard/weather` - Open dashboard and focus weather
- `ghost://dashboard/weather/city?name=Chicago` - Open weather for specific city
- `ghost://dashboard/art/refresh` - Trigger art refresh
- `ghost://settings` - Navigate to settings tab

---

## URL Scheme Format

```
ghost://[tab]/[feature]/[action]?[query_parameters]
   │      │       │         │           │
   │      │       │         │           └── Optional key-value pairs (e.g., name=Chicago)
   │      │       │         │
   │      │       │         └── Action within the feature (e.g., city, refresh, settings)
   │      │       │
   │      │       └── Feature/module identifier (e.g., weather, art)
   │      │
   │      └── Tab to navigate to (e.g., dashboard, settings)
   │
   └── Custom URL scheme registered in Info.plist
```

### URL Components Breakdown

| Component | Description | Example |
|-----------|-------------|---------|
| Scheme | App identifier, registered in Info.plist | `ghost` |
| Host | Tab to navigate to | `dashboard`, `settings` |
| Path[0] | Feature/module identifier | `weather`, `art` |
| Path[1+] | Action within the feature | `city`, `refresh` |
| Query | Parameters as key-value pairs | `name=Chicago` |

### Example URLs

| URL | Tab | Feature | Action | Parameters |
|-----|-----|---------|--------|------------|
| `ghost://dashboard` | dashboard | - | - | - |
| `ghost://dashboard/weather` | dashboard | weather | - | - |
| `ghost://dashboard/weather/city?name=Chicago` | dashboard | weather | city | name=Chicago |
| `ghost://dashboard/art/refresh` | dashboard | art | refresh | - |
| `ghost://settings` | settings | - | - | - |

### Parsed Deeplink Structure

```swift
// Input URL: ghost://dashboard/weather/city?name=Chicago

Deeplink(
    scheme: "ghost",
    tab: "dashboard",              // The host - which tab to navigate to
    feature: "weather",            // First path component - which feature handles this
    action: "city",                // Second path component - what action to perform
    pathComponents: ["weather", "city"],
    queryParameters: ["name": "Chicago"],
    originalURL: URL(string: "ghost://dashboard/weather/city?name=Chicago")!
)
```

### Routing Strategy

Handlers register by **feature** (first path component), not by tab:

```swift
// WeatherDeeplinkHandler registers for feature "weather"
// It receives deeplinks like:
//   - ghost://dashboard/weather
//   - ghost://dashboard/weather/city?name=Chicago
//   - ghost://settings/weather/units  (if weather settings lived on settings tab)
```

The handler is responsible for:
1. Navigating to the correct tab (from `deeplink.tab`)
2. Performing the feature-specific action (from `deeplink.action`)

---

## iOS System Process

### App Lifecycle Clarification

When an iOS app is **cold launched** (not running), the following always happens in order:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COLD LAUNCH SEQUENCE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. AppDelegate.application(_:didFinishLaunchingWithOptions:)               │
│     │                                                                        │
│     ├── Called FIRST, always, regardless of how app was launched            │
│     ├── Sets up app-wide state, bootstrap services                          │
│     └── For scene-based apps: URL is NOT in launchOptions                   │
│                                                                              │
│  2. SceneDelegate.scene(_:willConnectTo:options:)                           │
│     │                                                                        │
│     ├── Called AFTER didFinishLaunching                                     │
│     ├── connectionOptions.urlContexts contains the URL (if launched via URL)│
│     └── Ghost's implementation starts async Task for initialization         │
│                                                                              │
│  3. Inside the Task (Ghost-specific):                                       │
│     │                                                                        │
│     ├── initializeApp() runs FIRST                                          │
│     │   ├── Services registered (including DeeplinkService)                 │
│     │   ├── Lifecycle phases run (.prewarm, .launch, .sceneConnect)         │
│     │   ├── Deeplink handlers registered during lifecycle                   │
│     │   ├── UI built and displayed                                          │
│     │   └── .postUI phase runs                                              │
│     │                                                                        │
│     └── THEN listenerCollection.notifyWillConnect() called                  │
│         └── Listeners receive URL AFTER all services are ready              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Insight**: In Ghost's architecture, `notifyWillConnect` is called AFTER `initializeApp` completes, meaning all services and deeplink handlers are registered before the listener processes the URL.

### Scene-Based Apps vs Legacy Apps

For **scene-based apps** (iOS 13+, which Ghost is):

| Launch Type | URL Location |
|-------------|--------------|
| Cold launch | `scene(_:willConnectTo:options:)` → `connectionOptions.urlContexts` |
| Warm launch | `scene(_:openURLContexts:)` → `urlContexts` |

The URL is **NOT** delivered via `launchOptions` in `application(_:didFinishLaunchingWithOptions:)`.

For **legacy apps** (pre-iOS 13, no scenes):

| Launch Type | URL Location |
|-------------|--------------|
| Cold launch | `application(_:didFinishLaunchingWithOptions:)` → `launchOptions[.url]` |
| Warm launch | `application(_:open:options:)` |

Ghost uses scenes, so we only handle URLs in SceneDelegate methods.

### Info.plist Configuration

The URL scheme must be registered in the app's Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.ghost.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ghost</string>
        </array>
    </dict>
</array>
```

### How iOS Delivers URLs to the App

iOS uses different delivery mechanisms depending on app state:

#### Scenario 1: Cold Launch (App Not Running)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS SYSTEM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. User taps link: ghost://weather/city?name=Chicago                       │
│                              │                                               │
│                              ▼                                               │
│  2. iOS checks Info.plist for registered URL schemes                        │
│                              │                                               │
│                              ▼                                               │
│  3. iOS finds "ghost" scheme registered to Ghost.app                        │
│                              │                                               │
│                              ▼                                               │
│  4. iOS launches Ghost.app (cold start)                                     │
│                              │                                               │
└──────────────────────────────│──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GHOST APP                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  5. AppDelegate.application(_:didFinishLaunchingWithOptions:)               │
│                              │                                               │
│                              ▼                                               │
│  6. SceneDelegate.scene(_:willConnectTo:options:)                           │
│     └── connectionOptions.urlContexts contains the URL                      │
│                              │                                               │
│                              ▼                                               │
│  7. URL extracted and processed                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Scenario 2: Warm Launch (App Already Running)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS SYSTEM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. User taps link: ghost://weather/city?name=Chicago                       │
│                              │                                               │
│                              ▼                                               │
│  2. iOS checks Info.plist for registered URL schemes                        │
│                              │                                               │
│                              ▼                                               │
│  3. iOS finds Ghost.app already running                                     │
│                              │                                               │
│                              ▼                                               │
│  4. iOS brings Ghost.app to foreground                                      │
│                              │                                               │
└──────────────────────────────│──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GHOST APP                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  5. SceneDelegate.scene(_:openURLContexts:)                                 │
│     └── urlContexts contains the URL                                        │
│                              │                                               │
│                              ▼                                               │
│  6. URL extracted and processed                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Scenario 3: App Suspended in Background

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS SYSTEM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. User taps link: ghost://weather/city?name=Chicago                       │
│                              │                                               │
│                              ▼                                               │
│  2. iOS wakes Ghost.app from suspension                                     │
│                              │                                               │
│                              ▼                                               │
│  3. iOS brings Ghost.app to foreground                                      │
│                              │                                               │
└──────────────────────────────│──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GHOST APP                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  4. SceneDelegate.sceneWillEnterForeground(_:)                              │
│                              │                                               │
│                              ▼                                               │
│  5. SceneDelegate.scene(_:openURLContexts:)                                 │
│     └── urlContexts contains the URL                                        │
│                              │                                               │
│                              ▼                                               │
│  6. URL extracted and processed                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## App Architecture Integration

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                              Ghost (App Target)                              │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                           SceneDelegate                                 │ │
│  │                                                                         │ │
│  │  • Receives URLs from iOS via scene(_:openURLContexts:)                │ │
│  │  • Receives URLs on cold launch via scene(_:willConnectTo:options:)    │ │
│  │  • Forwards to SceneDelegateListenerCollection                         │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
└──────────────────────────────────────│──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                              CoreContracts                                   │
│                                                                              │
│  ┌──────────────────────────┐    ┌────────────────────────────────────────┐ │
│  │  SceneDelegateListener   │    │         DeeplinkService                │ │
│  │  (Protocol)              │    │         (Protocol)                     │ │
│  │                          │    │                                        │ │
│  │  + scene(_:openURL       │    │  + register(handler:for:)              │ │
│  │    Contexts:)            │    │  + handle(_ deeplink:) -> Bool         │ │
│  │                          │    │  + canHandle(_ url:) -> Bool           │ │
│  └──────────────────────────┘    └────────────────────────────────────────┘ │
│                                                                              │
│  ┌──────────────────────────┐    ┌────────────────────────────────────────┐ │
│  │  DeeplinkHandler         │    │         Deeplink                       │ │
│  │  (Protocol)              │    │         (Struct)                       │ │
│  │                          │    │                                        │ │
│  │  + host: String          │    │  + scheme: String                      │ │
│  │  + handle(_ deeplink:)   │    │  + host: String?                       │ │
│  │    -> Bool               │    │  + path: String                        │ │
│  │                          │    │  + pathComponents: [String]            │ │
│  └──────────────────────────┘    │  + queryParameters: [String: String]   │ │
│                                  │  + originalURL: URL                    │ │
│                                  └────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                              Deeplinking Module                              │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          DeeplinkRouter                                 │ │
│  │                    (Implements DeeplinkService)                         │ │
│  │                                                                         │ │
│  │  • Maintains registry of DeeplinkHandler instances                      │ │
│  │  • Routes incoming Deeplinks to matching handlers                       │ │
│  │  • Matches by host (e.g., "weather", "art", "dashboard")               │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                   DeeplinkSceneDelegateListener                         │ │
│  │                 (Implements SceneDelegateListener)                      │ │
│  │                                                                         │ │
│  │  • Receives URL contexts from SceneDelegate                             │ │
│  │  • Parses URLs into Deeplink structs                                    │ │
│  │  • Passes Deeplinks to DeeplinkService for routing                      │ │
│  │  • Queues deeplinks received before app is ready                        │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                       DeeplinkingManifest                               │ │
│  │                                                                         │ │
│  │  • Registers DeeplinkRouter as DeeplinkService                          │ │
│  │  • Registers DeeplinkSceneDelegateListener                              │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                         Feature Modules (Weather, Art, etc.)                 │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     WeatherDeeplinkHandler                              │ │
│  │                   (Implements DeeplinkHandler)                          │ │
│  │                                                                         │ │
│  │  host = "weather"                                                       │ │
│  │                                                                         │ │
│  │  Handles:                                                               │ │
│  │    • ghost://weather           → Show weather widget                    │ │
│  │    • ghost://weather/city?...  → Show weather for specific city         │ │
│  │    • ghost://weather/settings  → Open weather settings                  │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                       ArtDeeplinkHandler                                │ │
│  │                   (Implements DeeplinkHandler)                          │ │
│  │                                                                         │ │
│  │  host = "art"                                                           │ │
│  │                                                                         │ │
│  │  Handles:                                                               │ │
│  │    • ghost://art           → Show art widget                            │ │
│  │    • ghost://art/refresh   → Refresh artwork                            │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Type Definitions

### CoreContracts Types

#### Deeplink (Struct)

```swift
/// Represents a parsed deep link URL.
/// URL format: ghost://[tab]/[feature]/[action]?[query]
public struct Deeplink: Sendable, Equatable {

    /// The URL scheme (e.g., "ghost")
    public let scheme: String

    /// The tab to navigate to (from URL host)
    /// e.g., "dashboard", "settings"
    public let tab: String?

    /// The feature that should handle this deeplink (first path component)
    /// e.g., "weather", "art"
    /// Handlers register by feature name.
    public let feature: String?

    /// The action to perform within the feature (second path component)
    /// e.g., "city", "refresh"
    public let action: String?

    /// All path components for more complex routing
    public let pathComponents: [String]

    /// Query parameters as key-value pairs
    public let queryParameters: [String: String]

    /// The original URL that was parsed
    public let originalURL: URL

    // MARK: - Initialization

    /// Creates a Deeplink from a URL.
    /// Returns nil if the URL cannot be parsed.
    public init?(url: URL) {
        guard let scheme = url.scheme else { return nil }

        self.scheme = scheme
        self.tab = url.host
        self.originalURL = url

        // Parse path components (filter out empty strings from leading "/")
        let components = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        self.pathComponents = components

        // First path component is the feature
        self.feature = components.first

        // Second path component is the action
        self.action = components.count > 1 ? components[1] : nil

        // Parse query parameters
        var params: [String: String] = [:]
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            for item in queryItems {
                params[item.name] = item.value ?? ""
            }
        }
        self.queryParameters = params
    }

    // MARK: - Convenience

    /// Returns a query parameter value for the given key.
    public func parameter(_ key: String) -> String? {
        queryParameters[key]
    }

    /// Returns path components after feature and action (for deeper routing)
    public var remainingPath: [String] {
        guard pathComponents.count > 2 else { return [] }
        return Array(pathComponents.dropFirst(2))
    }
}
```

#### DeeplinkHandler (Protocol)

```swift
/// Protocol for modules that handle deep links.
/// Each handler is responsible for a specific feature (e.g., "weather", "art").
@MainActor
public protocol DeeplinkHandler: AnyObject {

    /// The feature this handler responds to (first path component).
    /// e.g., "weather", "art"
    /// The router uses this to match incoming deeplinks.
    var feature: String { get }

    /// Handles a deep link.
    /// The handler is responsible for:
    /// 1. Navigating to the correct tab (from deeplink.tab) if needed
    /// 2. Performing the feature-specific action (from deeplink.action)
    /// - Parameter deeplink: The parsed deep link
    /// - Returns: true if the deep link was handled, false otherwise
    func handle(_ deeplink: Deeplink) -> Bool
}
```

#### NavigationService (Protocol)

```swift
/// Protocol for tab navigation.
/// Implemented by TabBar, used by deeplink handlers to switch tabs.
@MainActor
public protocol NavigationService: AnyObject {

    /// Switches to the specified tab.
    /// - Parameter identifier: The tab identifier (e.g., "dashboard", "settings")
    /// - Returns: true if the tab was found and switched to
    @discardableResult
    func switchToTab(_ identifier: String) -> Bool

    /// Returns the currently selected tab identifier.
    var currentTab: String? { get }
}
```

#### DeeplinkService (Protocol)

```swift
/// Service protocol for deep link routing.
/// Modules register handlers and the service routes incoming links.
@MainActor
public protocol DeeplinkService: AnyObject {

    /// Registers a handler for deep links.
    /// - Parameter handler: The handler to register
    func register(handler: DeeplinkHandler)

    /// Unregisters a handler.
    /// - Parameter handler: The handler to remove
    func unregister(handler: DeeplinkHandler)

    /// Attempts to handle a deep link.
    /// - Parameter deeplink: The parsed deep link
    /// - Returns: true if a handler processed the link, false otherwise
    func handle(_ deeplink: Deeplink) -> Bool

    /// Checks if any registered handler can handle the given URL.
    /// - Parameter url: The URL to check
    /// - Returns: true if a handler exists for this URL's host
    func canHandle(_ url: URL) -> Bool
}
```

#### SceneDelegateListener Extension

```swift
/// Updated SceneDelegateListener protocol with dependency injection support
public protocol SceneDelegateListener: AnyObject {
    init()

    // ... existing methods ...

    /// Called after services are registered to inject dependencies.
    /// Listeners that need access to services should override this.
    /// - Parameter resolver: The service resolver to obtain dependencies from
    func configure(with resolver: Resolver)

    /// Called when the scene receives URLs to open.
    /// - Parameters:
    ///   - scene: The scene receiving the URLs
    ///   - urlContexts: The URL contexts containing the URLs to open
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>)
}

public extension SceneDelegateListener {
    /// Default implementation does nothing.
    func configure(with resolver: Resolver) {
        // Default: no-op - listeners without dependencies don't need to implement this
    }

    /// Default implementation does nothing.
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        // Default: no-op
    }
}
```

This pattern allows any listener to receive dependencies without SceneDelegate needing to know about specific listener types.

### Deeplinking Module Types

#### DeeplinkRouter (Class)

```swift
/// Central router for deep links.
/// Maintains a registry of handlers keyed by feature name.
/// Routes incoming links to the appropriate handler based on the first path component.
@MainActor
public final class DeeplinkRouter: DeeplinkService {

    // MARK: - Properties

    /// Registered handlers, keyed by feature name
    private var handlers: [String: DeeplinkHandler] = [:]

    /// Handler for tab-only deeplinks (no feature specified)
    /// e.g., ghost://dashboard with no path
    private var tabOnlyHandler: ((Deeplink) -> Bool)?

    /// Expected URL scheme
    private let scheme: String

    // MARK: - Initialization

    public init(scheme: String = "ghost") {
        self.scheme = scheme
    }

    // MARK: - DeeplinkService

    public func register(handler: DeeplinkHandler) {
        handlers[handler.feature] = handler
        print("[DeeplinkRouter] Registered handler for feature: \(handler.feature)")
    }

    public func unregister(handler: DeeplinkHandler) {
        handlers.removeValue(forKey: handler.feature)
        print("[DeeplinkRouter] Unregistered handler for feature: \(handler.feature)")
    }

    /// Sets a handler for tab-only deeplinks (ghost://dashboard with no feature path)
    public func setTabOnlyHandler(_ handler: @escaping (Deeplink) -> Bool) {
        self.tabOnlyHandler = handler
    }

    public func handle(_ deeplink: Deeplink) -> Bool {
        // Validate scheme
        guard deeplink.scheme == scheme else {
            print("[DeeplinkRouter] Ignoring deeplink with scheme: \(deeplink.scheme)")
            return false
        }

        // If no feature specified, this is a tab-only deeplink
        guard let feature = deeplink.feature else {
            print("[DeeplinkRouter] Tab-only deeplink for tab: \(deeplink.tab ?? "nil")")
            return tabOnlyHandler?(deeplink) ?? false
        }

        // Find handler for feature
        guard let handler = handlers[feature] else {
            print("[DeeplinkRouter] No handler for feature: \(feature)")
            return false
        }

        // Delegate to handler
        print("[DeeplinkRouter] Routing to handler for feature: \(feature)")
        return handler.handle(deeplink)
    }

    public func canHandle(_ url: URL) -> Bool {
        guard url.scheme == scheme else { return false }

        // Parse to get feature
        guard let deeplink = Deeplink(url: url) else { return false }

        // Tab-only deeplinks are handleable if we have a tab handler
        guard let feature = deeplink.feature else {
            return tabOnlyHandler != nil
        }

        return handlers[feature] != nil
    }
}
```

#### DeeplinkSceneDelegateListener (Class)

**Design Note**: Since Ghost calls `notifyWillConnect` AFTER `initializeApp` completes, the listener receives URLs when services are already registered. The listener uses the protocol's `configure(with:)` method to receive its dependencies.

```swift
/// SceneDelegate listener that receives URLs and routes them through DeeplinkService.
@MainActor
public final class DeeplinkSceneDelegateListener: SceneDelegateListener {

    // MARK: - Properties

    /// Reference to the deeplink service (injected via configure)
    private var deeplinkService: DeeplinkService?

    // MARK: - Initialization

    public required init() {}

    // MARK: - SceneDelegateListener

    /// Receives dependencies after services are registered.
    public func configure(with resolver: Resolver) {
        self.deeplinkService = resolver.resolve(DeeplinkService.self)
    }

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) -> ServiceManagerProtocol? {
        // Handle URLs from cold launch
        // Note: This is called AFTER initializeApp and configure, so services are ready
        handleURLContexts(connectionOptions.urlContexts)
        return nil
    }

    public func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        // Handle URLs when app is already running
        handleURLContexts(urlContexts)
    }

    // MARK: - Private

    private func handleURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        for context in urlContexts {
            handleURL(context.url)
        }
    }

    private func handleURL(_ url: URL) {
        print("[DeeplinkListener] Received URL: \(url)")

        guard let deeplink = Deeplink(url: url) else {
            print("[DeeplinkListener] Failed to parse URL")
            return
        }

        guard let service = deeplinkService else {
            print("[DeeplinkListener] Error: DeeplinkService not configured")
            return
        }

        let handled = service.handle(deeplink)
        print("[DeeplinkListener] Deeplink handled: \(handled)")
    }
}
```

#### DeeplinkingManifest

```swift
import CoreContracts

public enum DeeplinkingManifest: Manifest {

    public static var serviceProviders: [ServiceProvider.Type] {
        [DeeplinkServiceProvider.self]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [DeeplinkSceneDelegateListener.self]
    }
}

// MARK: - Service Provider

final class DeeplinkServiceProvider: ServiceProvider {

    static var dependencies: [ServiceKey] { [] }

    static func register(in container: ServiceContainer) {
        container.register(DeeplinkService.self) { _ in
            DeeplinkRouter()
        }
    }
}
```

---

## Listener Configuration

### The Challenge

SceneDelegateListeners are created via `init()` (parameterless) and don't have access to the service container. However, some listeners (like `DeeplinkSceneDelegateListener`) need access to services to function.

### The Solution

Add a `configure(with resolver:)` method to the `SceneDelegateListener` protocol. This provides a clean, generic way for any listener to receive dependencies without SceneDelegate needing to know about specific listener types.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LISTENER CONFIGURATION FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. SceneDelegate.scene(_:willConnectTo:options:) called                    │
│     │                                                                        │
│     └── listenerCollection created (lazy)                                   │
│         └── All listeners instantiated via init()                           │
│             └── Dependencies are nil at this point                          │
│                                                                              │
│  2. Task started for async initialization                                   │
│     │                                                                        │
│     ├── initializeApp() runs                                                │
│     │   ├── Services registered (DeeplinkRouter as DeeplinkService)        │
│     │   ├── Lifecycle phases run                                            │
│     │   └── Handlers registered                                             │
│     │                                                                        │
│     ├── Configure ALL listeners (generic loop)                              │
│     │   └── for listener in listeners { listener.configure(with: resolver) }│
│     │       └── Each listener resolves its own dependencies                 │
│     │                                                                        │
│     └── notifyWillConnect() called                                          │
│         └── Listeners receive URL with dependencies configured ✓            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### SceneDelegate Changes

Add a generic configuration loop after initialization:

```swift
// In SceneDelegate.swift

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    window = UIWindow(windowScene: windowScene)

    let serviceManager = appDelegate?.bootstrapServiceManager ?? ServiceManager()
    coordinator = AppCoordinator(serviceManager: serviceManager)

    Task {
        await initializeApp(windowScene: windowScene)

        // Configure all listeners with the resolver (generic - no specific type knowledge needed)
        configureListeners()

        // Now notify listeners - all dependencies are injected
        _ = listenerCollection.notifyWillConnect(scene, session: session, options: connectionOptions)
    }
}

private func configureListeners() {
    guard let resolver = coordinator?.resolver else { return }

    // Generic loop - works for any listener that needs dependencies
    for listener in listenerCollection.handlers {
        listener.configure(with: resolver)
    }
}
```

### Benefits of This Approach

1. **Generic** - SceneDelegate doesn't need to know about specific listener types
2. **Extensible** - Any new listener can receive dependencies by implementing `configure(with:)`
3. **Backwards compatible** - Default empty implementation means existing listeners don't break
4. **Follows existing patterns** - Similar to how `ServiceProvider` declares dependencies

### SceneDelegateListenerCollection Change

Expose handlers for iteration:

```swift
// In SceneDelegateListenerCollection.swift

public struct SceneDelegateListenerCollection: HandlerCollection {
    public typealias EventHandler = SceneDelegateListener

    public private(set) var handlers: [SceneDelegateListener] = []  // Make readable

    // ... rest of implementation
}
```

---

## Flow Diagrams

### Complete Flow: Cold Launch from Deep Link

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ USER ACTION                                                                             │
│                                                                                         │
│  User taps: ghost://weather/city?name=Chicago                                          │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ iOS SYSTEM                                                                              │
│                                                                                         │
│  1. iOS parses URL scheme → "ghost"                                                    │
│  2. iOS looks up Info.plist → finds Ghost.app                                          │
│  3. iOS launches Ghost.app with URL in connection options                              │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ APPDELEGATE                                                                             │
│                                                                                         │
│  4. application(_:didFinishLaunchingWithOptions:)                                      │
│     • Called FIRST, always                                                             │
│     • Bootstrap services registered                                                    │
│     • AppDelegate listener collection notified                                         │
│     • URL is NOT in launchOptions (scene-based app)                                    │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ SCENEDELEGATE - scene(_:willConnectTo:options:)                                        │
│                                                                                         │
│  5. Method called by iOS                                                               │
│     │                                                                                   │
│     ├── connectionOptions.urlContexts = [UIOpenURLContext(ghost://weather/city?...)]  │
│     ├── Creates window                                                                 │
│     ├── Creates ServiceManager (from bootstrap)                                        │
│     ├── Creates AppCoordinator                                                         │
│     │                                                                                   │
│     └── Starts Task for async initialization...                                        │
│                                                                                         │
│  Note: Method returns immediately, Task runs asynchronously                            │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ASYNC TASK - initializeApp()                                                            │
│                                                                                         │
│  6. AppCoordinator.initialize(manifest:)                                               │
│     • Registers all services (including DeeplinkService/DeeplinkRouter)                │
│                                                                                         │
│  7. Run lifecycle phases                                                               │
│     • .prewarm                                                                         │
│     • .launch ← Feature modules register DeeplinkHandlers here                         │
│     • .sceneConnect                                                                    │
│                                                                                         │
│  8. Build and display UI                                                               │
│     • Root view controller set                                                         │
│     • Window made visible                                                              │
│                                                                                         │
│  9. Run .postUI phase                                                                  │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ASYNC TASK - Configure All Listeners                                                    │
│                                                                                         │
│  10. configureListeners()                                                              │
│      │                                                                                  │
│      └── for listener in listenerCollection.handlers:                                  │
│              listener.configure(with: resolver)                                        │
│                                                                                         │
│      DeeplinkSceneDelegateListener.configure(with:) resolves:                          │
│          self.deeplinkService = resolver.resolve(DeeplinkService.self)                 │
│                                                                                         │
│  All listeners now have their dependencies ✓                                           │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ASYNC TASK - Notify Listeners                                                           │
│                                                                                         │
│  11. listenerCollection.notifyWillConnect(scene, session, options)                     │
│      │                                                                                  │
│      └── Iterates through registered listeners                                         │
│          └── Calls each listener's scene(_:willConnectTo:options:)                     │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DEEPLINKSCENEDELEGATELISTENER                                                           │
│                                                                                         │
│  12. scene(_:willConnectTo:options:)                                                   │
│      │                                                                                  │
│      ├── Extracts URL from connectionOptions.urlContexts                               │
│      ├── Parses URL → Deeplink struct                                                  │
│      │   Deeplink(                                                                      │
│      │     scheme: "ghost",                                                             │
│      │     host: "weather",                                                             │
│      │     path: "/city",                                                               │
│      │     pathComponents: ["city"],                                                    │
│      │     queryParameters: ["name": "Chicago"]                                         │
│      │   )                                                                              │
│      │                                                                                  │
│      └── deeplinkService is configured ✓ → Immediately handles                         │
│          └── deeplinkService.handle(deeplink)                                          │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DEEPLINKROUTER                                                                          │
│                                                                                         │
│  13. handle(_ deeplink:)                                                               │
│      │                                                                                  │
│      ├── Validates scheme == "ghost" ✓                                                 │
│      ├── Looks up handler for host "weather"                                           │
│      │   └── Found: WeatherDeeplinkHandler (registered in .launch phase)              │
│      │                                                                                  │
│      └── Calls handler.handle(deeplink)                                                │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ WEATHERDEEPLINKHANDLER                                                                  │
│                                                                                         │
│  14. handle(_ deeplink:)                                                               │
│      │                                                                                  │
│      ├── Checks path: "/city"                                                          │
│      ├── Extracts parameter: name = "Chicago"                                          │
│      │                                                                                  │
│      └── Executes action:                                                              │
│          • Sets weather location to Chicago                                            │
│          • Refreshes weather widget                                                    │
│          • Returns true (handled)                                                      │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ RESULT                                                                                  │
│                                                                                         │
│  User sees weather for Chicago                                                         │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Timing Insight

The critical insight is that in Ghost's architecture, **listeners are notified AFTER initialization and configuration**:

```swift
Task {
    await initializeApp(windowScene: windowScene)  // ← All services registered
    configureListeners()                           // ← All listeners receive dependencies
    _ = listenerCollection.notifyWillConnect(...)  // ← THEN listeners notified with URL
}
```

This means:
- No queuing of pending deeplinks needed for cold launch
- By the time the listener receives the URL, everything is ready
- The listener can immediately route the deeplink to the appropriate handler
- The pattern is generic and works for any listener that needs dependencies

### Complete Flow: Warm Launch (App Already Running)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ USER ACTION                                                                             │
│                                                                                         │
│  User taps: ghost://art/refresh                                                        │
│  (App is already running in foreground or background)                                  │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ iOS SYSTEM                                                                              │
│                                                                                         │
│  1. iOS parses URL scheme → "ghost"                                                    │
│  2. iOS finds Ghost.app already running                                                │
│  3. iOS brings Ghost.app to foreground (if backgrounded)                               │
│  4. iOS calls scene(_:openURLContexts:) with URL                                       │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ SCENEDELEGATE                                                                           │
│                                                                                         │
│  5. scene(_:openURLContexts:)                                                          │
│     │                                                                                   │
│     ├── urlContexts = [UIOpenURLContext(ghost://art/refresh)]                          │
│     │                                                                                   │
│     └── Notifies listenerCollection.notifyOpenURLContexts(urlContexts)                 │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ SCENEDELEGATELISTENERCOLLECTION                                                         │
│                                                                                         │
│  6. Iterates through registered listeners                                              │
│     └── Calls each listener's scene(_:openURLContexts:)                                │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DEEPLINKSCENEDELEGATELISTENER                                                           │
│                                                                                         │
│  7. scene(_:openURLContexts:)                                                          │
│     │                                                                                   │
│     ├── Extracts URL from urlContexts                                                  │
│     ├── Parses URL → Deeplink struct                                                   │
│     │   Deeplink(                                                                       │
│     │     scheme: "ghost",                                                              │
│     │     host: "art",                                                                  │
│     │     path: "/refresh",                                                             │
│     │     pathComponents: ["refresh"],                                                  │
│     │     queryParameters: [:]                                                          │
│     │   )                                                                               │
│     │                                                                                   │
│     └── App is ready → Immediately calls deeplinkService.handle(deeplink)             │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DEEPLINKROUTER                                                                          │
│                                                                                         │
│  8. handle(_ deeplink:)                                                                │
│     │                                                                                   │
│     ├── Validates scheme == "ghost" ✓                                                  │
│     ├── Looks up handler for host "art"                                                │
│     │   └── Found: ArtDeeplinkHandler                                                  │
│     │                                                                                   │
│     └── Calls handler.handle(deeplink)                                                 │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ARTDEEPLINKHANDLER                                                                      │
│                                                                                         │
│  9. handle(_ deeplink:)                                                                │
│     │                                                                                   │
│     ├── Checks path: "/refresh"                                                        │
│     │                                                                                   │
│     └── Executes action:                                                               │
│         • Triggers art widget refresh                                                  │
│         • Returns true (handled)                                                       │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ RESULT                                                                                  │
│                                                                                         │
│  Art widget refreshes with new artwork                                                 │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Registration Process

### Handler Registration Flow

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ APP STARTUP                                                                             │
│                                                                                         │
│  AppCoordinator.initialize(manifest:)                                                  │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ SERVICE REGISTRATION PHASE                                                              │
│                                                                                         │
│  1. DeeplinkServiceProvider.register(in: container)                                    │
│     └── container.register(DeeplinkService.self) { DeeplinkRouter() }                  │
│                                                                                         │
│  2. WeatherServiceProvider.register(in: container)                                     │
│     └── ... weather services ...                                                       │
│                                                                                         │
│  3. ArtServiceProvider.register(in: container)                                         │
│     └── ... art services ...                                                           │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ LIFECYCLE PHASE: .launch                                                                │
│                                                                                         │
│  WeatherLifecycleParticipant.launch(context:)                                          │
│  │                                                                                      │
│  └── Registers deeplink handler:                                                       │
│      let deeplinkService = context.resolve(DeeplinkService.self)                       │
│      let handler = WeatherDeeplinkHandler(...)                                         │
│      deeplinkService.register(handler: handler)                                        │
│                                                                                         │
│  ArtLifecycleParticipant.launch(context:)                                              │
│  │                                                                                      │
│  └── Registers deeplink handler:                                                       │
│      let deeplinkService = context.resolve(DeeplinkService.self)                       │
│      let handler = ArtDeeplinkHandler(...)                                             │
│      deeplinkService.register(handler: handler)                                        │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DEEPLINKROUTER STATE                                                                    │
│                                                                                         │
│  handlers = [                                                                          │
│    "weather": WeatherDeeplinkHandler,                                                  │
│    "art": ArtDeeplinkHandler                                                           │
│  ]                                                                                      │
│                                                                                         │
│  Ready to handle:                                                                      │
│    • ghost://weather/*                                                                 │
│    • ghost://art/*                                                                     │
│                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Handler Implementation Guide

### Example: WeatherDeeplinkHandler

```swift
import CoreContracts
import UIKit

/// Handles deep links for the Weather module.
/// Registered for feature "weather".
@MainActor
final class WeatherDeeplinkHandler: DeeplinkHandler {

    // MARK: - Properties

    let feature = "weather"

    private let navigationService: NavigationService
    private let persistenceService: PersistenceService
    private weak var widgetRefreshDelegate: RefreshableWidget?

    // MARK: - Initialization

    init(navigationService: NavigationService, persistenceService: PersistenceService) {
        self.navigationService = navigationService
        self.persistenceService = persistenceService
    }

    // MARK: - DeeplinkHandler

    func handle(_ deeplink: Deeplink) -> Bool {
        print("[WeatherDeeplink] Handling: \(deeplink.originalURL)")

        // Step 1: Navigate to the correct tab (if specified)
        if let tab = deeplink.tab {
            navigationService.switchToTab(tab)
        }

        // Step 2: Perform the action
        switch deeplink.action {
        case nil:
            // ghost://dashboard/weather - Just navigate to tab (already done)
            print("[WeatherDeeplink] Navigated to weather on \(deeplink.tab ?? "current") tab")
            return true

        case "city":
            // ghost://dashboard/weather/city?name=Chicago
            guard let cityName = deeplink.parameter("name") else {
                print("[WeatherDeeplink] Missing 'name' parameter")
                return false
            }
            return selectCity(named: cityName)

        case "settings":
            // ghost://dashboard/weather/settings
            return showSettings()

        case "refresh":
            // ghost://dashboard/weather/refresh
            return refreshWeather()

        default:
            print("[WeatherDeeplink] Unknown action: \(deeplink.action ?? "")")
            return false
        }
    }

    // MARK: - Actions

    private func selectCity(named name: String) -> Bool {
        // Find city in available locations
        guard let index = WeatherLocations.available.firstIndex(where: {
            $0.name?.lowercased() == name.lowercased()
        }) else {
            print("[WeatherDeeplink] City not found: \(name)")
            return false
        }

        // Update selection
        WeatherLocations.setSelectedIndex(index, using: persistenceService)
        widgetRefreshDelegate?.refreshContent()

        print("[WeatherDeeplink] Selected city: \(name)")
        return true
    }

    private func showSettings() -> Bool {
        // Flip to back of weather widget
        print("[WeatherDeeplink] Showing settings")
        return true
    }

    private func refreshWeather() -> Bool {
        widgetRefreshDelegate?.refreshContent()
        print("[WeatherDeeplink] Refreshed weather")
        return true
    }
}
```

### Example: TabBar NavigationService Implementation

```swift
import CoreContracts
import UIKit

/// TabBar implements NavigationService to allow deeplink handlers to switch tabs.
extension TabBarController: NavigationService {

    public var currentTab: String? {
        guard let index = selectedIndex as Int?,
              index < tabIdentifiers.count else {
            return nil
        }
        return tabIdentifiers[index]
    }

    @discardableResult
    public func switchToTab(_ identifier: String) -> Bool {
        guard let index = tabIdentifiers.firstIndex(of: identifier) else {
            print("[TabBar] Unknown tab: \(identifier)")
            return false
        }

        selectedIndex = index
        print("[TabBar] Switched to tab: \(identifier)")
        return true
    }
}

// TabBar also registers as a service
final class TabBarServiceProvider: ServiceProvider {
    static var dependencies: [ServiceKey] { [] }

    static func register(in container: ServiceContainer) {
        // The actual TabBarController instance is set later during UI setup
        container.register(NavigationService.self) { resolver in
            // This would be the actual tab bar instance
            // Could use a wrapper/proxy pattern if needed
            resolver.resolve(TabBarController.self)
        }
    }
}
```

### Example: Setting Up Tab-Only Handler

```swift
// During app initialization, set up handling for tab-only deeplinks
// like ghost://dashboard (no feature path)

func setupDeeplinking(deeplinkService: DeeplinkService, navigationService: NavigationService) {
    // Handle tab-only deeplinks by just switching tabs
    if let router = deeplinkService as? DeeplinkRouter {
        router.setTabOnlyHandler { deeplink in
            guard let tab = deeplink.tab else { return false }
            return navigationService.switchToTab(tab)
        }
    }
}
```

### Supported URL Patterns

| URL | Tab Navigation | Feature Action |
|-----|----------------|----------------|
| `ghost://dashboard` | → dashboard | (none) |
| `ghost://dashboard/weather` | → dashboard | show weather |
| `ghost://dashboard/weather/city?name=Chicago` | → dashboard | set city to Chicago |
| `ghost://dashboard/weather/refresh` | → dashboard | refresh weather |
| `ghost://dashboard/art/refresh` | → dashboard | refresh art |
| `ghost://settings` | → settings | (none) |

---

## File Changes Summary

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `Deeplink.swift` | CoreContracts/Deeplinking/ | Parsed deeplink struct |
| `DeeplinkHandler.swift` | CoreContracts/Deeplinking/ | Handler protocol |
| `DeeplinkService.swift` | CoreContracts/Deeplinking/ | Service protocol |
| `NavigationService.swift` | CoreContracts/Navigation/ | Tab navigation protocol |
| `DeeplinkRouter.swift` | Deeplinking/ | Router implementation |
| `DeeplinkSceneDelegateListener.swift` | Deeplinking/ | SceneDelegate listener |
| `Manifest.swift` | Deeplinking/ | Module manifest |

### Modified Files

| File | Change |
|------|--------|
| `SceneDelegateListener.swift` | Add `configure(with:)` and `scene(_:openURLContexts:)` methods |
| `SceneDelegateListenerCollection.swift` | Add `notifyOpenURLContexts()` method, expose `handlers` as readable |
| `SceneDelegate.swift` | Add `scene(_:openURLContexts:)` implementation, add `configureListeners()` call |
| `Info.plist` | Add `CFBundleURLTypes` with "ghost" scheme |
| `AppManifest.swift` | Add `DeeplinkingManifest` to manifests |
| `TabBarController.swift` | Implement `NavigationService` protocol |
| `TabBarManifest.swift` | Register `NavigationService` |

### Optional Feature Module Files

| File | Purpose |
|------|---------|
| `WeatherDeeplinkHandler.swift` | Handle weather deep links |
| `ArtDeeplinkHandler.swift` | Handle art deep links |

---

## Testing Deep Links

### Simulator Testing

```bash
# Open URL in simulator
xcrun simctl openurl booted "ghost://dashboard"
xcrun simctl openurl booted "ghost://dashboard/weather"
xcrun simctl openurl booted "ghost://dashboard/weather/city?name=Chicago"
xcrun simctl openurl booted "ghost://dashboard/art/refresh"
```

### Device Testing

Create a note or message with the URL and tap it:
```
ghost://dashboard/weather/city?name=Los%20Angeles
```

### Safari Testing

Type in Safari address bar:
```
ghost://dashboard
```

---

## Security Considerations

1. **Validate all input** - Never trust URL parameters; validate before use
2. **Avoid sensitive actions** - Don't expose destructive operations via deep links
3. **Rate limiting** - Consider throttling rapid deep link calls
4. **Logging** - Log deep link handling for debugging (remove in production)
5. **Scheme uniqueness** - Ensure "ghost" scheme doesn't conflict with other apps
