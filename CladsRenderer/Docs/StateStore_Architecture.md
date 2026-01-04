# StateStore Architecture

This document describes the internal architecture of the CLADS state management system, including `StateStore` and its sub-components.

## Overview

The state management system is composed of three main components:

```
┌─────────────────────────────────────────────────────────────────────┐
│                           StateStore                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    values: [String: Any]                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│         │                      │                      │              │
│         ▼                      ▼                      ▼              │
│  ┌─────────────┐      ┌─────────────────┐    ┌──────────────┐       │
│  │ KeypathAcc- │      │ ExpressionEval- │    │ Dirty        │       │
│  │ essor       │      │ uator           │    │ Tracking     │       │
│  │             │      │                 │    │              │       │
│  │ • Parsing   │      │ • Interpolation │    │ • dirtyPaths │       │
│  │ • Get/Set   │      │ • Ternary       │    │ • callbacks  │       │
│  │ • Indices   │      │ • Arithmetic    │    │              │       │
│  └─────────────┘      └─────────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

| Component | Responsibility |
|-----------|---------------|
| **StateStore** | Main facade - coordinates state storage, dirty tracking, and callbacks |
| **KeypathAccessor** | Parses keypaths and handles nested get/set operations |
| **ExpressionEvaluator** | Evaluates expressions and interpolates template strings |

---

## StateStore

The `StateStore` is the central coordinator for all state operations. It's an `ObservableObject` that works with SwiftUI and UIKit.

### Core Properties

```swift
@MainActor
public final class StateStore: ObservableObject, StateStoring {
    @Published private var values: [String: Any] = [:]      // Flat storage
    private var dirtyPaths: Set<String> = []                 // Changed paths
    private var changeCallbacks: [UUID: StateChangeCallback] = [:]  // Observers

    // Sub-components
    private let keypathAccessor = KeypathAccessor()
    private let expressionEvaluator = ExpressionEvaluator()
}
```

### Storage Model

StateStore uses a **flat dictionary** with **nested keypath access**:

```swift
// Internal storage (flat top-level keys)
values = [
    "count": 5,
    "user": [
        "name": "John",
        "profile": [
            "avatar": "photo.jpg"
        ]
    ],
    "items": ["apple", "banana", "cherry"]
]

// Access via keypaths
store.get("count")                    // 5
store.get("user.name")                // "John"
store.get("user.profile.avatar")      // "photo.jpg"
store.get("items[1]")                 // "banana"
store.get("items.2")                  // "cherry" (alternative syntax)
```

### StateStoring Protocol

For dependency injection and testing, `StateStore` conforms to `StateStoring`:

```swift
@MainActor
public protocol StateStoring: AnyObject, ObservableObject {
    // Reading
    func get(_ keypath: String) -> Any?
    func get<T>(_ keypath: String, as type: T.Type) -> T?
    func getArray(_ keypath: String) -> [Any]?
    func getArrayCount(_ keypath: String) -> Int
    func arrayContains(_ keypath: String, value: Any) -> Bool

    // Writing
    func set(_ keypath: String, value: Any?)
    func initialize(from state: [String: Document.StateValue]?)

    // Array Operations
    func appendToArray(_ keypath: String, value: Any)
    func removeFromArray(_ keypath: String, value: Any)
    func removeFromArray(_ keypath: String, at index: Int)
    func toggleInArray(_ keypath: String, value: Any)

    // Dirty Tracking
    var hasDirtyPaths: Bool { get }
    func consumeDirtyPaths() -> Set<String>
    func isDirty(_ path: String) -> Bool
    func clearDirtyPaths()

    // Callbacks
    func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID
    func removeStateChangeCallback(_ id: UUID)

    // Expression Evaluation
    func evaluate(expression: String) -> Any
    func interpolate(_ template: String) -> String

