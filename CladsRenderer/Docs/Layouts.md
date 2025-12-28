# Layouts

Layouts are container nodes that arrange their children in specific patterns. CLADS supports both simple stack-based layouts and complex section-based layouts.

## Layout Types

| Type | Description | Alignment |
|------|-------------|-----------|
| `vstack` | Vertical stack | Horizontal alignment |
| `hstack` | Horizontal stack | Vertical alignment |
| `zstack` | Overlay stack | 2D alignment |
| `sectionLayout` | Section-based layout | Per-section |

---

## VStack

Arranges children vertically from top to bottom.

### JSON Schema

```json
{
  "type": "vstack",
  "alignment": "center",
  "spacing": 8,
  "padding": { ... },
  "children": [ ... ]
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `"vstack"` | - | Layout type identifier |
| `alignment` | `string` | `"center"` | Horizontal alignment of children |
| `spacing` | `number` | `8` | Space between children (points) |
| `padding` | `Padding` | - | Padding around the stack |
| `children` | `[LayoutNode]` | `[]` | Child nodes |

### Alignment Values

| Value | Description |
|-------|-------------|
| `leading` | Align to left edge |
| `center` | Center horizontally |
| `trailing` | Align to right edge |

### Example

```json
{
  "type": "vstack",
  "alignment": "leading",
  "spacing": 12,
  "padding": { "horizontal": 16 },
  "children": [
    { "type": "label", "label": "Title", "styleId": "titleStyle" },
    { "type": "label", "label": "Subtitle", "styleId": "subtitleStyle" },
    { "type": "button", "label": "Action", "styleId": "buttonStyle" }
  ]
}
```

### Visual Representation

```
┌──────────────────────────────┐
│  ┌────────────────────────┐  │
│  │ Title                  │  │
│  └────────────────────────┘  │
│           ↕ spacing          │
│  ┌────────────────────────┐  │
│  │ Subtitle               │  │
│  └────────────────────────┘  │
│           ↕ spacing          │
│  ┌────────────────────────┐  │
│  │        Action          │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

---

## HStack

Arranges children horizontally from leading to trailing.

### JSON Schema

