# Actions

Actions define behaviors that execute in response to user interactions. CLADS provides a set of built-in action types that can be composed into complex workflows.

## Action Definition

Actions are defined in the `actions` section and referenced by ID:

```json
{
  "actions": {
    "actionId": {
      "type": "actionType",
      ...properties
    }
  }
}
```

## Triggering Actions

Actions are triggered from components using the `actions` property:

```json
{
  "type": "button",
  "label": "Tap Me",
  "actions": {
    "onTap": "actionId"
  }
}
```

---

## Action Types

| Type | Description |
|------|-------------|
| `dismiss` | Dismiss the current view |
| `setState` | Update a value in the state store |
| `showAlert` | Display an alert dialog |
| `sequence` | Execute multiple actions in order |
| `navigate` | Navigate to another screen |

---

## Dismiss

Dismisses the current view/sheet.

### JSON Schema

```json
{
  "dismissAction": {
    "type": "dismiss"
  }
}
```

### Example

```json
{
  "actions": {
    "closeSheet": {
      "type": "dismiss"
    }
  },
  "root": {
    "children": [
      {
        "type": "button",
        "label": "Close",
        "actions": { "onTap": "closeSheet" }
      }
    ]
  }
}
```

---

## SetState

Updates a value in the state store.

### JSON Schema

```json
{
  "setStateAction": {
    "type": "setState",
    "path": "state.path",
    "value": <value or expression>
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"setState"` | Yes | Action type |
| `path` | `string` | Yes | Dot-notation path to state property |
| `value` | `any` | Yes | New value or expression |

### Static Value

```json
{
  "setCountToZero": {
    "type": "setState",
    "path": "count",
    "value": 0
  }
}
```

### Expression Value

Use `$expr` for dynamic values:

```json
{
  "incrementCount": {
    "type": "setState",
    "path": "count",
    "value": { "$expr": "${count} + 1" }
  }
}
```

### Expression Syntax

- `${path}` - Reference a state value
- Basic arithmetic: `+`, `-`, `*`, `/`
- String interpolation: `"Hello ${name}"`

### Example: Counter

```json
{
  "state": {
    "count": 0
  },
  "actions": {
    "increment": {
      "type": "setState",
      "path": "count",
      "value": { "$expr": "${count} + 1" }
    },
    "decrement": {
      "type": "setState",
      "path": "count",
      "value": { "$expr": "${count} - 1" }
    },
    "reset": {
      "type": "setState",
      "path": "count",
      "value": 0
    }
  }
}
```

---

## ShowAlert

Displays an alert dialog with buttons.

### JSON Schema

```json
{
  "alertAction": {
    "type": "showAlert",
    "title": "Alert Title",
    "message": "Alert message" | { "type": "binding", "template": "..." },
    "buttons": [
      {
        "label": "Button Label",
        "style": "default" | "cancel" | "destructive",
        "action": "optionalActionId"
      }
    ]
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"showAlert"` | Yes | Action type |
| `title` | `string` | Yes | Alert title |
| `message` | `string` or `object` | No | Alert message (static or template) |
| `buttons` | `[AlertButton]` | No | Array of buttons |

### Button Styles

| Style | Description |
|-------|-------------|
| `default` | Standard button |
| `cancel` | Cancel button (bold on iOS) |
| `destructive` | Destructive action (red on iOS) |

### Static Message

```json
{
  "showError": {
    "type": "showAlert",
    "title": "Error",
    "message": "Something went wrong.",
    "buttons": [
      { "label": "OK", "style": "default" }
    ]
  }
}
```

### Dynamic Message

```json
{
  "showCount": {
    "type": "showAlert",
    "title": "Current Count",
    "message": {
      "type": "binding",
      "template": "The count is ${count}"
    },
    "buttons": [
      { "label": "OK", "style": "default" }
    ]
  }
}
```

### Alert with Actions

```json
{
  "confirmDelete": {
    "type": "showAlert",
    "title": "Delete Item?",
    "message": "This action cannot be undone.",
    "buttons": [
      { "label": "Cancel", "style": "cancel" },
      { "label": "Delete", "style": "destructive", "action": "performDelete" }
    ]
  },
  "performDelete": {
    "type": "dismiss"
  }
}
```

---

## Sequence

Executes multiple actions in order.

### JSON Schema

```json
{
  "sequenceAction": {
    "type": "sequence",
    "steps": [
      { ...action1 },
      { ...action2 },
      { ...action3 }
    ]
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"sequence"` | Yes | Action type |
| `steps` | `[Action]` | Yes | Array of actions to execute |

### Example: Increment and Show Alert

```json
{
  "incrementAndShow": {
    "type": "sequence",
    "steps": [
      {
        "type": "setState",
        "path": "count",
        "value": { "$expr": "${count} + 1" }
      },
      {
        "type": "showAlert",
        "title": "Updated",
        "message": {
          "type": "binding",
          "template": "Count is now ${count}"
        },
        "buttons": [{ "label": "OK", "style": "default" }]
      }
    ]
  }
}
```