    // Bindings
    func binding(for keypath: String) -> Binding<String>
}
```

---

## KeypathAccessor

`KeypathAccessor` handles all path parsing and nested value access.

### Path Syntax

| Syntax | Example | Description |
|--------|---------|-------------|
| Simple key | `"count"` | Top-level value |
| Nested key | `"user.name"` | Dot-separated nesting |
| Bracket index | `"items[0]"` | Array index with brackets |
| Dot index | `"items.0"` | Array index with dot notation |
| Mixed | `"users[0].profile.name"` | Combined access patterns |

### Path Parsing

Paths are parsed into a sequence of components:

```swift
enum PathComponent: Equatable {
    case key(String)    // Dictionary key access
    case index(Int)     // Array index access
}

// Examples of parsing
"count"                → [.key("count")]
"user.name"            → [.key("user"), .key("name")]
"items[0]"             → [.key("items"), .index(0)]
"items.0"              → [.key("items"), .index(0)]
"users[0].profile.name"→ [.key("users"), .index(0), .key("profile"), .key("name")]
```

### Get Operation

The get operation traverses the path components:

```swift
public func get(_ keypath: String, from values: [String: Any]) -> Any? {
    let components = parseKeypath(keypath)
    var current: Any? = values

    for component in components {
        guard current != nil else { return nil }

        switch component {
        case .key(let key):
            // Access dictionary
            if let dict = current as? [String: Any] {
                current = dict[key]
            } else {
                return nil
            }
        case .index(let idx):
            // Access array
            if let array = current as? [Any], idx >= 0, idx < array.count {
                current = array[idx]
            } else {
                return nil
            }
        }
    }
    return current
}
```

### Set Operation

Setting nested values creates intermediate containers as needed:

```swift
// Setting "user.profile.name" to "Jane" on empty store
store.set("user.profile.name", value: "Jane")

// Results in:
values = [
    "user": [
        "profile": [
            "name": "Jane"
        ]
    ]
]
```

The set operation:
1. Parses the keypath into components
2. Recursively traverses/creates nested dictionaries or arrays
3. Sets the final value

```swift
// For arrays, intermediate slots are filled with NSNull()
store.set("items[2]", value: "cherry")

// If items was empty, results in:
values = [
    "items": [NSNull(), NSNull(), "cherry"]
]
```

### Parent Path Extraction

For dirty tracking, `KeypathAccessor` can extract parent paths:

```swift
accessor.parentPaths(of: "user.profile.name")
// Returns: ["user", "user.profile"]
```

---

## ExpressionEvaluator

`ExpressionEvaluator` handles dynamic expressions and template interpolation.

### StateValueReading Protocol

The evaluator works with any state source through this protocol:

```swift
public protocol StateValueReading {
    func getValue(_ keypath: String) -> Any?
    func getArray(_ keypath: String) -> [Any]?
    func arrayContains(_ keypath: String, value: Any) -> Bool
    func getArrayCount(_ keypath: String) -> Int
}
```

`StateStore` conforms to `StateValueReading`, allowing the evaluator to read state values.

### Template Interpolation

Templates use `${...}` syntax:

```swift
// Template: "Hello, ${user.name}! You have ${count} items."
// State: { "user": { "name": "John" }, "count": 5 }
// Result: "Hello, John! You have 5 items."

evaluator.interpolate("Hello, ${user.name}!", using: stateStore)
```

**Algorithm:**
1. Find all `${...}` patterns using regex
2. For each match, extract the expression
3. Evaluate the expression (may be a simple path or array expression)
4. Replace the placeholder with the string value
5. Process in reverse order to preserve string indices

### Ternary Expressions

```swift
// condition ? 'trueValue' : 'falseValue'
evaluator.evaluate("isLoggedIn ? 'Welcome!' : 'Please log in'", using: stateStore)
```

**Condition evaluation:**
- Boolean state values: `isLoggedIn`
- Array expressions: `items.contains("apple")`
- Negation: `!isLoggedIn`
- Literal: `"true"` or `"false"`

### Array Expressions

| Expression | Description | Example |
|------------|-------------|---------|
| `.count` | Array length | `items.count` → `3` |
| `.isEmpty` | Check if empty | `items.isEmpty` → `false` |
| `.first` | First element | `items.first` → `"apple"` |
| `.last` | Last element | `items.last` → `"cherry"` |
| `.contains("x")` | Contains literal | `items.contains("apple")` → `true` |
| `.contains(var)` | Contains variable | `items.contains(selectedItem)` → `true/false` |

### Arithmetic Expressions

Simple addition and subtraction:

```swift
// With state: { "count": 5 }
evaluator.evaluate("${count} + 1", using: stateStore)  // 6
evaluator.evaluate("${count} - 2", using: stateStore)  // 3
```

**Note:** Arithmetic operates on the interpolated result, so the expression must resolve to integer strings.

---

## Dirty Tracking

Dirty tracking enables efficient updates by recording which paths have changed.

### How It Works

```swift
// When a value is set:
store.set("user.profile.name", value: "Jane")

