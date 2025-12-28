# CladsRenderer

A server-driven UI framework for iOS that renders native SwiftUI and UIKit views from JSON definitions.

## Overview

CladsRenderer uses an LLVM-inspired multi-stage pipeline to transform JSON into native UI:

```
JSON → Document (AST) → RenderTree (IR) → Renderer → Native UI
```

This architecture enables:
- **Server-driven UI**: Update your app's UI without app store releases
- **Multiple renderers**: SwiftUI, UIKit, and debug output from the same IR
- **Type-safe resolution**: Styles, data bindings, and actions resolved at parse time
- **Reactive state**: Built-in state management with two-way binding

## Quick Start

```swift
import SwiftUI
import CladsRendererFramework

struct ContentView: View {
    var body: some View {
        if let view = CladsRendererView(jsonString: jsonDocument) {
            view
        }
    }
}
```

## Example JSON

```json
{
  "id": "hello-world",
  "version": "1.0",
  "styles": {
    "title": {
      "fontSize": 24,
      "fontWeight": "bold"
    }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 16,
        "children": [
          { "type": "label", "label": "Hello, World!", "styleId": "title" },
          { "type": "button", "label": "Tap Me" }
        ]
      }
    ]
  }
}
```

## Documentation

### Core Concepts

| Document | Description |
|----------|-------------|
| [Rendering Pipeline](Docs/RenderingPipeline.md) | How JSON transforms into native UI through the multi-stage pipeline |
| [Components](Docs/Components.md) | Available UI components (label, button, textfield, image, gradient) |
| [Layouts](Docs/Layouts.md) | Layout containers (vstack, hstack, zstack, sectionLayout) |
| [Styling](Docs/Styling.md) | Style system with inheritance and resolution |
| [Actions](Docs/Actions.md) | Action system for handling user interactions |
| [State](Docs/State.md) | State management and data binding |

### Reference

| Document | Description |
|----------|-------------|
| [Future Enhancements](Docs/FutureEnhancements.md) | Planned features and potential renderer implementations |

## Architecture

```
CladsRendererFramework/
├── Document/            # Document.* namespace - JSON schema types (AST)
│   ├── Document.swift        # Document.Definition, Document.StateValue
│   ├── Component.swift       # Document.Component
│   ├── LayoutNode.swift      # Document.LayoutNode, Document.Layout
│   ├── SectionLayout.swift   # Document.SectionLayout, Document.SectionDefinition
│   ├── Style.swift           # Document.Style
│   ├── Action.swift          # Document.Action
│   └── DataSource.swift      # Document.DataSource
├── IR/                  # Intermediate representation
│   ├── IR.swift              # IR.* namespace - IR.Style, IR.Section
│   ├── RenderTree.swift      # RenderTree, RenderNode, node types
│   ├── Resolver.swift        # Document → RenderTree resolution
│   └── Resolution/           # Specialized resolvers
├── Renderers/           # Output renderers
│   ├── SwiftUIRenderer.swift
│   ├── CladsUIKitView.swift
│   └── DebugRenderer.swift
├── Rendering/           # SwiftUI view components
│   ├── CladsRendererView.swift
│   └── ComponentViews/
├── Actions/             # Action handling
│   └── Handlers/
├── State/               # State management
│   └── StateStore.swift
└── Styles/              # Style resolution
    └── StyleResolver.swift
```

### Type Namespaces

| Layer | Namespace | Description |
|-------|-----------|-------------|
| JSON Schema (AST) | `Document.*` | Decoded JSON types: `Document.Definition`, `Document.Component`, `Document.Style` |
| Intermediate Representation | `IR.*` | Resolved types: `IR.Style`, `IR.Section`, `IR.SectionType` |
| Render Tree | (none) | Renderer-agnostic nodes: `RenderTree`, `RenderNode`, `TextNode`, `ButtonNode` |

## Features

### Components
- **label**: Text display with static or dynamic content
- **button**: Interactive buttons with action handlers
- **textfield**: Text input with two-way state binding
- **image**: System icons, assets, or remote URLs
- **gradient**: Linear gradients with light/dark mode support
- **spacer**: Flexible spacing

### Layouts
- **vstack**: Vertical arrangement
- **hstack**: Horizontal arrangement
- **zstack**: Overlapping layers
- **sectionLayout**: Complex section-based layouts (horizontal scroll, list, grid)

### Styling
- Named styles with inheritance
- Font, color, size, and appearance properties
- Style resolution and flattening

### Actions
- **dismiss**: Close the current view
- **setState**: Update state values
- **showAlert**: Display alert dialogs
- **sequence**: Chain multiple actions
- **navigate**: Navigate between screens

### State
- Observable state store
- Path-based access (dot notation)
- Template interpolation
- Two-way binding for text fields

## Renderers

| Renderer | Output | Use Case |
|----------|--------|----------|
| `SwiftUIRenderer` | SwiftUI `View` | Primary iOS/macOS rendering |
| `UIKitRenderer` | `UIView` | UIKit apps, custom integrations |
| `DebugRenderer` | `String` | Debugging, logging |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## License

[Your License Here]