```json
{
  "type": "hstack",
  "alignment": { "vertical": "center" },
  "spacing": 8,
  "padding": { ... },
  "children": [ ... ]
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `"hstack"` | - | Layout type identifier |
| `alignment` | `object` | `{"vertical": "center"}` | Vertical alignment of children |
| `spacing` | `number` | `8` | Space between children (points) |
| `padding` | `Padding` | - | Padding around the stack |
| `children` | `[LayoutNode]` | `[]` | Child nodes |

### Alignment Values

| Value | Description |
|-------|-------------|
| `top` | Align to top edge |
| `center` | Center vertically |
| `bottom` | Align to bottom edge |

### Example

```json
{
  "type": "hstack",
  "alignment": { "vertical": "center" },
  "spacing": 12,
  "children": [
    { "type": "image", "data": { "type": "static", "value": "system:person.circle" } },
    { "type": "label", "label": "Username" },
    { "type": "spacer" },
    { "type": "image", "data": { "type": "static", "value": "system:chevron.right" } }
  ]
}
```

### Visual Representation

```
┌──────────────────────────────────────────┐
│  ┌───┐  ┌──────────┐          ┌───┐     │
│  │ 👤│  │ Username │ <spacer> │ > │     │
│  └───┘  └──────────┘          └───┘     │
└──────────────────────────────────────────┘
```

---

## ZStack

Overlays children on top of each other (back to front).

### JSON Schema

```json
{
  "type": "zstack",
  "alignment": {
    "horizontal": "center",
    "vertical": "center"
  },
  "padding": { ... },
  "children": [ ... ]
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `"zstack"` | - | Layout type identifier |
| `alignment` | `object` | `{"horizontal": "center", "vertical": "center"}` | 2D alignment |
| `padding` | `Padding` | - | Padding around the stack |
| `children` | `[LayoutNode]` | `[]` | Child nodes (first = back, last = front) |

### Alignment Object

```json
{
  "alignment": {
    "horizontal": "leading" | "center" | "trailing",
    "vertical": "top" | "center" | "bottom"
  }
}
```

### Common Alignment Combinations

| Alignment | Position |
|-----------|----------|
| `{ "horizontal": "center", "vertical": "center" }` | Center |
| `{ "horizontal": "leading", "vertical": "top" }` | Top-left |
| `{ "horizontal": "trailing", "vertical": "bottom" }` | Bottom-right |

### Example: Image with Text Overlay

```json
{
  "type": "zstack",
  "alignment": { "horizontal": "leading", "vertical": "bottom" },
  "children": [
    {
      "type": "image",
      "data": { "type": "static", "value": "url:https://example.com/photo.jpg" },
      "styleId": "heroImage"
    },
    {
      "type": "gradient",
      "gradientColors": [
        { "color": "#FF000000", "location": 0.0 },
        { "color": "#00000000", "location": 0.5 }
      ],
      "gradientStart": "bottom",
      "gradientEnd": "top",
      "styleId": "overlayGradient"
    },
    {
      "type": "vstack",
      "alignment": "leading",
      "padding": { "leading": 16, "bottom": 16 },
      "children": [
        { "type": "label", "label": "Photo Title", "styleId": "overlayTitle" }
      ]
    }
  ]
}
```

### Visual Representation (Exploded View)

```
Layer 3 (front): ┌─────────────────┐
                 │ Photo Title     │
                 └─────────────────┘
                        ↓
Layer 2:         ┌─────────────────┐
                 │ ░░░░░░░░░░░░░░░ │ ← Gradient
                 │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
                 └─────────────────┘
                        ↓
Layer 1 (back):  ┌─────────────────┐
                 │                 │
                 │     Image       │
                 │                 │
                 └─────────────────┘
```

---

## SectionLayout

A complex layout for heterogeneous sections, commonly used for feeds, settings screens, and collection views.

### JSON Schema

```json
{
  "type": "sectionLayout",
  "id": "optional-id",
  "sectionSpacing": 24,
  "sections": [ ... ]
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `"sectionLayout"` | - | Layout type identifier |
| `id` | `string` | - | Unique identifier |
| `sectionSpacing` | `number` | `0` | Space between sections |
| `sections` | `[SectionDefinition]` | `[]` | Array of section definitions |

### Section Definition

```json
{
  "id": "section-id",
  "layout": "horizontal" | "list" | "grid" | "flow",
  "header": { ... },
  "footer": { ... },
  "stickyHeader": false,
  "config": { ... },
  "children": [ ... ],
  "dataSource": "state.path",
  "itemTemplate": { ... }
}
```

### Section Types

#### Horizontal Section

Horizontally scrolling row of items.

```json
{
  "id": "featured",
  "layout": "horizontal",
  "header": {
    "type": "label",
    "label": "Featured",
    "styleId": "sectionHeader"
  },
  "config": {
    "itemSpacing": 12,
    "contentInsets": { "horizontal": 16 },
    "showsIndicators": false,
    "isPagingEnabled": false
  },
  "children": [
    { "type": "label", "label": "Item 1" },
    { "type": "label", "label": "Item 2" },
    { "type": "label", "label": "Item 3" }
  ]
}
```

#### List Section

Vertical list with optional dividers.

```json
{
  "id": "settings",
  "layout": "list",
  "config": {
    "itemSpacing": 0,
    "showsDividers": true,
    "contentInsets": { "horizontal": 16 }
  },
  "children": [
    { "type": "hstack", "children": [{ "type": "label", "label": "Option 1" }] },
    { "type": "hstack", "children": [{ "type": "label", "label": "Option 2" }] }
  ]
}
```

#### Grid Section

Grid layout with configurable columns.

```json
{
  "id": "gallery",
  "layout": "grid",
  "config": {
    "columns": 3,
    "itemSpacing": 8,
    "lineSpacing": 8,
    "contentInsets": { "horizontal": 16 }
  },
  "children": [
    { "type": "image", "data": { "type": "static", "value": "photo1" } },
    { "type": "image", "data": { "type": "static", "value": "photo2" } },
    { "type": "image", "data": { "type": "static", "value": "photo3" } }
  ]
}
```

**Adaptive Columns:**

```json
{
  "config": {
    "columns": { "adaptive": { "minWidth": 120 } }
  }
}
```

#### Flow Section

Wrapping layout where items flow to next line.

```json
{
  "id": "tags",
  "layout": "flow",
  "config": {
    "itemSpacing": 8,
    "lineSpacing": 8
  },
  "children": [
    { "type": "label", "label": "Tag 1" },
    { "type": "label", "label": "Tag 2" },
    { "type": "label", "label": "Longer Tag 3" }
  ]
}
```

### Section Config Properties

| Property | Type | Applies To | Description |
|----------|------|------------|-------------|
| `itemSpacing` | `number` | All | Space between items |
| `lineSpacing` | `number` | Grid, Flow | Space between rows |
| `contentInsets` | `Padding` | All | Padding around section content |
| `showsIndicators` | `boolean` | Horizontal | Show scroll indicators |
| `isPagingEnabled` | `boolean` | Horizontal | Enable paging behavior |
| `columns` | `number` or `object` | Grid | Column configuration |
| `showsDividers` | `boolean` | List | Show dividers between items |

### Data-Driven Sections

Sections can be populated from state data:

```json
{
  "state": {
    "products": [
      { "name": "Product 1", "price": "$10" },
      { "name": "Product 2", "price": "$20" }
    ]
  },
  "root": {
    "children": [
      {
        "type": "sectionLayout",
        "sections": [
          {
            "id": "products",
            "layout": "list",
            "dataSource": "products",
            "itemTemplate": {
              "type": "hstack",
              "children": [
                { "type": "label", "data": { "type": "binding", "path": "name" } },
                { "type": "spacer" },
                { "type": "label", "data": { "type": "binding", "path": "price" } }
              ]
            }
          }
        ]
      }
    ]
  }
}
```

### Complete Example

```json
{
  "type": "sectionLayout",
  "sectionSpacing": 24,
  "sections": [
    {
      "id": "horizontal-section",
      "layout": "horizontal",
      "header": {
        "type": "vstack",
        "alignment": "leading",
        "padding": { "horizontal": 16, "bottom": 8 },
        "children": [
          { "type": "label", "label": "Featured", "styleId": "sectionHeader" }
        ]
      },
      "config": {
        "itemSpacing": 12,
        "contentInsets": { "leading": 16, "trailing": 16 }
      },
      "children": [
        { "type": "label", "label": "Item 1" },
        { "type": "label", "label": "Item 2" }
      ]
    },
    {
      "id": "grid-section",
      "layout": "grid",
      "header": {
        "type": "label",
        "label": "Gallery",
        "styleId": "sectionHeader"
      },
      "config": {
        "columns": 2,
        "itemSpacing": 12,
        "lineSpacing": 12
      },
      "children": [
        { "type": "label", "label": "Grid 1" },
        { "type": "label", "label": "Grid 2" },
        { "type": "label", "label": "Grid 3" },
        { "type": "label", "label": "Grid 4" }
      ]
    }
  ]
}
```

---

## Padding

Padding can be applied to any layout.

### JSON Schema

```json
{
  "padding": {
    "top": 16,
    "bottom": 16,
    "leading": 20,
    "trailing": 20,
    "horizontal": 16,
    "vertical": 8
  }
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `top` | `number` | Top padding |
| `bottom` | `number` | Bottom padding |
| `leading` | `number` | Left padding (LTR) |
| `trailing` | `number` | Right padding (LTR) |
| `horizontal` | `number` | Left and right padding |
| `vertical` | `number` | Top and bottom padding |

### Resolution Priority

Specific values override general values:
- `top` overrides `vertical`
- `bottom` overrides `vertical`
- `leading` overrides `horizontal`
- `trailing` overrides `horizontal`

### Shorthand Examples

```json
// All sides equal
{ "padding": { "horizontal": 16, "vertical": 16 } }

// Only horizontal
{ "padding": { "horizontal": 16 } }

// Only top and bottom
{ "padding": { "top": 20, "bottom": 10 } }

// Mixed
{ "padding": { "horizontal": 16, "top": 20 } }
```

---

## IR Mapping

### Layout → ContainerNode

```swift
// AST (Document namespace)
Document.Layout(type: .vstack, alignment: .center, spacing: 8, children: [...])

// IR (RenderNode)
ContainerNode(
    layoutMode: .vstack,
    alignment: .center,
    spacing: 8,
    padding: .zero,  // NSDirectionalEdgeInsets
    children: [...]
)
```

### SectionLayout → SectionLayoutNode

```swift
// AST (Document namespace)
Document.SectionLayout(sectionSpacing: 24, sections: [Document.SectionDefinition(...)])

// IR (RenderNode)
SectionLayoutNode(
    id: "main-sections",
    sectionSpacing: 24,
    sections: [
        IR.Section(
            id: "featured",
            layoutType: .horizontal,
            header: TextNode(...),
            footer: nil,
            stickyHeader: false,
            config: IR.SectionConfig(...),
            children: [...]
        )
    ]
)
```

The `IR.Section` and `IR.SectionConfig` types live in the `IR` namespace and represent the fully resolved section configuration after style and data resolution.