// dirtyPaths becomes:
Set(["user.profile.name", "user.profile", "user"])
```

**Parent propagation:** When a nested path changes, all parent paths are also marked dirty. This allows observers watching `"user"` to be notified when `"user.profile.name"` changes.

### Checking Dirty State

```swift
store.isDirty("user")                // true (self or children changed)
store.isDirty("user.profile.name")   // true (exact match)
store.isDirty("other")               // false
```

### Consuming Dirty Paths

The `consumeDirtyPaths()` method returns and clears the dirty set:

```swift
let changed = store.consumeDirtyPaths()
// changed = Set(["user.profile.name", "user.profile", "user"])
// dirtyPaths is now empty
```

This is used by `ViewTreeUpdater` to determine which views need re-rendering.

### Integration with ViewTree

```
┌─────────────┐        ┌──────────────────┐        ┌─────────────┐
│ StateStore  │───────▶│ ViewTreeUpdater  │───────▶│ ViewNode    │
│             │        │                  │        │ Tree        │
│ dirtyPaths  │        │ DependencyIndex  │        │             │
│ callbacks   │        │ maps paths to    │        │ Re-renders  │
│             │        │ affected nodes   │        │ affected    │
└─────────────┘        └──────────────────┘        └─────────────┘
```

1. `StateStore` notifies via callbacks when state changes
2. `ViewTreeUpdater` receives the callback and consumes dirty paths
3. `DependencyIndex` maps dirty paths to affected `ViewNode`s
4. Only affected nodes are re-rendered

---

## Change Callbacks

Callbacks provide a way to observe state changes:

```swift
// Register a callback
let callbackId = store.onStateChange { path, oldValue, newValue in
    print("Path '\(path)' changed from \(oldValue) to \(newValue)")
}

// Later, unregister
store.removeStateChangeCallback(callbackId)
```

### Callback Signature

```swift
public typealias StateChangeCallback = (
    _ path: String,     // The keypath that changed
    _ oldValue: Any?,   // Previous value (nil if new)
    _ newValue: Any?    // New value (nil if removed)
) -> Void
```

### Usage by ViewTreeUpdater

```swift
// In ViewTreeUpdater.attach(to:)
stateCallbackId = stateStore.onStateChange { [weak self] path, _, _ in
    self?.handleStateChange(at: path)
}

func handleStateChange(at path: String) {
    let dirtyPaths = stateStore.consumeDirtyPaths()
    let affectedNodes = dependencyIndex.nodesAffectedBy(dirtyPaths)
    for node in affectedNodes {
        node.markNeedsUpdate()
    }
}
```

---

## Typed State Access

For type-safe access to complex state structures:

```swift
struct UserProfile: Codable {
    let name: String
    let email: String
}

// Read typed value
if let profile: UserProfile = store.getTyped("user.profile") {
    print(profile.name)
}

// Write typed value
let newProfile = UserProfile(name: "Jane", email: "jane@example.com")
store.setTyped("user.profile", value: newProfile)
```

---

## Extending the State System

### Custom State Source

Create a custom state source by conforming to `StateValueReading`:

```swift
struct MockStateReader: StateValueReading {
    var values: [String: Any]

    func getValue(_ keypath: String) -> Any? {
        KeypathAccessor().get(keypath, from: values)
    }

    func getArray(_ keypath: String) -> [Any]? {
        getValue(keypath) as? [Any]
    }

    func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = getArray(keypath) else { return false }
        return array.contains { /* equality check */ }
    }

    func getArrayCount(_ keypath: String) -> Int {
        getArray(keypath)?.count ?? 0
    }
}

