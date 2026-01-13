# CLADS Android Port - Implementation Prompt

## Overview

You are tasked with implementing **CLADS** (Components, Layouts, Actions, Data, Styles) - a server-driven UI framework for Android. This framework allows native Android UIs to be defined in JSON and rendered without app updates.

CLADS uses an **LLVM-inspired multi-stage rendering pipeline**:

```
JSON → Document (AST) → Resolver → RenderTree (IR) → Renderer → Native UI
```

This architecture provides:
- **Clear separation of concerns** between parsing, resolution, and rendering
- **Multiple renderer support** (Jetpack Compose, traditional Views, debug output)
- **Type-safe resolution** of styles, data bindings, and actions at parse time
- **Reactive state management** with two-way binding

---

## Design Decisions (Already Made)

The following decisions have been made for this implementation:

| Decision | Choice |
|----------|--------|
| **Primary UI Framework** | Jetpack Compose (with optional View support) |
| **Language** | Idiomatic Kotlin (sealed classes, data classes, extension functions, coroutines) |
| **Serialization** | kotlinx.serialization |
| **State Management** | StateFlow / MutableStateFlow |
| **Image Loading** | Coil (Compose-native) |
| **Concurrency** | Kotlin Coroutines |
| **Min SDK** | API 24 (Android 7.0) |

---

## Part 1: Core Architecture

### 1.1 Pipeline Stages

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│    JSON     │ ──▶ │   Document   │ ──▶ │ RenderTree  │ ──▶ │   Renderer   │
│   (Input)   │     │    (AST)     │     │    (IR)     │     │   (Output)   │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                          │                     │                    │
                      Parsing              Resolution            Rendering
                    (Decoding)         (Style/Data/Action)    (Compose/View)
