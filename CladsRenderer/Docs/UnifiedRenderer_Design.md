# Unified Renderer Architecture Design

**Status:** Proposal (not yet implemented)

This document describes a proposed fallback system that allows component renderers to be implemented in either UIKit or SwiftUI and automatically bridges to the other system when needed.

## Goals

1. Implement a component renderer once (in either UIKit or SwiftUI)
2. Automatically bridge to the other system when needed
3. Prefer native implementation when both exist
4. Maintain type safety and performance

---

## Core Principle: Bridge and Return

**Cross the bridge for a component, then cross back for its children.**

The bridge is a single-node operation. After rendering a component in the fallback system, children return to the original pipeline:

```
SwiftUI Pipeline (origin)
    │
    ├── SwiftUI Label ← native
    │
    ├── UIKit Chart ← BRIDGE (UIViewRepresentable)
    │       │
    │       └── children rendered back in SwiftUI (origin)
    │               │
    │               ├── SwiftUI Axis Label ← native
    │               └── SwiftUI Legend ← native
    │
    └── SwiftUI Button ← native
```

### Why This Approach

**The alternative (staying in bridged system) has problems:**

1. **Cascading implementation requirements** - If UIKit Chart's children stay UIKit, you need UIKit renderers for Label, Legend, etc.
2. **Layout system mismatch within subtree** - Children designed for SwiftUI layout would behave differently in UIKit
3. **Defeats the purpose** - The goal is "implement once, works everywhere", not "implement once, then implement all children too"

**Bridge-and-return benefits:**

1. **Minimal bridging** - Only one bridge wrapper per fallback component
2. **Children use native layout** - SwiftUI children get SwiftUI layout semantics
3. **True single implementation** - A component works in both pipelines without requiring its dependencies to also have dual implementations

### The Tradeoff

The bridged component itself cannot use its native layout system to arrange children. It must:
- Accept children as an opaque rendered unit (SwiftUI `AnyView` or `UIView`)
- Let the origin pipeline handle child layout

```swift
// UIKit Chart bridged into SwiftUI
// Chart receives children as a single SwiftUI view, not UIKit subviews
struct BridgedUIKitChart: UIViewRepresentable {
    let chartNode: ChartNode
    let childrenView: AnyView  // Children rendered by SwiftUI, passed as opaque unit

    func makeUIView(context: Context) -> ChartUIView {
        let chart = ChartUIView()
        // Chart can position the children container, but not individual children
        chart.legendContainer = UIHostingController(rootView: childrenView).view
        return chart
    }
}
```

### When This Works Well

| Component Type | Bridge-and-Return | Notes |
|----------------|-------------------|-------|
| Leaf components | Perfect | Label, Image, Chart (no children) |
| Simple containers | Good | Card, Panel (children as single unit) |
| Complex layouts | Challenging | Grid, List (needs to measure/position each child) |

### When This Is Problematic

Components that need to **measure or position individual children** don't work well:

```
UIKit CollectionView (bridged)
    └── Needs to measure each cell individually
        └── But children are SwiftUI, returned as opaque unit
            └── Can't get individual cell sizes!
```

**Solutions for complex layout components:**
1. Implement in both systems (native layout in each)
2. Use a layout-agnostic approach (fixed sizes, scrolling containers)
3. Accept the limitation (children as single scrollable unit)

---

## Current vs Proposed Architecture

### Current: Separate Registries (No Fallback)

```
SwiftUINodeRendererRegistry          UIKitNodeRendererRegistry
        │                                    │
        ↓                                    ↓
   SwiftUI View                           UIView
   (or EmptyView)                     (or empty UIView)
```

- Each pipeline has its own registry
- Missing renderer returns empty view
- No cross-system fallback
- Components must be implemented twice for full coverage

### Proposed: Unified Registry with Bridging

```
              UnifiedNodeRendererRegistry
                         │
         ┌───────────────┼───────────────┐
         ↓               ↓               ↓
    SwiftUI Only    Both Exist      UIKit Only
         │               │               │
         ↓               ↓               ↓
   ┌─────────────────────────────────────────┐
   │           Rendering Context             │
   │  ┌─────────────┐   ┌─────────────┐     │
   │  │  SwiftUI    │   │   UIKit     │     │
   │  │  Pipeline   │   │  Pipeline   │     │
   │  └─────────────┘   └─────────────┘     │
   └─────────────────────────────────────────┘
         │                   │
         ↓                   ↓
   Native or            Native or
   UIViewRepresentable  UIHostingController
```

