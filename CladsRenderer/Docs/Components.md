# Components

Components are the leaf nodes in the CLADS layout tree. They represent individual UI elements that display content or capture user input.

## Component Types

| Type | Description | Key Properties |
|------|-------------|----------------|
| `label` | Text display | `label`, `dataSourceId`, `styleId` |
| `button` | Tappable button | `label`, `styleId`, `fillWidth`, `actions` |
| `textfield` | Text input | `placeholder`, `bind`, `styleId` |
| `image` | Image display | `data`, `styleId` |
| `gradient` | Gradient overlay | `gradientColors`, `gradientStart`, `gradientEnd` |

---

## Label

Displays static or dynamic text content.

### JSON Schema

```json
{
  "type": "label",
  "id": "optional-id",
  "label": "Static text content",
  "styleId": "textStyle",
  "dataSourceId": "dynamicTextSource"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"label"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier for the component |
| `label` | `string` | No | Static text content |
| `styleId` | `string` | No | Reference to a style definition |
| `dataSourceId` | `string` | No | Reference to a data source for dynamic content |
| `data` | `DataReference` | No | Inline data reference |

### Text Resolution Priority

1. `data` (inline data reference)
2. `dataSourceId` (named data source)
3. `label` (static text)

### Example

```json
{
  "styles": {
    "titleStyle": {
      "fontSize": 24,
      "fontWeight": "bold",
      "textColor": "#000000"
    }
  },
  "dataSources": {
    "greeting": { "type": "static", "value": "Hello, World!" }
  },
  "root": {
    "children": [
      {
        "type": "label",
        "id": "greetingLabel",
        "styleId": "titleStyle",
        "dataSourceId": "greeting"
      }
    ]
  }
}
```

### IR Mapping

```swift
// AST (Document namespace)
Document.Component(type: .label, label: "Hello", styleId: "titleStyle")

