# Rendering Pipeline

CladsRenderer uses an LLVM-inspired multi-stage pipeline to transform JSON into native UI. This architecture provides clear separation of concerns, enables multiple rendering backends, and facilitates debugging at each stage.

## Pipeline Overview

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│    JSON     │ ──▶ │   Document   │ ──▶ │ RenderTree  │ ──▶ │   Renderer   │
│   (Input)   │     │    (AST)     │     │    (IR)     │     │   (Output)   │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                          │                     │                    │
                      Parsing              Resolution            Rendering
                    (Decoding)         (Style/Data/Action)    (SwiftUI/UIKit)
```

## Stage 1: JSON Input

The pipeline begins with a JSON document that describes the UI declaratively. This JSON can come from:
- A remote server (server-driven UI)
- Local files bundled with the app
- Runtime generation

### Example JSON Structure

```json
{
  "id": "screen-id",
  "version": "1.0",
  "state": { ... },
  "styles": { ... },
  "dataSources": { ... },
  "actions": { ... },
  "root": { ... }
}
```

## Stage 2: Document (AST)

The JSON is parsed into a **Document.Definition** - the Abstract Syntax Tree representation. This stage:

- Validates JSON structure
- Decodes into strongly-typed Swift structures under the `Document.*` namespace
- Preserves all references (style IDs, data source IDs, action IDs) as strings

### Key Types

| Type | Description |
|------|-------------|
| `Document.Definition` | Root container holding all document sections |
| `Document.RootComponent` | The root view configuration (background, insets, children) |
| `Document.LayoutNode` | Enum representing layouts, section layouts, components, or spacers |
| `Document.Layout` | Container types (VStack, HStack, ZStack) |
| `Document.SectionLayout` | Section-based layouts with heterogeneous sections |
| `Document.Component` | Leaf UI elements (label, button, textfield, image, gradient) |
| `Document.Style` | Visual styling with inheritance support |
| `Document.DataSource` | Static or bound data references |
| `Document.Action` | Action configurations (dismiss, setState, showAlert, etc.) |

### File Locations

```
CladsRendererFramework/Document/
├── Document.swift         # Document enum namespace, Document.Definition
├── RootComponent.swift    # Document.RootComponent
├── LayoutNode.swift       # Document.LayoutNode, Document.Layout
├── Component.swift        # Document.Component
├── SectionLayout.swift    # Document.SectionLayout, Document.SectionDefinition
├── Style.swift            # Document.Style
├── DataSource.swift       # Document.DataSource
└── Action.swift           # Document.Action
```

## Stage 3: Resolver

The **Resolver** transforms the Document (AST) into a **RenderTree** (IR). This is where all references are resolved:

### Resolution Process

1. **Style Resolution**: Style IDs are resolved, inheritance is flattened, and final `IR.Style` objects are created
2. **Data Binding**: Data source references are resolved against the `StateStore`
3. **Action Resolution**: Action definitions are parsed and validated
4. **Layout Resolution**: Layout nodes are converted to `RenderNode` with resolved properties

### Key Transformations

| AST (Input) | IR (Output) |
|-------------|-------------|
| `Document.Layout` | `ContainerNode` |
| `Document.SectionLayout` | `SectionLayoutNode` |
| `Document.Component` (label) | `TextNode` |
| `Document.Component` (button) | `ButtonNode` |
| `Document.Component` (textfield) | `TextFieldNode` |
| `Document.Component` (image) | `ImageNode` |
| `Document.Component` (gradient) | `GradientNode` |
| `Document.Style` (by ID) | `IR.Style` |
| `Document.SectionDefinition` | `IR.Section` |

### File Location

```
CladsRendererFramework/IR/
├── IR.swift           # IR namespace: IR.Style, IR.Section, IR.SectionType
├── Resolver.swift     # Main resolver
├── RenderTree.swift   # RenderTree, RenderNode, node types
└── Resolution/        # Specialized resolvers
```

## Stage 4: RenderTree (IR)

The **RenderTree** is the Intermediate Representation - a fully resolved, renderer-agnostic tree ready for rendering. At this stage:

- All style inheritance is flattened
- All data bindings are resolved to concrete values
- All references are validated
- The tree structure matches the final UI hierarchy

### Key Types

| Type | Description |
|------|-------------|
| `RenderTree` | Root container with resolved tree and state store |
| `RootNode` | Resolved root with background, insets, color scheme |
| `RenderNode` | Enum of all renderable node types |
| `ContainerNode` | Resolved VStack/HStack/ZStack |
| `SectionLayoutNode` | Resolved section-based layout |
| `TextNode` | Resolved text with content and style |
| `ButtonNode` | Resolved button with label, style, action |
| `TextFieldNode` | Resolved text input with binding |
| `ImageNode` | Resolved image with source |
| `GradientNode` | Resolved gradient with adaptive colors |
| `IR.Style` | Flattened style properties |
| `IR.Section` | Resolved section with layout type and config |

### IR Design Principles

1. **Renderer-Agnostic**: No SwiftUI or UIKit types in the IR
2. **Fully Resolved**: No unresolved references or lazy evaluation
3. **Immutable**: The tree doesn't change after resolution
4. **Self-Contained**: All information needed for rendering is present

## Stage 5: Renderer

The final stage transforms the RenderTree into platform-specific UI. Multiple renderers can consume the same IR:

### Available Renderers

| Renderer | Output | Use Case |
|----------|--------|----------|
| `SwiftUIRenderer` | SwiftUI `View` | Primary iOS/macOS rendering |
| `UIKitRenderer` | `UIView` | UIKit-based apps, custom integrations |
| `DebugRenderer` | `String` | Console debugging, logging |

### Renderer Protocol

```swift
public protocol Renderer {
    associatedtype Output
    func render(_ tree: RenderTree) -> Output
}
```

### Rendering Process

Each renderer traverses the RenderTree and creates corresponding platform views:

```swift
// SwiftUI
case .text(let text):
    Text(text.content)
        .applyTextStyle(text.style)

