# State Management

CLADS includes a reactive state management system that enables dynamic UIs with data binding and state updates.

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                      StateStore                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  @Published state: [String: Any]                │    │
│  └─────────────────────────────────────────────────┘    │
│                         │                                │
│         ┌───────────────┼───────────────┐               │
│         ▼               ▼               ▼               │
│    ┌─────────┐    ┌─────────┐    ┌─────────────┐       │
│    │  get()  │    │  set()  │    │ interpolate │       │
│    └─────────┘    └─────────┘    └─────────────┘       │
└─────────────────────────────────────────────────────────┘
         │                 ▲               │
         │                 │               │
         ▼                 │               ▼
   ┌──────────┐      ┌──────────┐    ┌──────────────┐
   │   Read   │      │  Write   │    │  Templates   │
   │  Binding │      │  Action  │    │  ${variable} │
   └──────────┘      └──────────┘    └──────────────┘
```

## Initial State

State is initialized in the `state` section of the document:

```json
{
  "state": {
    "count": 0,
    "username": "",
    "isLoggedIn": false,
    "items": ["apple", "banana", "cherry"]
  }
}
```

### Supported Types

| Type | JSON Example | Swift Type |
|------|--------------|------------|
| Number | `0`, `3.14` | `Int`, `Double` |
| String | `"hello"` | `String` |
| Boolean | `true`, `false` | `Bool` |
| Array | `[1, 2, 3]` | `[Any]` |
| Object | `{"key": "value"}` | `[String: Any]` |
| Null | `null` | `nil` |

---

## StateStore

The `StateStore` is an observable object that holds the document's state:

```swift
@MainActor
public class StateStore: ObservableObject {
    @Published private var state: [String: Any] = [:]

    public func get(_ path: String) -> Any?
    public func set(_ path: String, value: Any)
    public func interpolate(_ template: String) -> String
}
```

### Key Features

- **Observable**: Uses `@Published` for SwiftUI reactivity
- **Path-based Access**: Dot notation for nested values
- **Template Interpolation**: `${path}` syntax for dynamic strings
- **Main Actor Isolation**: Thread-safe state updates

---

## Reading State

### Data Sources

Define named data sources that reference state:

```json
{
  "state": {
    "user": {
      "name": "John",
      "email": "john@example.com"
    }
  },
  "dataSources": {
    "userName": {
      "type": "binding",
      "path": "user.name"
    },
    "greeting": {
      "type": "binding",
      "template": "Hello, ${user.name}!"
    }
  }
}
```

### Data Source Types

#### Static

Fixed value that doesn't change:

```json
{
  "welcomeMessage": {
    "type": "static",
    "value": "Welcome to our app!"
  }
}
```

#### Binding

Dynamic value from state:

```json
{
  "userName": {
    "type": "binding",
    "path": "user.name"
  }
}
```

#### Template Binding

String with interpolated values:

```json
{
  "greeting": {
    "type": "binding",
    "template": "Hello, ${user.name}! You have ${notifications.count} notifications."
  }
}
```

### Inline Data References

Components can reference state directly:

```json
{
  "type": "label",
  "data": {
    "type": "binding",
    "path": "user.name"
  }
}
```

---

## Writing State

### SetState Action

Update state values using the `setState` action:

```json
{
  "updateName": {
    "type": "setState",
    "path": "user.name",
    "value": "Jane"
  }
}
```

### Expression Values

Use expressions for dynamic updates:

```json
{
  "increment": {
    "type": "setState",
    "path": "count",
    "value": { "$expr": "${count} + 1" }
  }
}
```

### Supported Expressions

| Expression | Description | Example |
|------------|-------------|---------|
| `${path}` | State reference | `${count}` |
| `+ - * /` | Arithmetic | `${count} + 1` |
| String concat | String building | `${first} ${last}` |

---

## Two-Way Binding

TextFields support two-way binding with state:

```json
{
  "state": {
    "username": ""
  },
  "root": {
    "children": [
      {
        "type": "textfield",
        "placeholder": "Enter username",
        "bind": "username"
      },
      {
        "type": "label",
        "data": {
          "type": "binding",
          "template": "Username: ${username}"
        }
      }
    ]
  }
}
```

### Binding Flow

```
┌────────────────┐          ┌────────────────┐
│   TextField    │◀────────▶│   StateStore   │
└────────────────┘          └───────┬────────┘
                                    │
                                    ▼
                            ┌────────────────┐
                            │     Label      │
                            │ (observes)     │
                            └────────────────┘