// IR (RenderNode)
TextNode(id: "greetingLabel", content: "Hello, World!", style: IR.Style(...))
```

---

## Button

An interactive button that triggers actions when tapped.

### JSON Schema

```json
{
  "type": "button",
  "id": "optional-id",
  "label": "Button Text",
  "styleId": "buttonStyle",
  "fillWidth": true,
  "actions": {
    "onTap": "actionId"
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"button"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `label` | `string` | Yes | Button text |
| `styleId` | `string` | No | Reference to a style definition |
| `fillWidth` | `boolean` | No | Whether button expands to fill container width |
| `actions.onTap` | `string` | No | Action ID to execute on tap |

### Styling

Buttons support additional style properties:

```json
{
  "buttonStyle": {
    "backgroundColor": "#007AFF",
    "textColor": "#FFFFFF",
    "cornerRadius": 12,
    "height": 50,
    "fontSize": 17,
    "fontWeight": "semibold"
  }
}
```

### Example

```json
{
  "styles": {
    "primaryButton": {
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 50
    }
  },
  "actions": {
    "submitForm": {
      "type": "dismiss"
    }
  },
  "root": {
    "children": [
      {
        "type": "button",
        "id": "submitButton",
        "label": "Submit",
        "styleId": "primaryButton",
        "fillWidth": true,
        "actions": {
          "onTap": "submitForm"
        }
      }
    ]
  }
}
```

### IR Mapping

```swift
// AST (Document namespace)
Document.Component(type: .button, label: "Submit", styleId: "primaryButton", ...)

// IR (RenderNode)
ButtonNode(
    id: "submitButton",
    label: "Submit",
    style: IR.Style(...),
    fillWidth: true,
    onTap: .reference("submitForm")
)
```

---

## TextField

A text input field with optional state binding.

### JSON Schema

```json
{
  "type": "textfield",
  "id": "optional-id",
  "placeholder": "Enter text...",
  "styleId": "inputStyle",
  "bind": "state.path"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"textfield"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `placeholder` | `string` | No | Placeholder text |
| `styleId` | `string` | No | Reference to a style definition |
| `bind` | `string` | No | State path for two-way binding |

### Two-Way Binding

When `bind` is specified, the text field:
1. Initializes with the current state value
2. Updates the state as the user types
3. Reflects external state changes

### Example

```json
{
  "state": {
    "username": ""
  },
  "styles": {
    "inputStyle": {
      "fontSize": 16,
      "textColor": "#000000"
    }
  },
  "root": {
    "children": [
      {
        "type": "textfield",
        "id": "usernameInput",
        "placeholder": "Enter username",
        "styleId": "inputStyle",
        "bind": "username"
      }
    ]
  }
}
```

### IR Mapping

```swift
// AST (Document namespace)
Document.Component(type: .textfield, placeholder: "Enter username", bind: "username", ...)

// IR (RenderNode)
TextFieldNode(
    id: "usernameInput",
    placeholder: "Enter username",
    style: IR.Style(...),
    bindingPath: "username"
)
```

---

## Image

Displays images from various sources.

### JSON Schema

```json
{
  "type": "image",
  "id": "optional-id",
  "data": {
    "type": "static",
    "value": "source-string"
  },
  "styleId": "imageStyle"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"image"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `data` | `DataReference` | Yes | Image source reference |
| `styleId` | `string` | No | Reference to a style definition |

### Image Sources

The `data.value` string supports three prefixes:

| Prefix | Description | Example |
|--------|-------------|---------|
| `system:` | SF Symbol name | `"system:star.fill"` |
| `url:` | Remote image URL | `"url:https://example.com/image.jpg"` |
| (none) | Asset catalog name | `"heroImage"` |

### Size Styling

```json
{
  "imageStyle": {
    "width": 100,
    "height": 100
  }
}
```

### Example

```json
{
  "styles": {
    "heroImage": {
      "height": 300
    }
  },
  "root": {
    "children": [
      {
        "type": "image",
        "id": "backgroundImage",
        "data": {
          "type": "static",
          "value": "url:https://example.com/photo.jpg"
        },
        "styleId": "heroImage"
      }
    ]
  }
}
```

### IR Mapping

```swift
// AST (Document namespace)
Document.Component(type: .image, data: Document.DataSource(...), ...)

// IR (RenderNode)
ImageNode(
    id: "backgroundImage",
    source: .url(URL(string: "https://example.com/photo.jpg")!),
    style: IR.Style(...)
)

// ImageNode.Source enum (nested)
extension ImageNode {
    enum Source {
        case system(name: String)  // SF Symbols
        case asset(name: String)   // Asset catalog
        case url(URL)              // Remote URL
    }
}
```

---

## Gradient

Displays a gradient overlay, typically used with ZStack for image overlays.

### JSON Schema

```json
{
  "type": "gradient",
  "id": "optional-id",
  "gradientColors": [
    { "color": "#FFFFFF", "location": 0.0 },
    { "color": "#00FFFFFF", "location": 1.0 }
  ],
  "gradientStart": "bottom",
  "gradientEnd": "top",
  "styleId": "gradientStyle"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"gradient"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `gradientColors` | `[GradientColorConfig]` | Yes | Array of color stops |
| `gradientStart` | `string` | No | Gradient start point (default: "bottom") |
| `gradientEnd` | `string` | No | Gradient end point (default: "top") |
| `styleId` | `string` | No | Reference to a style definition |

### Gradient Color Stops

Each color stop can be:

**Fixed color:**
```json
{ "color": "#FF0000", "location": 0.5 }
```

**Adaptive color (light/dark mode):**
```json
{
  "lightColor": "#FFFFFFFF",
  "darkColor": "#FF000000",
  "location": 0.0
}
```

### Gradient Points

| Value | Position |
|-------|----------|
| `top` | Top center |
| `bottom` | Bottom center |
| `leading` | Left center |
| `trailing` | Right center |
| `topLeading` | Top left |
| `topTrailing` | Top right |
| `bottomLeading` | Bottom left |
| `bottomTrailing` | Bottom right |

### Color Format

Colors use ARGB hex format:
- `#RRGGBB` - Opaque color (alpha = FF)
- `#AARRGGBB` - Color with alpha

Examples:
- `#FF0000` - Red (opaque)
- `#FFFF0000` - Red (opaque, explicit alpha)
- `#80FF0000` - Red (50% transparent)
- `#00FFFFFF` - White (fully transparent)

### Example: Image Overlay

```json
{
  "type": "zstack",
  "children": [
    {
      "type": "image",
      "data": { "type": "static", "value": "url:https://..." },
      "styleId": "heroImage"
    },
    {
      "type": "gradient",
      "gradientColors": [
        { "lightColor": "#FFFFFFFF", "darkColor": "#FF000000", "location": 0.0 },
        { "lightColor": "#00FFFFFF", "darkColor": "#00000000", "location": 0.4 }
      ],
      "gradientStart": "bottom",
      "gradientEnd": "top",
      "styleId": "heroGradient"
    }
  ]
}
```

### IR Mapping

```swift
// AST (Document namespace)
Document.Component(type: .gradient, gradientColors: [...], ...)

// IR (RenderNode)
GradientNode(
    id: "overlayGradient",
    gradientType: .linear,
    colors: [
        GradientNode.ColorStop(
            color: .adaptive(light: .white, dark: .black),
            location: 0.0
        ),
        GradientNode.ColorStop(
            color: .adaptive(light: .white.opacity(0), dark: .black.opacity(0)),
            location: 0.4
        )
    ],
    startPoint: .bottom,
    endPoint: .top,
    style: IR.Style(...)
)
```

---

## Spacer

A flexible space that expands to fill available space.

### JSON Schema

```json
{
  "type": "spacer"
}
```

### Usage

Spacers are commonly used to:
- Push content to edges
- Create equal spacing between elements
- Center content vertically or horizontally

### Example

```json
{
  "type": "vstack",
  "children": [
    { "type": "spacer" },
    { "type": "label", "label": "Centered Content" },
    { "type": "spacer" }
  ]
}
```

### IR Mapping

```swift
// IR
RenderNode.spacer
```

---

## Common Properties

All components share these optional properties:

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | Unique identifier for the component |
| `styleId` | `string` | Reference to a named style |

## Data References

Components can reference data in two ways:

### Inline Data Reference

```json
{
  "data": {
    "type": "static",
    "value": "Hello World"
  }
}
```

### Named Data Source

```json
{
  "dataSources": {
    "greeting": { "type": "static", "value": "Hello World" }
  },
  "root": {
    "children": [
      {
        "type": "label",
        "dataSourceId": "greeting"
      }
    ]
  }
}
```

### Binding Data Reference

```json
{
  "data": {
    "type": "binding",
    "path": "user.name"
  }
}
```

### Template Data Reference

```json
{
  "data": {
    "type": "binding",
    "template": "Hello, ${user.name}!"
  }
}
```
