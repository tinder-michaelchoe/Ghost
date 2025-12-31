# AppDelegate & SceneDelegate: Visual Diagrams

## Diagram 1: Complete App Startup Flow

```mermaid
graph TD
    A[System Launches App] --> B[Load Info.plist]
    B --> C[Find @main AppDelegate]
    C --> D[Create UIApplication Instance]
    D --> E[Create AppDelegate Instance]
    E --> F[AppDelegate.application:didFinishLaunchingWithOptions]
    F --> G{App-wide<br/>Initialization}
    G --> H[Register Services]
    G --> I[Setup Core Data]
    G --> J[Register Push Notifications]
    H --> K[System Requests Scene]
    I --> K
    J --> K
    K --> L[AppDelegate.application:configurationForConnecting]
    L --> M[Return UISceneConfiguration]
    M --> N[System Creates Scene]
    N --> O[Create SceneDelegate Instance]
    O --> P[SceneDelegate.scene:willConnectTo]
    P --> Q[Create UIWindow]
    Q --> R[Initialize AppCoordinator]
    R --> S[Register Services from Manifest]
    S --> T[Create AppContext]
    T --> U[Run Lifecycle Phases]
    U --> V[.prewarm]
    U --> W[.launch]
    U --> X[.sceneConnect]
    V --> Y[Build Root View Controller]
    W --> Y
    X --> Y
    Y --> Z[Set window.rootViewController]
    Z --> AA[window.makeKeyAndVisible]
    AA --> AB[SceneDelegate.sceneDidBecomeActive]
    AB --> AC[App is Running]
    
    style F fill:#e1f5ff
    style L fill:#e1f5ff
    style P fill:#fff4e1
    style AB fill:#fff4e1
    style AC fill:#e8f5e9
```

## Diagram 2: Relationship Between AppDelegate and SceneDelegate

```mermaid
graph LR
    subgraph "Application Level"
        AD[AppDelegate<br/>Singleton]
        AD --> |1. Creates| SC1[Scene Configuration]
        AD --> |2. Creates| SC2[Scene Configuration]
    end
    
    subgraph "Scene Level - Window 1"
        SD1[SceneDelegate #1]
        SC1 --> |3. Instantiates| SD1
        SD1 --> |Manages| W1[UIWindow #1]
        W1 --> |Contains| VC1[Root ViewController #1]
    end
    
    subgraph "Scene Level - Window 2"
        SD2[SceneDelegate #2]
        SC2 --> |3. Instantiates| SD2
        SD2 --> |Manages| W2[UIWindow #2]
        W2 --> |Contains| VC2[Root ViewController #2]
    end
    
    style AD fill:#e1f5ff
    style SD1 fill:#fff4e1
    style SD2 fill:#fff4e1
    style W1 fill:#f3e5f5
    style W2 fill:#f3e5f5
```

## Diagram 3: Lifecycle Events Flow

```mermaid
stateDiagram-v2
    [*] --> AppLaunch: System Starts App
    AppLaunch --> AppDelegateLaunch: Create AppDelegate
    AppDelegateLaunch --> AppInitialized: didFinishLaunchingWithOptions
    AppInitialized --> SceneRequested: User Opens App
    SceneRequested --> SceneConfigured: configurationForConnecting
    SceneConfigured --> SceneCreated: System Creates Scene
    SceneCreated --> SceneConnecting: willConnectTo
    SceneConnecting --> UIInitializing: Create Window & Setup UI
    UIInitializing --> SceneActive: sceneDidBecomeActive
    SceneActive --> SceneInactive: sceneWillResignActive
    SceneInactive --> SceneActive: sceneDidBecomeActive
    SceneActive --> SceneBackground: sceneDidEnterBackground
    SceneBackground --> SceneForeground: sceneWillEnterForeground
    SceneForeground --> SceneActive: sceneDidBecomeActive
    SceneBackground --> SceneDisconnected: sceneDidDisconnect
    SceneDisconnected --> [*]: Session Discarded
```

## Diagram 4: Method Call Sequence