### Example: Reset and Dismiss

```json
{
  "resetAndClose": {
    "type": "sequence",
    "steps": [
      {
        "type": "setState",
        "path": "formData",
        "value": {}
      },
      {
        "type": "dismiss"
      }
    ]
  }
}
```

---

## Navigate

Navigates to another screen or document.

### JSON Schema

```json
{
  "navigateAction": {
    "type": "navigate",
    "destination": "screen-id",
    "presentation": "push" | "sheet" | "fullScreen"
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"navigate"` | Yes | Action type |
| `destination` | `string` | Yes | Target screen/document ID |
| `presentation` | `string` | No | How to present (default: `"push"`) |

### Presentation Styles

| Style | Description |
|-------|-------------|
| `push` | Push onto navigation stack |
| `sheet` | Present as modal sheet |
| `fullScreen` | Present as full screen cover |

### Example

```json
{
  "goToSettings": {
    "type": "navigate",
    "destination": "settings",
    "presentation": "push"
  },
  "showDetails": {
    "type": "navigate",
    "destination": "item-details",
    "presentation": "sheet"
  }
}
```

---

## Action Context

The `ActionContext` manages action execution at runtime:

### Architecture

```
User Interaction
       │
       ▼
┌─────────────────┐
│  ActionContext  │
├─────────────────┤
│ - actions       │ ◄── From RenderTree
│ - stateStore    │
│ - actionRegistry│
│ - dismissAction │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ActionExecutor  │
├─────────────────┤
│ Dispatches to   │
│ appropriate     │
│ ActionHandler   │
└────────┬────────┘
         │
    ┌────┴────┬────────┬──────────┐
    ▼         ▼        ▼          ▼
┌───────┐ ┌───────┐ ┌───────┐ ┌────────┐
│Dismiss│ │SetState│ │Alert  │ │Sequence│
│Handler│ │Handler │ │Handler│ │Handler │
└───────┘ └───────┘ └───────┘ └────────┘
```

### Execution Flow

1. Component triggers action by ID
2. `ActionContext.executeAction(id:)` is called
3. `ActionExecutor` looks up action definition
4. Appropriate `ActionHandler` executes the action
5. State updates trigger UI refresh

---

## Complete Example

```json
{
  "id": "counter-demo",
  "version": "1.0",

  "state": {
    "count": 0
  },

  "styles": {
    "countLabel": {
      "fontSize": 48,
      "fontWeight": "bold"
    },
    "button": {
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 50
    }
  },

  "actions": {
    "increment": {
      "type": "setState",
      "path": "count",
      "value": { "$expr": "${count} + 1" }
    },
    "decrement": {
      "type": "setState",
      "path": "count",
      "value": { "$expr": "${count} - 1" }
    },
    "reset": {
      "type": "sequence",
      "steps": [
        {
          "type": "setState",
          "path": "count",
          "value": 0
        },
        {
          "type": "showAlert",
          "title": "Reset",
          "message": "Counter has been reset to zero.",
          "buttons": [{ "label": "OK", "style": "default" }]
        }
      ]
    }
  },

  "dataSources": {
    "countDisplay": {
      "type": "binding",
      "path": "count"
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 20,
        "alignment": "center",
        "children": [
          { "type": "spacer" },
          {
            "type": "label",
            "dataSourceId": "countDisplay",
            "styleId": "countLabel"
          },
          {
            "type": "hstack",
            "spacing": 12,
            "children": [
              {
                "type": "button",
                "label": "-",
                "styleId": "button",
                "actions": { "onTap": "decrement" }
              },
              {
                "type": "button",
                "label": "+",
                "styleId": "button",
                "actions": { "onTap": "increment" }
              }
            ]
          },
          {
            "type": "button",
            "label": "Reset",
            "styleId": "button",
            "actions": { "onTap": "reset" }
          },
          { "type": "spacer" }
        ]
      }
    ]
  }
}
```

---

## Custom Actions

The action system is extensible. To add a custom action:

### 1. Create an ActionHandler

```swift
struct MyCustomActionHandler: ActionHandler {
    func canHandle(_ action: Document.Action) -> Bool {
        if case .custom(let customAction) = action {
            return customAction.type == "myCustomAction"
        }
        return false
    }

    func execute(_ action: Document.Action, context: ActionContext) async {
        guard case .custom(let customAction) = action else { return }
        // Handle the custom action using customAction.parameters
    }
}
```

### 2. Register the Handler

```swift
actionRegistry.register(MyCustomActionHandler())
```

### 3. Use in JSON

```json
{
  "myAction": {
    "type": "myCustomAction",
    "customParam": "value"
  }
}
```