```

**Stage 1: JSON Input** - JSON document describing UI declaratively (from server, local file, or runtime)

**Stage 2: Document (AST)** - Parsed JSON into strongly-typed Kotlin data classes. All references (style IDs, action IDs, data sources) remain as strings.

**Stage 3: Resolver** - Transforms Document → RenderTree. Resolves all references:
- Style inheritance flattened
- Data bindings resolved against StateStore
- Actions validated and prepared

**Stage 4: RenderTree (IR)** - Fully resolved, renderer-agnostic tree. Ready for any renderer to consume.

**Stage 5: Renderer** - Transforms IR to platform UI (Compose `@Composable` or Android `View`)

### 1.2 Type Namespaces

Use Kotlin packages or sealed hierarchies to maintain clear separation:

| Layer | Kotlin Organization | Purpose |
|-------|---------------------|---------|
| **Document (AST)** | `com.clads.document.*` | Parsed JSON types |
| **IR** | `com.clads.ir.*` | Resolved types |
| **RenderNode** | `com.clads.ir.RenderNode` | Renderer-agnostic node types |
| **Renderer** | `com.clads.renderer.*` | Platform-specific rendering |

---

## Part 2: The 5 CLADS Components

### 2.1 Components (C)

UI leaf nodes that display content or capture input.

| Component | Description | Key Properties |
|-----------|-------------|----------------|
| `label` | Text display | `text`, `dataSourceId`, `styleId` |
| `button` | Tappable button | `text`, `styleId`, `fillWidth`, `actions.onTap` |
| `textfield` | Text input | `placeholder`, `bind`, `styleId` |
| `image` | Image display | `image.system` or `image.url`, `styleId` |
| `gradient` | Gradient overlay | `gradientColors`, `gradientStart`, `gradientEnd` |
| `toggle` | Switch/checkbox | `bind`, `styleId` |
| `slider` | Slider control | `bind`, `minValue`, `maxValue` |
| `divider` | Separator line | `styleId` |
| `spacer` | Flexible space | (none) |

### 2.2 Layouts (L)

Container nodes that arrange children.

| Layout | Description | Key Properties |
|--------|-------------|----------------|
| `vstack` | Vertical stack | `alignment`, `spacing`, `padding`, `children` |
| `hstack` | Horizontal stack | `alignment`, `spacing`, `padding`, `children` |
| `zstack` | Overlay stack | `alignment`, `padding`, `children` |
| `sectionLayout` | Section-based | `sections`, `sectionSpacing` |
| `forEach` | Iteration | `items`, `template`, `emptyView` |

**Compose Mappings:**
- `vstack` → `Column`
- `hstack` → `Row`
- `zstack` → `Box`
- `sectionLayout` → `LazyColumn` with heterogeneous sections

### 2.3 Actions (A)

Behaviors triggered by user interactions.

| Action | Description | Key Properties |
|--------|-------------|----------------|
| `dismiss` | Close current view | (none) |
| `setState` | Update state value | `path`, `value` (literal or `$expr`) |
| `toggleState` | Toggle boolean | `path` |
| `showAlert` | Display dialog | `title`, `message`, `buttons` |
| `navigate` | Navigate screens | `destination`, `presentation` |
| `sequence` | Chain actions | `steps` |
| Custom | Extensible | `type`, `...parameters` |

**Action Binding**: Actions can be referenced by ID or defined inline:
```json
"actions": { "onTap": "myActionId" }
"actions": { "onTap": { "type": "dismiss" } }
```

### 2.4 Data Sources (D)

Data binding and state management.

| Type | Description | Example |
|------|-------------|---------|
| `static` | Fixed value | `{ "type": "static", "value": "Hello" }` |
| `binding` | State reference | `{ "type": "binding", "path": "user.name" }` |
| Template | Interpolated | `{ "type": "binding", "template": "Hello, ${name}!" }` |

**StateStore** provides:
- Key-path access (`user.name`, `items[0].title`)
- Dirty tracking for efficient updates
- Template interpolation (`${variable}` syntax)
- Expression evaluation (`$expr` for `${count} + 1`)
- Two-way binding for text fields

### 2.5 Styles (S)

Visual styling with inheritance.

| Property | Type | Description |
|----------|------|-------------|
| `inherits` | `String` | Parent style ID |
| `fontSize` | `Number` | Font size in sp |
| `fontWeight` | `String` | ultraLight...black |
| `textColor` | `String` | Hex color (#RRGGBB or #AARRGGBB) |
| `backgroundColor` | `String` | Hex color |
| `cornerRadius` | `Number` | Corner radius in dp |
| `width`, `height` | `Number` | Fixed dimensions |
| `padding` | `Object` | top, bottom, leading, trailing, horizontal, vertical |

**Style Resolution**: Child properties override parent. Resolve inheritance chain and flatten.

---

## Part 3: JSON Schema

The JSON schema defines the contract between server and client. **This schema must be identical across iOS and Android.**

### 3.1 Document Structure

```json
{
  "id": "screen-id",
  "version": "1.0",
  "state": {
    "count": 0,
    "user": { "name": "John" }
  },
  "styles": {
    "title": { "fontSize": 24, "fontWeight": "bold" },
    "button": { "inherits": "baseButton", "backgroundColor": "#007AFF" }
  },
  "dataSources": {
    "greeting": { "type": "binding", "template": "Hello, ${user.name}!" }
  },
  "actions": {
    "increment": { "type": "setState", "path": "count", "value": { "$expr": "${count} + 1" } }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [...]
  }
}
```

### 3.2 Complete Example Document

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
      "fontWeight": "bold",
      "textColor": "#000000"
    },
    "primaryButton": {
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
        { "type": "setState", "path": "count", "value": 0 },
        {
          "type": "showAlert",
          "title": "Reset",
          "message": "Counter reset to zero",
          "buttons": [{ "label": "OK", "style": "default" }]
        }
      ]
    }
  },
  "dataSources": {
    "countDisplay": { "type": "binding", "path": "count" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 20,
        "alignment": "center",
        "padding": { "horizontal": 20 },
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
                "text": "-",
                "styleId": "primaryButton",
                "actions": { "onTap": "decrement" }
              },
              {
                "type": "button",
                "text": "+",
                "styleId": "primaryButton",
                "actions": { "onTap": "increment" }
              }
            ]
          },
          {
            "type": "button",
            "text": "Reset",
            "styleId": "primaryButton",
            "fillWidth": true,
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

## Part 4: Kotlin Type Definitions

### 4.1 Document Types (AST)

```kotlin
// Document.kt - Root definition
@Serializable
data class DocumentDefinition(
    val id: String,
    val version: String? = null,
    val state: Map<String, StateValue>? = null,
    val styles: Map<String, Style>? = null,
    val dataSources: Map<String, DataSource>? = null,
    val actions: Map<String, Action>? = null,
    val root: RootComponent
)