---

## Core Components

### 1. NodeRendererEntry

A unified entry that can hold either or both renderer types:

```swift
struct NodeRendererEntry {
    let nodeKind: RenderNodeKind
    var swiftUIRenderer: (any SwiftUINodeRendering)?
    var uiKitRenderer: (any UIKitNodeRendering)?
    var bridgingPreference: BridgingPreference
}

enum BridgingPreference {
    case preferNative   // Use native for current pipeline, bridge only if needed
    case preferSwiftUI  // Always use SwiftUI, even in UIKit context
    case preferUIKit    // Always use UIKit, even in SwiftUI context
}
```

### 2. UnifiedNodeRendererRegistry

Single registry that manages all renderers:

```swift
public final class UnifiedNodeRendererRegistry {
    private var entries: [RenderNodeKind: NodeRendererEntry] = [:]

    // MARK: - Registration

    /// Register a SwiftUI-only renderer
    public func register(_ renderer: some SwiftUINodeRendering)

    /// Register a UIKit-only renderer
    public func register(_ renderer: some UIKitNodeRendering)

    /// Register both renderers with preference
    public func register(
        swiftUI: some SwiftUINodeRendering,
        uiKit: some UIKitNodeRendering,
        preference: BridgingPreference = .preferNative
    )

    // MARK: - Rendering

    /// Render for SwiftUI pipeline (returns native, bridged, or EmptyView)
    public func renderForSwiftUI(
        _ node: RenderNode,
        context: SwiftUIRenderContext
    ) -> AnyView

    /// Render for UIKit pipeline (returns native, bridged, or empty UIView)
    public func renderForUIKit(
        _ node: RenderNode,
        context: UIKitRenderContext
    ) -> UIView

    // MARK: - Introspection

    /// Check what renderers are available for a node kind
    public func capabilities(for kind: RenderNodeKind) -> RendererCapabilities
}

enum RendererCapabilities {
    case none
    case swiftUIOnly
    case uiKitOnly
    case both
}
```

### 3. Bridging Wrappers

#### UIKit → SwiftUI Bridge (UIViewRepresentable)

```swift
struct BridgedUIKitView: UIViewRepresentable {
    let node: RenderNode
    let renderer: any UIKitNodeRendering
    let contextCore: RenderContextCore

    func makeUIView(context: Context) -> UIView {
        let uiKitContext = UIKitRenderContext(core: contextCore)
        return renderer.render(node, context: uiKitContext)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle state updates - may need to re-render
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIView,
        context: Context
    ) -> CGSize? {
        // Coordinate sizing between systems
        uiView.systemLayoutSizeFitting(/* ... */)
    }
}
```

#### SwiftUI → UIKit Bridge (UIHostingController wrapper)

```swift
final class BridgedSwiftUIView: UIView {
    private var hostingController: UIHostingController<AnyView>?
    private let node: RenderNode
    private let renderer: any SwiftUINodeRendering
    private let contextCore: RenderContextCore

    func setup() {
        let swiftUIContext = SwiftUIRenderContext(core: contextCore)
        let view = renderer.render(node, context: swiftUIContext)

        let hosting = UIHostingController(rootView: view)
        hosting.sizingOptions = [.intrinsicContentSize]
        // Add as child view controller and constrain
    }

    func updateContent() {
        // Re-render SwiftUI content when state changes
    }
}
```

---

## Rendering Flow

### SwiftUI Pipeline Rendering a Node

```
renderForSwiftUI(node, context)
         │
         ↓
┌────────────────────────────────────┐
│ Look up entry for node.kind        │
└────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────┐
│ Has SwiftUI renderer?                                  │
│                                                        │
│  YES → Render natively                                 │
│        │                                               │
│        └── If node has children:                       │
│            context.renderChildren(node.children)       │
│            → Children rendered as SwiftUI (origin)     │
│                                                        │
│  NO → Has UIKit renderer?                              │
│       │                                                │
│       YES → Bridge: wrap in UIViewRepresentable        │
│             │                                          │
│             └── Children pre-rendered as SwiftUI       │
│                 Passed to UIKit component as AnyView   │
│       │                                                │
│       NO → EmptyView                                   │
└────────────────────────────────────────────────────────┘
```

### UIKit Pipeline Rendering a Node

