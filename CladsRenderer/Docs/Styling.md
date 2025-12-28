# Styling

CLADS uses a style system with named styles, inheritance, and resolution. Styles are defined once and referenced by ID throughout the document.

## Style Definition

Styles are defined in the `styles` section of the document:

```json
{
  "styles": {
    "styleName": {
      "property": "value"
    }
  }
}
```

## Style Properties

### Text Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `fontSize` | `number` | Font size in points | `16` |
| `fontWeight` | `string` | Font weight | `"bold"` |
| `fontFamily` | `string` | Font family | `"system"` |
| `textColor` | `string` | Text color (hex) | `"#000000"` |
| `textAlignment` | `string` | Text alignment | `"center"` |

### Layout Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `width` | `number` | Fixed width in points | `100` |
| `height` | `number` | Fixed height in points | `50` |

### Appearance Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `backgroundColor` | `string` | Background color (hex) | `"#007AFF"` |
| `cornerRadius` | `number` | Corner radius in points | `12` |

### Inheritance

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `inherits` | `string` | Parent style to inherit from | `"baseStyle"` |

---

## Font Weight Values

| Value | Description |
|-------|-------------|
| `ultraLight` | Ultra light weight |
| `thin` | Thin weight |
| `light` | Light weight |
| `regular` | Regular weight (default) |
| `medium` | Medium weight |
| `semibold` | Semi-bold weight |
| `bold` | Bold weight |
| `heavy` | Heavy weight |
| `black` | Black weight |

---

## Text Alignment Values

| Value | Description |
|-------|-------------|
| `leading` | Left-aligned (LTR) |
| `center` | Center-aligned |
| `trailing` | Right-aligned (LTR) |

---

## Color Format

Colors use hexadecimal format:

| Format | Description | Example |
|--------|-------------|---------|
| `#RRGGBB` | RGB (opaque) | `#FF0000` (red) |
| `#AARRGGBB` | ARGB (with alpha) | `#80FF0000` (50% red) |

### Alpha Values

| Alpha | Opacity |
|-------|---------|
| `FF` | 100% (opaque) |
| `CC` | 80% |
| `99` | 60% |
| `66` | 40% |
| `33` | 20% |
| `00` | 0% (transparent) |

### Common Colors

```json
{
  "styles": {
    "colors": {
      "textColor": "#000000",       // Black
      "secondaryText": "#666666",   // Gray
      "primaryBlue": "#007AFF",     // iOS Blue
      "destructive": "#FF3B30",     // iOS Red
      "success": "#34C759",         // iOS Green
      "warning": "#FF9500",         // iOS Orange
      "background": "#FFFFFF",      // White
      "secondaryBg": "#F2F2F7"      // iOS Secondary Background
    }
  }
}
```

---

## Style Inheritance

Styles can inherit from other styles using the `inherits` property:

```json
{
  "styles": {
    "baseText": {
      "fontFamily": "system",
      "textColor": "#000000"
    },
    "titleStyle": {
      "inherits": "baseText",
      "fontSize": 24,
      "fontWeight": "bold"
    },
    "subtitleStyle": {
      "inherits": "baseText",
      "fontSize": 16,
      "fontWeight": "regular",
      "textColor": "#666666"
    }
  }
}
```

### Inheritance Rules

1. Child style properties override parent properties
2. Multiple levels of inheritance are supported
3. Circular inheritance is not allowed

### Resolution Example

```json
// Parent
"baseButton": {
  "cornerRadius": 12,
  "height": 50,
  "fontWeight": "semibold"
}

// Child
"primaryButton": {
  "inherits": "baseButton",
  "backgroundColor": "#007AFF",
  "textColor": "#FFFFFF"
}

// Resolved primaryButton
{
  "cornerRadius": 12,        // from baseButton
  "height": 50,              // from baseButton
  "fontWeight": "semibold",  // from baseButton
  "backgroundColor": "#007AFF",  // from primaryButton
  "textColor": "#FFFFFF"     // from primaryButton
}
```

---

## Component-Specific Styling

### Label Styles

```json
{
  "titleStyle": {
    "fontSize": 28,
    "fontWeight": "bold",
    "textColor": "#000000",
    "textAlignment": "center"
  }
}
```

### Button Styles

```json
{
  "primaryButton": {
    "backgroundColor": "#007AFF",
    "textColor": "#FFFFFF",
    "cornerRadius": 12,
    "height": 50,
    "fontSize": 17,
    "fontWeight": "semibold"
  },
  "secondaryButton": {
    "backgroundColor": "#E5E5EA",
    "textColor": "#000000",
    "cornerRadius": 12,
    "height": 50
  },
  "destructiveButton": {
    "backgroundColor": "#FF3B30",
    "textColor": "#FFFFFF",
    "cornerRadius": 12,
    "height": 50
  }
}
```

### Image Styles