// StateValue.kt - Recursive JSON value type
@Serializable(with = StateValueSerializer::class)
sealed class StateValue {
    data class IntValue(val value: Int) : StateValue()
    data class DoubleValue(val value: Double) : StateValue()
    data class StringValue(val value: String) : StateValue()
    data class BoolValue(val value: Boolean) : StateValue()
    object NullValue : StateValue()
    data class ArrayValue(val value: List<StateValue>) : StateValue()
    data class ObjectValue(val value: Map<String, StateValue>) : StateValue()
}

// LayoutNode.kt - Union type for layout tree nodes
@Serializable(with = LayoutNodeSerializer::class)
sealed class LayoutNode {
    data class Layout(val layout: LayoutContainer) : LayoutNode()
    data class SectionLayout(val sectionLayout: SectionLayoutContainer) : LayoutNode()
    data class ForEach(val forEach: ForEachNode) : LayoutNode()
    data class Component(val component: ComponentNode) : LayoutNode()
    object Spacer : LayoutNode()
}

// Component.kt
@Serializable
data class ComponentNode(
    val type: String,
    val id: String? = null,
    val styleId: String? = null,
    val styles: ComponentStyles? = null,
    val text: String? = null,
    val placeholder: String? = null,
    val bind: String? = null,
    val fillWidth: Boolean? = null,
    val actions: ComponentActions? = null,
    val data: Map<String, DataReference>? = null,
    val image: ImageSource? = null,
    val gradientColors: List<GradientColorConfig>? = null,
    val gradientStart: String? = null,
    val gradientEnd: String? = null,
    val minValue: Double? = null,
    val maxValue: Double? = null
)

// Action.kt
@Serializable(with = ActionSerializer::class)
sealed class Action {
    object Dismiss : Action()
    data class SetState(val path: String, val value: SetValue) : Action()
    data class ToggleState(val path: String) : Action()
    data class ShowAlert(val title: String, val message: AlertMessage?, val buttons: List<AlertButton>?) : Action()
    data class Navigate(val destination: String, val presentation: NavigationPresentation?) : Action()
    data class Sequence(val steps: List<Action>) : Action()
    data class Custom(val type: String, val parameters: Map<String, StateValue>) : Action()
}

// Style.kt
@Serializable
data class Style(
    val inherits: String? = null,
    val fontFamily: String? = null,
    val fontSize: Float? = null,
    val fontWeight: FontWeight? = null,
    val textColor: String? = null,
    val textAlignment: TextAlignment? = null,
    val backgroundColor: String? = null,
    val cornerRadius: Float? = null,
    val borderWidth: Float? = null,
    val borderColor: String? = null,
    val tintColor: String? = null,
    val width: Float? = null,
    val height: Float? = null,
    val minWidth: Float? = null,
    val minHeight: Float? = null,
    val maxWidth: Float? = null,
    val maxHeight: Float? = null,
    val padding: Padding? = null
)