// UIKit
case .text(let text):
    let label = UILabel()
    label.text = text.content
    label.applyStyle(text.style)
    return label
```

### File Locations

```
CladsRendererFramework/Renderers/
├── Renderer.swift          // Protocol definition
├── SwiftUIRenderer.swift   // SwiftUI implementation
├── UIKitRenderer.swift     // UIKit implementation
└── DebugRenderer.swift     // Debug string output
```

## Data Flow Diagram

```
                                       ┌─────────────────┐
                                       │   StateStore    │
                                       │  (Observable)   │
                                       └────────┬────────┘
                                                │
                                                ▼
┌──────────┐    ┌───────────────────┐    ┌───────────────────┐    ┌─────────────┐
│   JSON   │───▶│ Document.Definition│───▶│     Resolver      │───▶│ RenderTree  │
└──────────┘    └───────────────────┘    └───────────────────┘    └──────┬──────┘
                                                │                        │
                                                ▼                        │
                                       ┌─────────────────┐               │
                                       │  StyleResolver  │               │
                                       │ (→ IR.Style)    │               │
                                       └─────────────────┘               │
                                                                         │
                    ┌────────────────────────────────────────────────────┤
                    │                   │                                │
                    ▼                   ▼                                ▼
            ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
            │ SwiftUI View │    │   UIView     │    │   Debug String   │
            └──────────────┘    └──────────────┘    └──────────────────┘
```

## Runtime Interaction

After rendering, the UI can interact with the system:

### Actions
User interactions trigger actions defined in the JSON:
```
User Tap → ButtonNode.onTap → ActionContext.executeAction → ActionHandler
```

### State Updates
State changes flow back through the system:
```
Action (setState) → StateStore.set → @Published update → SwiftUI re-render
```

### Data Binding
Two-way binding for text fields:
```
User Input → TextFieldNode.bindingPath → StateStore.set → Other bound views update
```

## Debugging the Pipeline

### Debug Renderer Output

Use `DebugRenderer` to inspect the resolved tree:

```swift
let debugRenderer = DebugRenderer()
let output = debugRenderer.render(renderTree)
print(output)
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RenderTree
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Root:
  root (bg: #FFFFFF)
    vstack (spacing: 8, align: center)
      text (content: "Hello World")
      button (label: "Tap Me", onTap: doSomething)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Document Debug Description

Inspect the parsed AST:

```swift
print(document.debugDescription)
```

## Performance Considerations

1. **Resolution is O(n)**: Single pass through the document tree
2. **Style Resolution is Cached**: `StyleResolver` caches flattened styles
3. **Lazy Rendering**: SwiftUI/UIKit renderers use lazy stacks where appropriate
4. **State Updates are Granular**: Only affected views re-render on state changes

## Extending the Pipeline

### Adding a New Component

1. Add to `Document.Component.Kind` enum in `Document/Component.swift`
2. Add properties to `Document.Component` struct
3. Add IR node type in `IR/RenderTree.swift`
4. Add resolution in `IR/Resolver.swift` or create a new resolver
5. Add rendering in each renderer (SwiftUI, UIKit, Debug)

### Adding a New Renderer

1. Conform to `Renderer` protocol
2. Implement `render(_ tree: RenderTree) -> Output`
3. Handle all `RenderNode` cases