```
renderForUIKit(node, context)
         │
         ↓
┌────────────────────────────────────┐
│ Look up entry for node.kind        │
└────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────┐
│ Has UIKit renderer?                                    │
│                                                        │
│  YES → Render natively                                 │
│        │                                               │
│        └── If node has children:                       │
│            context.renderChildren(node.children)       │
│            → Children rendered as UIKit (origin)       │
│                                                        │
│  NO → Has SwiftUI renderer?                            │
│       │                                                │
│       YES → Bridge: wrap in UIHostingController        │
│             │                                          │
│             └── Children pre-rendered as UIKit         │
│                 Passed to SwiftUI component as UIView  │
│       │                                                │
│       NO → empty UIView                                │
└────────────────────────────────────────────────────────┘
```

### Key Insight: Children Are Pre-Rendered

The bridged component doesn't render its own children - they're rendered by the origin pipeline first:

```swift
// When bridging UIKit Chart into SwiftUI pipeline:

// 1. SwiftUI pipeline renders Chart's children first (as SwiftUI)
let childrenViews = context.renderChildren(chartNode.children)  // [AnyView]

// 2. Then wraps the UIKit chart, passing children as parameter
BridgedUIKitView(
    node: chartNode,
    renderer: uiKitChartRenderer,
    children: childrenViews  // Already rendered, just needs placement
)
```

This keeps the origin pipeline in control of the entire tree structure.

---

## Context Architecture

### Shared Context Core

Both systems share common state through a core object:

```swift
enum RenderPipeline {
    case swiftUI
    case uiKit
}

final class RenderContextCore {
    let stateStore: StateStore
    let actionContext: ActionContext
    let colorScheme: RenderColorScheme
    let unifiedRegistry: UnifiedNodeRendererRegistry
    let tree: RenderTree

    // The pipeline that started the render - children always return here
    let originPipeline: RenderPipeline
}
```

### Child Rendering Always Uses Origin

Children are always rendered in the origin pipeline, regardless of whether the parent was bridged:

```swift
extension RenderContextCore {
    /// Render children - always uses origin pipeline
    func renderChildren(_ nodes: [RenderNode]) -> RenderedChildren {
        switch originPipeline {
        case .swiftUI:
            // Children rendered as SwiftUI, wrapped for use anywhere
            let views = nodes.map { registry.renderSwiftUI($0, context: self) }
            return .swiftUI(views)

        case .uiKit:
            // Children rendered as UIKit, wrapped for use anywhere
            let views = nodes.map { registry.renderUIKit($0, context: self) }
            return .uiKit(views)
        }
    }
}

enum RenderedChildren {
    case swiftUI([AnyView])
    case uiKit([UIView])

    /// Get as SwiftUI views (wraps UIKit if needed)
    var asSwiftUI: [AnyView] {
        switch self {
        case .swiftUI(let views): return views
        case .uiKit(let views): return views.map { AnyView(UIViewWrapper($0)) }
        }
    }

    /// Get as UIKit views (wraps SwiftUI if needed)
    var asUIKit: [UIView] {
        switch self {
        case .uiKit(let views): return views
        case .swiftUI(let views): return views.map { HostingView($0) }
        }
    }
}
```

This means a bridged component receives children already rendered in the origin system. It just needs to place them.

### System-Specific Contexts

Each system wraps the core with conveniences:

```swift
// SwiftUI context
struct SwiftUIRenderContext {
    let core: RenderContextCore

    var stateStore: StateStore { core.stateStore }
    var actionContext: ActionContext { core.actionContext }
    var tree: RenderTree { core.tree }

    func render(_ node: RenderNode) -> AnyView {
        core.unifiedRegistry.renderForSwiftUI(node, context: self)
    }
}

// UIKit context
final class UIKitRenderContext {
    let core: RenderContextCore

    var stateStore: StateStore { core.stateStore }
    var actionContext: ActionContext { core.actionContext }
    var colorScheme: RenderColorScheme { core.colorScheme }

    func render(_ node: RenderNode) -> UIView {
        core.unifiedRegistry.renderForUIKit(node, context: self)
    }
}
```

---

## Registration API

### Simple Registration (Single System)

```swift
let registry = UnifiedNodeRendererRegistry()

// Register SwiftUI-only renderer
registry.register(LabelNodeSwiftUIRenderer())

// Register UIKit-only renderer
registry.register(ChartNodeUIKitRenderer())
```