```mermaid
sequenceDiagram
    participant System
    participant AppDelegate
    participant SceneDelegate
    participant UIWindow
    participant AppCoordinator
    
    System->>AppDelegate: 1. Create Instance
    System->>AppDelegate: 2. application:didFinishLaunchingWithOptions
    AppDelegate->>AppDelegate: Initialize app-wide services
    AppDelegate-->>System: Return true
    
    System->>AppDelegate: 3. application:configurationForConnecting
    AppDelegate-->>System: Return UISceneConfiguration
    
    System->>SceneDelegate: 4. Create Instance
    System->>SceneDelegate: 5. scene:willConnectTo
    SceneDelegate->>UIWindow: Create UIWindow
    SceneDelegate->>AppCoordinator: Initialize
    AppCoordinator->>AppCoordinator: Register services
    AppCoordinator->>AppCoordinator: Create context
    AppCoordinator->>AppCoordinator: Run lifecycle phases
    AppCoordinator-->>SceneDelegate: Return context
    SceneDelegate->>UIWindow: Set rootViewController
    SceneDelegate->>UIWindow: makeKeyAndVisible
    
    System->>SceneDelegate: 6. sceneDidBecomeActive
    SceneDelegate-->>System: Scene is active
```

## Diagram 5: Multi-Window Scenario (iPad)

```mermaid
graph TB
    subgraph "Single App Instance"
        AD[AppDelegate<br/>One Instance]
    end
    
    subgraph "Multiple Scenes"
        SD1[SceneDelegate #1<br/>Window 1]
        SD2[SceneDelegate #2<br/>Window 2]
        SD3[SceneDelegate #3<br/>Window 3]
    end
    
    AD --> |Creates Config| SD1
    AD --> |Creates Config| SD2
    AD --> |Creates Config| SD3
    
    SD1 --> |Manages| W1[Window 1<br/>Main View]
    SD2 --> |Manages| W2[Window 2<br/>Settings View]
    SD3 --> |Manages| W3[Window 3<br/>Document View]
    
    style AD fill:#e1f5ff
    style SD1 fill:#fff4e1
    style SD2 fill:#fff4e1
    style SD3 fill:#fff4e1
```

## Diagram 6: Your Ghost App Specific Flow

```mermaid
graph TD
    A[App Launch] --> B[AppDelegate.didFinishLaunchingWithOptions]
    B --> C[AppDelegateListenerCollection<br/>notifyDidFinishLaunching]
    C --> D[System Requests Scene]
    D --> E[AppDelegate.configurationForConnecting]
    E --> F[AppDelegateListenerCollection<br/>notifyConfigurationForConnecting]
    F --> G[Return UISceneConfiguration]
    G --> H[SceneDelegate.scene:willConnectTo]
    H --> I[Create UIWindow]
    I --> J[Task: initializeApp]
    J --> K[AppCoordinator.initialize]
    K --> L[ServiceManager.register]
    L --> M[Create AppContext]
    M --> N[UIManager.register]
    N --> O[LifecycleManager.register]
    O --> P[Run Phase: .prewarm]
    P --> Q[Run Phase: .launch]
    Q --> R[Run Phase: .sceneConnect]
    R --> S[UIManager.getContributions]
    S --> T[Build Root ViewController]
    T --> U[Set window.rootViewController]
    U --> V[window.makeKeyAndVisible]
    V --> W[Run Phase: .postUI]
    W --> X[sceneDidBecomeActive]
    X --> Y[App Running]
    
    style B fill:#e1f5ff
    style E fill:#e1f5ff
    style H fill:#fff4e1
    style X fill:#fff4e1
    style Y fill:#e8f5e9
```

## ASCII Art Diagram: Simple Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS APP STARTUP                             │
└─────────────────────────────────────────────────────────────────────┘

1. SYSTEM LAUNCH
   │
   └─► Load Info.plist
       └─► Find @main AppDelegate class
           └─► Create UIApplication instance
               │
               ▼
