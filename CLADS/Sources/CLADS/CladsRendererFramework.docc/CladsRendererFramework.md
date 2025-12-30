# ``CladsRendererFramework``

A server-driven UI framework that renders native SwiftUI and UIKit views from JSON definitions.

## Overview

CladsRendererFramework uses an LLVM-inspired multi-stage pipeline to transform JSON into native UI:

```
JSON → Document.Definition (AST) → RenderTree (IR) → Renderer → Native UI
```

### Type Namespaces

The framework organizes types into clear namespaces:

| Layer | Namespace | Description |
|-------|-----------|-------------|
| JSON Schema (AST) | `Document.*` | Decoded JSON types |
| Intermediate Representation | `IR.*` | Resolved types |
| Render Tree | (none) | Renderer-agnostic nodes |

## Topics

### Getting Started

- ``CladsRendererView``
- ``CladsUIKitView``

### Document Types (AST)

- ``Document``
- ``Document/Definition``
- ``Document/Component``
- ``Document/Layout``
- ``Document/Style``
- ``Document/Action``

### Intermediate Representation

- ``IR``
- ``IR/Style``
- ``IR/Section``
- ``RenderTree``
- ``RenderNode``

### Renderers

- ``SwiftUIRenderer``
- ``DebugRenderer``

### State Management

- ``StateStore``
- ``ActionContext``