@Serializable
enum class FontWeight {
    @SerialName("ultraLight") ULTRA_LIGHT,
    @SerialName("thin") THIN,
    @SerialName("light") LIGHT,
    @SerialName("regular") REGULAR,
    @SerialName("medium") MEDIUM,
    @SerialName("semibold") SEMIBOLD,
    @SerialName("bold") BOLD,
    @SerialName("heavy") HEAVY,
    @SerialName("black") BLACK
}
```

### 4.2 IR Types (Resolved)

```kotlin
// IR.kt - Namespace for resolved types
object IR {
    // Fully resolved style with inheritance flattened
    data class Style(
        val fontFamily: String? = null,
        val fontSize: Float? = null,
        val fontWeight: androidx.compose.ui.text.font.FontWeight? = null,
        val textColor: androidx.compose.ui.graphics.Color? = null,
        val textAlignment: androidx.compose.ui.text.style.TextAlign? = null,
        val backgroundColor: androidx.compose.ui.graphics.Color? = null,
        val cornerRadius: Float? = null,
        val borderWidth: Float? = null,
        val borderColor: androidx.compose.ui.graphics.Color? = null,
        val tintColor: androidx.compose.ui.graphics.Color? = null,
        val width: Float? = null,
        val height: Float? = null,
        val minWidth: Float? = null,
        val minHeight: Float? = null,
        val maxWidth: Float? = null,
        val maxHeight: Float? = null,
        val paddingTop: Float? = null,
        val paddingBottom: Float? = null,
        val paddingStart: Float? = null,
        val paddingEnd: Float? = null
    )
    
    data class Section(
        val id: String?,
        val layoutType: SectionType,
        val header: RenderNode?,
        val footer: RenderNode?,
        val stickyHeader: Boolean,
        val config: SectionConfig,
        val children: List<RenderNode>
    )
    
    sealed class SectionType {
        object Horizontal : SectionType()
        object List : SectionType()
        data class Grid(val columns: ColumnConfig) : SectionType()
        object Flow : SectionType()
    }
}

// RenderTree.kt
data class RenderTree(
    val root: RootNode,
    val stateStore: StateStore,
    val actions: Map<String, ActionDefinition>
)

// RenderNode.kt - Renderer-agnostic node types
sealed class RenderNode {
    data class Container(val node: ContainerNode) : RenderNode()
    data class SectionLayout(val node: SectionLayoutNode) : RenderNode()
    data class Text(val node: TextNode) : RenderNode()
    data class Button(val node: ButtonNode) : RenderNode()
    data class TextField(val node: TextFieldNode) : RenderNode()
    data class Toggle(val node: ToggleNode) : RenderNode()
    data class Slider(val node: SliderNode) : RenderNode()
    data class Image(val node: ImageNode) : RenderNode()
    data class Gradient(val node: GradientNode) : RenderNode()
    object Spacer : RenderNode()
    data class Divider(val node: DividerNode) : RenderNode()
    data class Custom(val kind: String, val node: Any) : RenderNode()
}

data class TextNode(
    val id: String?,
    val content: String,
    val style: IR.Style,
    val bindingPath: String?,      // Dynamic content from state
    val bindingTemplate: String?   // Template with ${} placeholders
)

data class ButtonNode(
    val id: String?,
    val label: String,
    val styles: ButtonStyles,
    val isSelectedBinding: String?,
    val fillWidth: Boolean,
    val onTap: ActionBinding?
)

data class ContainerNode(
    val id: String?,
    val layoutType: LayoutType,  // VSTACK, HSTACK, ZSTACK
    val alignment: Alignment,
    val spacing: Float,
    val padding: PaddingValues,
    val style: IR.Style,
    val children: List<RenderNode>
)
```

### 4.3 StateStore

```kotlin
class StateStore {
    private val _state = MutableStateFlow<Map<String, Any?>>(emptyMap())
    val state: StateFlow<Map<String, Any?>> = _state.asStateFlow()
    