```json
{
  "avatarImage": {
    "width": 60,
    "height": 60,
    "cornerRadius": 30
  },
  "heroImage": {
    "height": 300
  },
  "thumbnailImage": {
    "width": 80,
    "height": 80
  }
}
```

### Gradient Styles

```json
{
  "overlayGradient": {
    "height": 300
  }
}
```

---

## Applying Styles

Reference styles using the `styleId` property:

```json
{
  "type": "label",
  "label": "Hello World",
  "styleId": "titleStyle"
}
```

### Multiple Components, Same Style

```json
{
  "styles": {
    "listItemStyle": {
      "fontSize": 16,
      "textColor": "#000000"
    }
  },
  "root": {
    "children": [
      { "type": "label", "label": "Item 1", "styleId": "listItemStyle" },
      { "type": "label", "label": "Item 2", "styleId": "listItemStyle" },
      { "type": "label", "label": "Item 3", "styleId": "listItemStyle" }
    ]
  }
}
```

---

## Style Resolution

The `StyleResolver` handles style resolution during the Document → RenderTree transformation.

### Resolution Process

1. Look up the `Document.Style` by ID
2. If `inherits` is specified, recursively resolve parent
3. Merge parent properties with child properties
4. Child properties override parent properties
5. Return flattened `IR.Style`

### IR.Style Structure

```swift
public struct IR.Style {
    // Text
    public var fontSize: CGFloat?
    public var fontWeight: Font.Weight?
    public var fontFamily: String?
    public var textColor: Color?
    public var textAlignment: TextAlignment?

    // Layout
    public var width: CGFloat?
    public var height: CGFloat?

    // Appearance
    public var backgroundColor: Color?
    public var cornerRadius: CGFloat?
}
```

The `IR.Style` struct lives in the `IR` namespace and represents the fully resolved style after inheritance has been applied.

---

## Design System Example

A complete design system setup:

```json
{
  "styles": {
    // Base Styles
    "baseText": {
      "fontFamily": "system",
      "textColor": "#000000"
    },
    "baseButton": {
      "cornerRadius": 12,
      "height": 50,
      "fontWeight": "semibold",
      "fontSize": 17
    },

    // Typography
    "largeTitle": {
      "inherits": "baseText",
      "fontSize": 34,
      "fontWeight": "bold"
    },
    "title1": {
      "inherits": "baseText",
      "fontSize": 28,
      "fontWeight": "bold"
    },
    "title2": {
      "inherits": "baseText",
      "fontSize": 22,
      "fontWeight": "bold"
    },
    "headline": {
      "inherits": "baseText",
      "fontSize": 17,
      "fontWeight": "semibold"
    },
    "body": {
      "inherits": "baseText",
      "fontSize": 17,
      "fontWeight": "regular"
    },
    "callout": {
      "inherits": "baseText",
      "fontSize": 16,
      "fontWeight": "regular"
    },
    "caption": {
      "inherits": "baseText",
      "fontSize": 12,
      "fontWeight": "regular",
      "textColor": "#666666"
    },

    // Buttons
    "primaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF"
    },
    "secondaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#E5E5EA",
      "textColor": "#000000"
    },
    "tertiaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#00000000",
      "textColor": "#007AFF"
    },
    "destructiveButton": {
      "inherits": "baseButton",
      "backgroundColor": "#FF3B30",
      "textColor": "#FFFFFF"
    }
  }
}
```

---

## Best Practices

### 1. Use Inheritance

Create base styles and extend them:

```json
// Good
"baseButton": { "cornerRadius": 12, "height": 50 },
"primaryButton": { "inherits": "baseButton", "backgroundColor": "#007AFF" }

// Avoid
"primaryButton": { "cornerRadius": 12, "height": 50, "backgroundColor": "#007AFF" },
"secondaryButton": { "cornerRadius": 12, "height": 50, "backgroundColor": "#E5E5EA" }
```

### 2. Semantic Naming

Use descriptive names that indicate purpose:

```json
// Good
"sectionHeader", "primaryButton", "errorText"

// Avoid
"style1", "bigBlue", "myStyle"
```

### 3. Organize by Category

Group related styles:

```json
{
  "styles": {
    // Typography
    "title": { ... },
    "body": { ... },
    "caption": { ... },

    // Buttons
    "primaryButton": { ... },
    "secondaryButton": { ... },

    // Images
    "avatarImage": { ... },
    "thumbnailImage": { ... }
  }
}
```

### 4. Use Consistent Values

Define and reuse common values:

```json
{
  "styles": {
    "spacing8": { /* reference for spacing: 8 */ },
    "spacing16": { /* reference for spacing: 16 */ },
    "cornerRadiusSmall": { "cornerRadius": 8 },
    "cornerRadiusMedium": { "cornerRadius": 12 },
    "cornerRadiusLarge": { "cornerRadius": 16 }
  }
}
```