// Use with ExpressionEvaluator
let reader = MockStateReader(values: ["name": "Test"])
let result = ExpressionEvaluator().interpolate("Hello ${name}", using: reader)
```

### Custom Expression Functions

To add new expression functions (e.g., `.uppercase`, `.reversed`), extend `ExpressionEvaluator`:

```swift
extension ExpressionEvaluator {
    func evaluateCustomFunction(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // .uppercase
        if expression.hasSuffix(".uppercase") {
            let path = String(expression.dropLast(10))
            if let value = stateReader.getValue(path) as? String {
                return value.uppercased()
            }
        }

        // .lowercase
        if expression.hasSuffix(".lowercase") {
            let path = String(expression.dropLast(10))
            if let value = stateReader.getValue(path) as? String {
                return value.lowercased()
            }
        }

        return nil
    }
}
```

Then integrate into `evaluateArrayExpression` or create a new evaluation phase.

### Mock StateStore for Testing

```swift
@MainActor
class MockStateStore: StateStoring {
    var values: [String: Any] = [:]
    var setCallLog: [(path: String, value: Any?)] = []

    func get(_ keypath: String) -> Any? {
        KeypathAccessor().get(keypath, from: values)
    }

    func set(_ keypath: String, value: Any?) {
        setCallLog.append((keypath, value))
        KeypathAccessor().set(keypath, value: value, in: &values)
    }

    // ... implement other protocol requirements
}

// In tests
func testButtonIncrementsCounter() async {
    let mockStore = MockStateStore()
    mockStore.values = ["count": 0]

    // Trigger action that calls store.set("count", value: 1)

    XCTAssertEqual(mockStore.setCallLog.count, 1)
    XCTAssertEqual(mockStore.setCallLog[0].path, "count")
    XCTAssertEqual(mockStore.setCallLog[0].value as? Int, 1)
}
```

### Adding New Keypath Syntax

To add new path syntax (e.g., negative indices, wildcards), modify `KeypathAccessor.parseKeypath`:

```swift
// Add negative index support: items[-1] for last element
func parseKeypath(_ keypath: String) -> [PathComponent] {
    // ... existing parsing ...

    // Handle negative indices
    if let index = Int(indexStr), index < 0 {
        components.append(.negativeIndex(index))  // New case
    }
}

// Then handle in get/set:
case .negativeIndex(let offset):
    if let array = current as? [Any] {
        let actualIndex = array.count + offset
        if actualIndex >= 0, actualIndex < array.count {
            current = array[actualIndex]
        }
    }
```

---

## Thread Safety

`StateStore` is isolated to `@MainActor` to ensure thread safety:

```swift
@MainActor
public final class StateStore: ObservableObject { ... }
```

All state reads and writes must occur on the main thread. This is enforced by the Swift concurrency system.

---

## Performance Considerations

### Path Parsing

Path parsing happens on every get/set operation. For hot paths, consider:
- Caching parsed components for frequently-used paths
- Using direct dictionary access for simple top-level keys

### Dirty Tracking

Parent path propagation creates multiple entries per set operation. For deeply nested paths:
- `"a.b.c.d.e"` creates 5 dirty entries
- This is typically acceptable but can be optimized if needed

### Callback Notifications

All callbacks are invoked synchronously on every set. For high-frequency updates:
- Consider debouncing at the callback level
- Use `consumeDirtyPaths()` to batch process changes

---

## Summary

| Component | Key Methods | Purpose |
|-----------|-------------|---------|
| **StateStore** | `get()`, `set()`, `onStateChange()` | Central coordinator |
| **KeypathAccessor** | `parseKeypath()`, `get()`, `set()` | Path parsing & nested access |
| **ExpressionEvaluator** | `evaluate()`, `interpolate()` | Expressions & templates |
| **StateStoring** | Protocol | Dependency injection |
| **StateValueReading** | Protocol | Read-only state access |

The architecture provides:
- **Separation of concerns**: Each component has a single responsibility
- **Testability**: Protocols enable mocking and isolation
- **Extensibility**: New path syntax, expressions, or state sources can be added
- **Reactivity**: Dirty tracking and callbacks enable efficient UI updates