    private val dirtyPaths = mutableSetOf<String>()
    private val changeCallbacks = mutableMapOf<UUID, (String, Any?, Any?) -> Unit>()
    
    // Initialize from document state
    fun initialize(state: Map<String, StateValue>?) { ... }
    
    // Key-path access
    fun get(keyPath: String): Any? { ... }
    inline fun <reified T> get(keyPath: String): T? = get(keyPath) as? T
    
    // Writing
    fun set(keyPath: String, value: Any?) { ... }
    
    // Array operations
    fun appendToArray(keyPath: String, value: Any) { ... }
    fun removeFromArray(keyPath: String, value: Any) { ... }
    fun toggleInArray(keyPath: String, value: Any) { ... }
    
    // Dirty tracking
    fun consumeDirtyPaths(): Set<String> { ... }
    fun isDirty(path: String): Boolean { ... }
    
    // Template interpolation
    fun interpolate(template: String): String { ... }
    
    // Expression evaluation
    fun evaluate(expression: String): Any { ... }
    
    // Two-way binding for Compose
    @Composable
    fun stringBinding(keyPath: String): MutableState<String> { ... }
}
```

### 4.4 Resolver

```kotlin
class Resolver(
    private val document: DocumentDefinition,
    private val componentRegistry: ComponentResolverRegistry
) {
    private val styleResolver = StyleResolver(document.styles ?: emptyMap())
    private val actionResolver = ActionResolver()
    
    suspend fun resolve(stateStore: StateStore = StateStore()): RenderTree {
        stateStore.initialize(document.state)
        
        val context = ResolutionContext(
            document = document,
            stateStore = stateStore,
            styleResolver = styleResolver
        )
        
        val actions = actionResolver.resolveAll(document.actions ?: emptyMap())
        val rootNode = resolveRoot(document.root, context)
        
        return RenderTree(
            root = rootNode,
            stateStore = stateStore,
            actions = actions
        )
    }
    
    private fun resolveRoot(root: RootComponent, context: ResolutionContext): RootNode { ... }
    private fun resolveNode(node: LayoutNode, context: ResolutionContext): RenderNode { ... }
}

class StyleResolver(private val styles: Map<String, Style>) {
    private val cache = mutableMapOf<String, IR.Style>()
    
    fun resolve(styleId: String?): IR.Style {
        if (styleId == null) return IR.Style()
        return cache.getOrPut(styleId) { resolveWithInheritance(styleId) }
    }
    
    private fun resolveWithInheritance(styleId: String): IR.Style {
        val style = styles[styleId] ?: return IR.Style()
        val parent = style.inherits?.let { resolve(it) } ?: IR.Style()
        return parent.mergeWith(style)
    }
}
```

### 4.5 Renderer Protocol

```kotlin
interface Renderer<Output> {
    fun render(tree: RenderTree): Output
}

// Compose renderer returns a composable lambda
class ComposeRenderer : Renderer<@Composable () -> Unit> {
    override fun render(tree: RenderTree): @Composable () -> Unit = {
        CompositionLocalProvider(
            LocalStateStore provides tree.stateStore,
            LocalActionContext provides ActionContext(tree)
        ) {
            RenderRoot(tree.root)
        }
    }
}

// Debug renderer returns string representation
class DebugRenderer : Renderer<String> {
    override fun render(tree: RenderTree): String { ... }
}
```

---

## Part 5: Android-Specific Considerations

### 5.1 Compose Component Mapping

```kotlin
@Composable
fun RenderNode(node: RenderNode, modifier: Modifier = Modifier) {
    when (node) {
        is RenderNode.Container -> ContainerNodeView(node.node, modifier)
        is RenderNode.Text -> TextNodeView(node.node, modifier)
        is RenderNode.Button -> ButtonNodeView(node.node, modifier)
        is RenderNode.TextField -> TextFieldNodeView(node.node, modifier)
        is RenderNode.Image -> ImageNodeView(node.node, modifier)
        is RenderNode.Gradient -> GradientNodeView(node.node, modifier)
        is RenderNode.Toggle -> ToggleNodeView(node.node, modifier)
        is RenderNode.Slider -> SliderNodeView(node.node, modifier)
        RenderNode.Spacer -> Spacer(modifier.weight(1f))
        is RenderNode.Divider -> DividerNodeView(node.node, modifier)
        is RenderNode.Custom -> CustomNodeView(node, modifier)
        is RenderNode.SectionLayout -> SectionLayoutNodeView(node.node, modifier)
    }
}