2. APPDELEGATE CREATION
   │
   └─► application(_:didFinishLaunchingWithOptions:)
       │
       ├─► Initialize app-wide services
       ├─► Register push notifications
       ├─► Setup Core Data
       └─► Configure analytics
           │
           ▼
3. SCENE CONFIGURATION
   │
   └─► application(_:configurationForConnecting:options:)
       │
       └─► Return UISceneConfiguration
           │
           └─► Specifies SceneDelegate class name
               │
               ▼
4. SCENE CREATION
   │
   └─► System creates UIScene
       │
       └─► System creates SceneDelegate instance
           │
           ▼
5. SCENE CONNECTION
   │
   └─► scene(_:willConnectTo:options:)
       │
       ├─► Create UIWindow
       ├─► Set windowScene
       └─► Start async initialization
           │
           ▼
6. UI INITIALIZATION (Your Ghost App)
   │
   ├─► Initialize AppCoordinator
   ├─► Register services from AppManifest
   ├─► Create AppContext
   ├─► Run lifecycle phases:
   │   ├─► .prewarm
   │   ├─► .launch
   │   ├─► .sceneConnect
   │   └─► .postUI
   ├─► Get UI contributions
   ├─► Build root view controller
   ├─► Set window.rootViewController
   └─► window.makeKeyAndVisible()
       │
       ▼
7. SCENE ACTIVE
   │
   └─► sceneDidBecomeActive(_:)
       │
       └─► App is now visible and running
           │
           ▼
8. LIFECYCLE EVENTS (Ongoing)
   │
   ├─► sceneWillResignActive(_:)    ← Temporary interruption
   ├─► sceneDidBecomeActive(_:)     ← Resume
   ├─► sceneWillEnterForeground(_:) ← Returning from background
   ├─► sceneDidEnterBackground(_:)  ← Going to background
   └─► sceneDidDisconnect(_:)      ← Scene disconnected
       │
       └─► AppDelegate.application(_:didDiscardSceneSessions:)
           └─► Session permanently discarded
```

## Key Points Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                    RESPONSIBILITY MATRIX                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AppDelegate (App-Wide)          SceneDelegate (Scene-Wide) │
│  ──────────────────────          ─────────────────────────  │
│                                                             │
│  ✓ App launch                  ✓ Window creation           │
│  ✓ Scene configuration         ✓ UI setup                  │
│  ✓ Push notifications          ✓ Root view controller      │
│  ✓ Background tasks            ✓ Scene lifecycle          │
│  ✓ Core Data stack             ✓ Scene state               │
│  ✓ Shared services             ✓ Window-specific resources │
│  ✓ App-wide state              ✓ Scene restoration         │
│                                                             │
│  ONE instance per app          ONE instance per scene       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Timeline View

```
Time →
│
├─► [AppDelegate] didFinishLaunchingWithOptions
│   └─► App-wide initialization
│
├─► [AppDelegate] configurationForConnecting
│   └─► Scene configuration created
│
├─► [SceneDelegate] scene:willConnectTo
│   └─► Window created, UI initialization starts
│
├─► [AppCoordinator] Initialize
│   ├─► Services registered
│   ├─► Context created
│   └─► Lifecycle phases run
│
├─► [SceneDelegate] UI Setup Complete
│   └─► Window made visible
│
├─► [SceneDelegate] sceneDidBecomeActive
│   └─► Scene is active
│
└─► [Ongoing] Scene lifecycle events
    ├─► sceneWillResignActive
    ├─► sceneDidBecomeActive
    ├─► sceneWillEnterForeground
    ├─► sceneDidEnterBackground
    └─► sceneDidDisconnect
```

---

## How to View These Diagrams

1. **Mermaid Diagrams**: 
   - View in GitHub (renders automatically)
   - Use [Mermaid Live Editor](https://mermaid.live/)
   - Use VS Code with Mermaid extension
   - Use Markdown viewers that support Mermaid

2. **ASCII Diagrams**: 
   - View directly in any text editor
   - Works in terminal/console
   - Compatible with all markdown viewers