### Dual Registration (Both Systems)

```swift
// Register both, prefer native for each pipeline
registry.register(
    swiftUI: ButtonNodeSwiftUIRenderer(),
    uiKit: ButtonNodeUIKitRenderer(),
    preference: .preferNative
)

// Register both, always use SwiftUI (even in UIKit pipeline)
registry.register(
    swiftUI: FancyAnimatedButtonSwiftUIRenderer(),
    uiKit: FancyAnimatedButtonUIKitRenderer(),
    preference: .preferSwiftUI  // SwiftUI animation is better
)
```

### Bulk Registration

```swift
// Register all built-in renderers
registry.registerBuiltIns()

// Register a plugin's renderers
registry.register(contentsOf: chartPlugin.renderers)
```

---

## Plugin Integration

Plugins provide renderers for one or both systems:

```swift
protocol CLADSPlugin {
    var swiftUIRenderers: [any SwiftUINodeRendering] { get }
    var uiKitRenderers: [any UIKitNodeRendering] { get }
    var bridgingPreferences: [RenderNodeKind: BridgingPreference] { get }
}
```

### Plugin Registration Flow

```
Plugin Registration
        │
        ↓
┌───────────────────────────────────────┐
│ For each SwiftUI renderer:            │
│   registry.register(swiftUIRenderer)  │
└───────────────────────────────────────┘
        │
        ↓
┌───────────────────────────────────────┐
│ For each UIKit renderer:              │
│   registry.register(uiKitRenderer)    │
└───────────────────────────────────────┘
        │
        ↓
┌───────────────────────────────────────┐
│ Apply bridging preferences            │
└───────────────────────────────────────┘
        │
        ↓
Both pipelines can now render
the plugin's components
```

---

## State Updates with Bridging

### UIKit in SwiftUI (UIViewRepresentable)

```
State Change (@Published)
         │
         ↓
SwiftUI detects change via ObservableObject
         │
         ↓
Calls updateUIView(_:context:)
         │
         ↓
BridgedUIKitView re-renders UIKit component
(or updates existing view in place)
```

### SwiftUI in UIKit (UIHostingController)

```
State Change
         │
         ↓
StateStore callback fires
         │
         ↓
BridgedSwiftUIView.updateContent()
         │
         ↓
Updates hostingController.rootView
         │
         ↓
SwiftUI re-renders internally
```

---

## Edge Cases & Considerations

### 1. Layout Coordination

UIKit and SwiftUI have different layout systems:

| Aspect | SwiftUI | UIKit |
|--------|---------|-------|
| Sizing | Proposed/ideal size | Intrinsic content size + constraints |
| Layout | Parent proposes, child responds | Auto Layout constraints |
| Updates | Declarative diff | Manual invalidation |

**Solutions:**

For `UIViewRepresentable`:
```swift
func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
    let targetSize = CGSize(
        width: proposal.width ?? UIView.layoutFittingCompressedSize.width,
        height: proposal.height ?? UIView.layoutFittingCompressedSize.height
    )
    return uiView.systemLayoutSizeFitting(
        targetSize,
        withHorizontalFittingPriority: .fittingSizeLevel,
        verticalFittingPriority: .fittingSizeLevel
    )
}
```

For `UIHostingController`:
```swift
hostingController.sizingOptions = [.intrinsicContentSize]
// or for scrollable content:
hostingController.sizingOptions = [.preferredContentSize]
```

### 2. Action Context Sharing

Both systems need the same ActionContext:

```swift
// Shared via RenderContextCore
let core = RenderContextCore(
    stateStore: stateStore,
    actionContext: actionContext,  // Same instance for both
    // ...
)

// SwiftUI accesses via @EnvironmentObject (injected at top level)
// UIKit accesses via context property
```

### 3. Performance Considerations

With bridge-and-return, performance is simpler to reason about:

| Scenario | Overhead |
|----------|----------|
| Native rendering | None |
| Bridged leaf component | One wrapper (minimal) |
| Bridged container | One wrapper + children re-wrapped for placement |

Since children return to the origin pipeline, you don't get cascading bridges. The worst case is a bridged component that needs to place origin-rendered children.

### 4. Animation Coordination

Animations may not transfer smoothly across bridges:

| Animation Type | Cross-Bridge Behavior |
|----------------|----------------------|
| SwiftUI implicit | Won't animate UIKit views |
| UIKit UIView.animate | Won't animate SwiftUI views |
| Core Animation | Works on any layer |