@Composable
fun ContainerNodeView(node: ContainerNode, modifier: Modifier = Modifier) {
    val content: @Composable () -> Unit = {
        node.children.forEach { child ->
            RenderNode(child)
        }
    }
    
    when (node.layoutType) {
        LayoutType.VSTACK -> Column(
            modifier = modifier.applyStyle(node.style).padding(node.padding),
            horizontalAlignment = node.alignment.toHorizontalAlignment(),
            verticalArrangement = Arrangement.spacedBy(node.spacing.dp)
        ) { content() }
        
        LayoutType.HSTACK -> Row(
            modifier = modifier.applyStyle(node.style).padding(node.padding),
            verticalAlignment = node.alignment.toVerticalAlignment(),
            horizontalArrangement = Arrangement.spacedBy(node.spacing.dp)
        ) { content() }
        
        LayoutType.ZSTACK -> Box(
            modifier = modifier.applyStyle(node.style).padding(node.padding),
            contentAlignment = node.alignment.toBoxAlignment()
        ) { content() }
    }
}
```

### 5.2 Style Application

```kotlin
fun Modifier.applyStyle(style: IR.Style): Modifier = this
    .then(style.width?.let { width(it.dp) } ?: Modifier)
    .then(style.height?.let { height(it.dp) } ?: Modifier)
    .then(style.minWidth?.let { widthIn(min = it.dp) } ?: Modifier)
    .then(style.maxWidth?.let { widthIn(max = it.dp) } ?: Modifier)
    .then(style.backgroundColor?.let { background(it, RoundedCornerShape(style.cornerRadius?.dp ?: 0.dp)) } ?: Modifier)
    .then(style.cornerRadius?.let { clip(RoundedCornerShape(it.dp)) } ?: Modifier)
    .then(style.borderWidth?.let { border(it.dp, style.borderColor ?: Color.Black, RoundedCornerShape(style.cornerRadius?.dp ?: 0.dp)) } ?: Modifier)

fun IR.Style.toTextStyle(): TextStyle = TextStyle(
    fontSize = fontSize?.sp ?: TextStyle.Default.fontSize,
    fontWeight = fontWeight ?: FontWeight.Normal,
    color = textColor ?: Color.Unspecified,
    textAlign = textAlignment
)
```

### 5.3 Navigation Handling

```kotlin
sealed class NavigationEvent {
    data class Push(val destination: String) : NavigationEvent()
    data class Present(val destination: String) : NavigationEvent()
    data class FullScreen(val destination: String) : NavigationEvent()
    object Dismiss : NavigationEvent()
}

interface CladsNavigationHandler {
    fun handleNavigation(event: NavigationEvent)
}