```

1. User types in TextField
2. TextField updates StateStore via `bind` path
3. StateStore publishes change
4. Label observing state re-renders

---

## Path Notation

Access nested state using dot notation:

### Simple Path

```json
{
  "state": { "count": 0 }
}
// Path: "count"
```

### Nested Path

```json
{
  "state": {
    "user": {
      "profile": {
        "name": "John"
      }
    }
  }
}
// Path: "user.profile.name"
```

### Array Index (Future)

```json
{
  "state": {
    "items": ["a", "b", "c"]
  }
}
// Path: "items.0" → "a"
```

---

## Reactivity

### SwiftUI Integration

The `StateStore` is injected as an `@EnvironmentObject`:

```swift
struct TextFieldNodeView: View {
    @EnvironmentObject var stateStore: StateStore
    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .onAppear {
                text = stateStore.get(bindingPath) as? String ?? ""
            }
            .onChange(of: text) { newValue in
                stateStore.set(bindingPath, value: newValue)
            }
    }
}
```

### UIKit Integration

```swift
class BoundTextField: UITextField {
    private let stateStore: StateStore

    func setupBinding() {
        // Initial value
        text = stateStore.get(bindingPath) as? String

        // Update on edit
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc func textChanged() {
        stateStore.set(bindingPath, value: text ?? "")
    }
}
```

---

## Template Interpolation

Templates allow embedding state values in strings:

### Syntax

```
"Hello, ${path.to.value}!"
```

### Examples

```json
{
  "state": {
    "user": { "name": "John" },
    "count": 5
  }
}

// Template: "Hello, ${user.name}!"
// Result: "Hello, John!"

// Template: "You have ${count} items"
// Result: "You have 5 items"

// Template: "${user.name} has ${count} items"
// Result: "John has 5 items"
```

### Usage in Alerts

```json
{
  "showStatus": {
    "type": "showAlert",
    "title": "Status",
    "message": {
      "type": "binding",
      "template": "Current count: ${count}"
    }
  }
}
```

---

## Data-Driven Sections

Section layouts can be populated from state arrays:

```json
{
  "state": {
    "products": [
      { "name": "Product 1", "price": 10 },
      { "name": "Product 2", "price": 20 }
    ]
  },
  "root": {
    "children": [
      {
        "type": "sectionLayout",
        "sections": [
          {
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

---

## Complete Example

```json
{
  "id": "state-demo",
  "version": "1.0",

  "state": {
    "user": {
      "name": "",
      "email": ""
    },
    "formSubmitted": false,
    "submissionCount": 0
  },

  "styles": {
    "inputLabel": { "fontSize": 14, "textColor": "#666666" },
    "statusText": { "fontSize": 16, "fontWeight": "semibold" },
    "submitButton": {
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 50
    }
  },

  "dataSources": {
    "welcomeMessage": {
      "type": "binding",
      "template": "Welcome, ${user.name}!"
    },
    "submissionStatus": {
      "type": "binding",
      "template": "Submitted ${submissionCount} time(s)"
    }
  },

  "actions": {
    "submitForm": {
      "type": "sequence",
      "steps": [
        {
          "type": "setState",
          "path": "formSubmitted",
          "value": true
        },
        {
          "type": "setState",
          "path": "submissionCount",
          "value": { "$expr": "${submissionCount} + 1" }
        },
        {
          "type": "showAlert",
          "title": "Success",
          "message": {
            "type": "binding",
            "template": "Thank you, ${user.name}!"
          },
          "buttons": [{ "label": "OK", "style": "default" }]
        }
      ]
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 16,
        "padding": { "horizontal": 20, "top": 20 },
        "children": [
          { "type": "label", "label": "Name", "styleId": "inputLabel" },
          {
            "type": "textfield",
            "placeholder": "Enter your name",
            "bind": "user.name"
          },
          { "type": "label", "label": "Email", "styleId": "inputLabel" },
          {
            "type": "textfield",
            "placeholder": "Enter your email",
            "bind": "user.email"
          },
          {
            "type": "label",
            "dataSourceId": "welcomeMessage",
            "styleId": "statusText"
          },
          {
            "type": "label",
            "dataSourceId": "submissionStatus",
            "styleId": "statusText"
          },
          {
            "type": "button",
            "label": "Submit",
            "styleId": "submitButton",
            "fillWidth": true,
            "actions": { "onTap": "submitForm" }
          }
        ]
      }
    ]
  }
}
```

---

## Best Practices

### 1. Initialize All State

Define all state properties upfront:

```json
{
  "state": {
    "count": 0,
    "items": [],
    "user": null
  }
}
```

### 2. Use Meaningful Paths

Organize state logically:

```json
{
  "state": {
    "ui": {
      "isLoading": false,
      "selectedTab": 0
    },
    "data": {
      "products": [],
      "cart": []
    },
    "user": {
      "profile": {},
      "preferences": {}
    }
  }
}
```

### 3. Keep State Minimal

Only store what's needed for the UI:

```json
// Good - minimal state
{
  "state": {
    "searchQuery": "",
    "selectedId": null
  }
}

// Avoid - derived data in state
{
  "state": {
    "searchQuery": "",
    "filteredResults": [],  // Derive this instead
    "resultCount": 0        // Derive this instead
  }
}
```

### 4. Use Templates for Display

Use templates for formatted display:

```json
{
  "dataSources": {
    "priceDisplay": {
      "type": "binding",
      "template": "$${product.price}"
    }
  }
}
```