**Recommendation:** For animated components, implement in both systems or use Core Animation.

---

## File Structure

```
CLADS/Renderers/
├── Unified/
│   ├── UnifiedNodeRendererRegistry.swift
│   ├── NodeRendererEntry.swift
│   ├── RenderContextCore.swift
│   ├── BridgingPreference.swift
│   └── RendererCapabilities.swift
│
├── Bridging/
│   ├── BridgedUIKitView.swift          (UIViewRepresentable)
│   ├── BridgedSwiftUIView.swift        (UIHostingController wrapper)
│   └── BridgeDepthEnvironment.swift    (SwiftUI environment key)
│
├── SwiftUI/
│   ├── SwiftUINodeRendering.swift      (protocol - unchanged)
│   ├── SwiftUIRenderContext.swift      (updated to wrap core)
│   ├── SwiftUIRenderer.swift           (updated to use unified registry)
│   └── Nodes/
│       ├── LabelNodeSwiftUIRenderer.swift
│       ├── ButtonNodeSwiftUIRenderer.swift
│       └── ...
│
└── UIKit/
    ├── UIKitNodeRendering.swift        (protocol - unchanged)
    ├── UIKitRenderContext.swift        (updated to wrap core)
    ├── UIKitRenderer.swift             (updated to use unified registry)
    └── Nodes/
        ├── TextNodeRenderer.swift
        ├── ButtonNodeRenderer.swift
        └── ...
```

---

## Migration Path

### Phase 1: Create Unified Infrastructure

- Create `RenderContextCore`
- Create `UnifiedNodeRendererRegistry`
- Create `NodeRendererEntry` and `BridgingPreference`

**No breaking changes** - existing code continues to work.

### Phase 2: Add Bridging Wrappers

- Implement `BridgedUIKitView` (UIViewRepresentable)
- Implement `BridgedSwiftUIView` (UIHostingController wrapper)
- Add bridge depth tracking

**No breaking changes** - wrappers are additive.

### Phase 3: Update Renderers to Use Unified Registry

- Update `SwiftUIRenderer` to use `UnifiedNodeRendererRegistry`
- Update `UIKitRenderer` to use `UnifiedNodeRendererRegistry`
- Update context types to wrap `RenderContextCore`

**Soft deprecation** of old separate registries.

### Phase 4: Migrate Existing Registrations

- Move existing SwiftUI renderers to unified registration
- Move existing UIKit renderers to unified registration
- Update plugin registration API

**Old API deprecated** but still functional.

### Phase 5: Remove Legacy Code

- Remove `SwiftUINodeRendererRegistry` (old)
- Remove `UIKitNodeRendererRegistry` (old)
- Remove deprecated registration methods

**Breaking change** - major version bump.

---

## API Comparison

### Current API

```swift
// Two separate registries
let swiftUIRegistry = SwiftUINodeRendererRegistry()
swiftUIRegistry.register(LabelNodeSwiftUIRenderer())

let uiKitRegistry = UIKitNodeRendererRegistry()
uiKitRegistry.register(TextNodeRenderer())

// Must pass correct registry to each renderer
let swiftUIRenderer = SwiftUIRenderer(registry: swiftUIRegistry)
let uiKitRenderer = UIKitRenderer(registry: uiKitRegistry)
```

### Proposed API

```swift
// Single unified registry
let registry = UnifiedNodeRendererRegistry()

// Register once, works in both pipelines
registry.register(LabelNodeSwiftUIRenderer())  // SwiftUI native, bridges to UIKit
registry.register(ChartNodeUIKitRenderer())    // UIKit native, bridges to SwiftUI

// Both renderers use same registry
let swiftUIRenderer = SwiftUIRenderer(registry: registry)
let uiKitRenderer = UIKitRenderer(registry: registry)
```

---

## Summary

| Feature | Current | Proposed |
|---------|---------|----------|
| Registry | Two separate | One unified |
| Missing renderer | Empty view | Bridge from other system |
| Implement component once | No | Yes |
| Native preferred | N/A | Configurable per component |
| Plugin support | Register in both | Register once, works in both |
| Bridge depth tracking | N/A | Yes, with warnings |
| Layout coordination | N/A | Built-in sizing helpers |

This design enables implementing components in whichever system is most convenient while automatically providing support in both rendering pipelines.