// Integration with Navigation Component
class NavControllerHandler(
    private val navController: NavController
) : CladsNavigationHandler {
    override fun handleNavigation(event: NavigationEvent) {
        when (event) {
            is NavigationEvent.Push -> navController.navigate(event.destination)
            is NavigationEvent.Present -> { /* Show as bottom sheet or dialog */ }
            is NavigationEvent.FullScreen -> { /* Navigate with full screen transition */ }
            NavigationEvent.Dismiss -> navController.popBackStack()
        }
    }
}
```

### 5.4 Image Loading with Coil

```kotlin
@Composable
fun ImageNodeView(node: ImageNode, modifier: Modifier = Modifier) {
    val imageModifier = modifier.applyStyle(node.style)
    
    when (val source = node.source) {
        is ImageSource.System -> {
            // Map to Material Icons or custom icon set
            val icon = MaterialIconMapper.map(source.name)
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = imageModifier,
                tint = node.style.tintColor ?: LocalContentColor.current
            )
        }
        is ImageSource.Url -> {
            AsyncImage(
                model = source.url,
                contentDescription = null,
                modifier = imageModifier,
                contentScale = ContentScale.Fit
            )
        }
        is ImageSource.Asset -> {
            Image(
                painter = painterResource(id = getResourceId(source.name)),
                contentDescription = null,
                modifier = imageModifier
            )
        }
    }
}
```

### 5.5 Lifecycle Integration

```kotlin
@Composable
fun CladsRendererView(
    document: DocumentDefinition,
    navigationHandler: CladsNavigationHandler? = null,
    customActions: Map<String, ActionClosure> = emptyMap()
) {
    val viewModel: CladsViewModel = viewModel {
        CladsViewModel(document, customActions)
    }
    
    val renderTree by viewModel.renderTree.collectAsStateWithLifecycle()
    
    renderTree?.let { tree ->
        CompositionLocalProvider(
            LocalStateStore provides tree.stateStore,
            LocalNavigationHandler provides navigationHandler,
            LocalActionContext provides viewModel.actionContext
        ) {
            RenderRoot(tree.root)
        }
    }
}

class CladsViewModel(
    document: DocumentDefinition,
    customActions: Map<String, ActionClosure>
) : ViewModel() {
    private val resolver = Resolver(document, ComponentResolverRegistry.default)
    
    private val _renderTree = MutableStateFlow<RenderTree?>(null)
    val renderTree: StateFlow<RenderTree?> = _renderTree.asStateFlow()
    
    val actionContext: ActionContext
    
    init {
        viewModelScope.launch {
            val tree = resolver.resolve()
            _renderTree.value = tree
            actionContext = ActionContext(tree, customActions)
        }
    }
}
```

---

## Part 6: Extensibility

### 6.1 Custom Component Registration

```kotlin
interface ComponentResolver {
    val kind: String
    fun resolve(component: ComponentNode, context: ResolutionContext): RenderNode
}

interface ComposeNodeRenderer {
    val kind: String
    @Composable
    fun Render(node: RenderNode, modifier: Modifier)
}

class CladsRegistry {
    private val componentResolvers = mutableMapOf<String, ComponentResolver>()
    private val composeRenderers = mutableMapOf<String, ComposeNodeRenderer>()
    private val actionHandlers = mutableMapOf<String, ActionHandler>()
    
    fun registerComponent(
        resolver: ComponentResolver,
        renderer: ComposeNodeRenderer
    ) {
        componentResolvers[resolver.kind] = resolver
        composeRenderers[renderer.kind] = renderer
    }
    
    fun registerAction(handler: ActionHandler) {
        actionHandlers[handler.actionType] = handler
    }
}

// Plugin interface for bundling related components
interface CladsPlugin {
    fun register(registry: CladsRegistry)
}
```

### 6.2 Custom Component Example

```kotlin
// Define component kind
object ChartComponentKind {
    const val CHART = "chart"
}

// Custom render node
data class ChartNode(
    val id: String?,
    val chartType: String,
    val dataPoints: List<Double>,
    val style: IR.Style
)

// Resolver
class ChartResolver : ComponentResolver {
    override val kind = ChartComponentKind.CHART
    
    override fun resolve(component: ComponentNode, context: ResolutionContext): RenderNode {
        val dataPoints = component.additionalProperties?.get("dataPoints") as? List<*>
        val chartType = component.additionalProperties?.get("chartType") as? String
        
        return RenderNode.Custom(
            kind = ChartComponentKind.CHART,
            node = ChartNode(
                id = component.id,
                chartType = chartType ?: "line",
                dataPoints = dataPoints?.mapNotNull { (it as? Number)?.toDouble() } ?: emptyList(),
                style = context.styleResolver.resolve(component.styleId)
            )
        )
    }
}

// Compose renderer
class ChartComposeRenderer : ComposeNodeRenderer {
    override val kind = ChartComponentKind.CHART
    
    @Composable
    override fun Render(node: RenderNode, modifier: Modifier) {
        val chartNode = (node as RenderNode.Custom).node as ChartNode
        // Render chart using your charting library
        ChartView(
            type = chartNode.chartType,
            data = chartNode.dataPoints,
            modifier = modifier.applyStyle(chartNode.style)
        )
    }
}

// Register as plugin
class ChartingPlugin : CladsPlugin {
    override fun register(registry: CladsRegistry) {
        registry.registerComponent(
            resolver = ChartResolver(),
            renderer = ChartComposeRenderer()
        )
    }
}
```

---

## Part 7: Testing Requirements

### 7.1 Unit Tests

Implement unit tests for:
- JSON parsing for all document types
- Style resolution with inheritance
- StateStore operations (get, set, arrays, dirty tracking)
- Expression evaluation
- Template interpolation
- Action resolution

### 7.2 Example Test Cases

```kotlin
class StyleResolverTest {
    @Test
    fun `resolves style inheritance`() {
        val styles = mapOf(
            "base" to Style(fontSize = 16f, fontWeight = FontWeight.REGULAR),
            "title" to Style(inherits = "base", fontWeight = FontWeight.BOLD)
        )
        val resolver = StyleResolver(styles)
        
        val resolved = resolver.resolve("title")
        
        assertEquals(16f, resolved.fontSize)
        assertEquals(FontWeight.Bold, resolved.fontWeight)
    }
}

class StateStoreTest {
    @Test
    fun `supports nested key paths`() = runTest {
        val store = StateStore()
        store.set("user.name", "John")
        
        assertEquals("John", store.get<String>("user.name"))
    }
    
    @Test
    fun `interpolates templates`() = runTest {
        val store = StateStore()
        store.set("name", "World")
        
        assertEquals("Hello, World!", store.interpolate("Hello, \${name}!"))
    }
    
    @Test
    fun `evaluates expressions`() = runTest {
        val store = StateStore()
        store.set("count", 5)
        
        assertEquals(6, store.evaluate("\${count} + 1"))
    }
}
```

---

## Part 8: Error Handling

### 8.1 Error Types

```kotlin
sealed class CladsError : Exception() {
    data class ParseError(val json: String, override val cause: Throwable) : CladsError()
    data class UnknownStyle(val styleId: String) : CladsError()
    data class UnknownAction(val actionId: String) : CladsError()
    data class UnknownDataSource(val dataSourceId: String) : CladsError()
    data class InvalidExpression(val expression: String) : CladsError()
    data class InvalidKeyPath(val path: String) : CladsError()
}
```

### 8.2 Graceful Degradation

- Invalid JSON: Show error UI with message
- Missing style: Use default style, log warning
- Missing action: Log error, no-op on trigger
- Invalid binding path: Return null/default value
- Network image failure: Show placeholder

---

## Summary

Implement CLADS for Android following this architecture:

1. **Parse** JSON into `Document.*` types using kotlinx.serialization
2. **Resolve** Document → IR using `Resolver`, flattening styles and binding data
3. **Render** IR → Compose UI using `ComposeRenderer`
4. **Manage state** reactively with `StateStore` and StateFlow
5. **Handle actions** via `ActionContext` and extensible handlers
6. **Support extensibility** via `CladsRegistry` and plugins

The implementation should be idiomatic Kotlin, using sealed classes for union types, data classes for immutable structures, extension functions for utilities, and coroutines for async operations.
