//
//  IRSchemaValidationTests.swift
//  CLADSTests
//
//  Tests that verify the resolved IR output conforms to the clads-ir-schema.json structure.
//  These tests ensure cross-platform compatibility by validating that resolution produces
//  output matching the expected schema structure.
//
//  Note: Full JSON schema validation requires Codable conformance on all IR types.
//  Until then, these tests validate structural requirements manually.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - RenderTree Schema Compliance Tests

/// Tests that RenderTree has all required top-level properties per schema:
/// - root: RootNode
/// - state: Dictionary of state values
/// - actions: Dictionary of ActionDefinition
struct RenderTreeSchemaTests {
    
    @Test @MainActor func renderTreeHasRequiredProperties() throws {
        let document = Document.Definition(
            id: "test",
            state: ["count": .intValue(0)],
            actions: ["dismiss": .dismiss],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema requires: root, state (via stateStore), actions
        // Verify root exists
        _ = renderTree.root
        
        // Verify state store has values
        #expect(renderTree.stateStore.get("count") != nil)
        
        // Verify actions dictionary exists with resolved actions
        #expect(renderTree.actions["dismiss"] != nil)
    }
    
    @Test @MainActor func renderTreeActionsAreResolved() throws {
        let document = Document.Definition(
            id: "test",
            actions: [
                "close": .dismiss,
                "toggle": .toggleState(Document.ToggleStateAction(path: "isOn")),
                "navigate": .navigate(Document.NavigateAction(destination: "settings", presentation: .push))
            ],
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Per schema, actions are ActionDefinition with type discriminator
        if case .dismiss = renderTree.actions["close"] {
            // matches schema: { "type": "dismiss" }
        } else {
            Issue.record("Expected dismiss action")
        }
        
        if case .toggleState(let path) = renderTree.actions["toggle"] {
            // matches schema: { "type": "toggleState", "path": "..." }
            #expect(path == "isOn")
        } else {
            Issue.record("Expected toggleState action")
        }
        
        if case .navigate(let dest, let pres) = renderTree.actions["navigate"] {
            // matches schema: { "type": "navigate", "destination": "...", "presentation": "..." }
            #expect(dest == "settings")
            #expect(pres == .push)
        } else {
            Issue.record("Expected navigate action")
        }
    }
}

// MARK: - RootNode Schema Compliance Tests

/// Tests that RootNode conforms to schema requirements:
/// - required: colorScheme, style, actions, children
/// - optional: backgroundColor, edgeInsets
struct RootNodeSchemaTests {
    
    @Test @MainActor func rootNodeHasRequiredColorScheme() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(colorScheme: "dark", children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: colorScheme is required, enum: ["light", "dark", "system"]
        #expect(renderTree.root.colorScheme == .dark)
    }
    
    @Test @MainActor func rootNodeColorSchemeDefaults() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: should default to "system"
        #expect(renderTree.root.colorScheme == .system)
    }
    
    @Test @MainActor func rootNodeHasChildrenArray() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [.spacer, .spacer])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: children is required array of renderNode
        #expect(renderTree.root.children.count == 2)
    }
    
    @Test @MainActor func rootNodeHasActionsObject() throws {
        let document = Document.Definition(
            id: "test",
            actions: ["onLoad": .dismiss],
            root: Document.RootComponent(
                actions: Document.RootActions(onAppear: .reference("onLoad")),
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: rootActions has optional onAppear/onDisappear
        #expect(renderTree.root.actions.action(for: .onAppear) != nil)
    }
    
    @Test @MainActor func rootNodeEdgeInsetsMatchSchema() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(
                edgeInsets: Document.EdgeInsets(
                    top: Document.EdgeInset(positioning: .safeArea, value: 10),
                    bottom: Document.EdgeInset(positioning: .absolute, value: 20)
                ),
                children: []
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: edgeInsets has positioning enum: ["safeArea", "absolute"]
        #expect(renderTree.root.edgeInsets?.top?.positioning == .safeArea)
        #expect(renderTree.root.edgeInsets?.top?.value == 10)
        #expect(renderTree.root.edgeInsets?.bottom?.positioning == .absolute)
        #expect(renderTree.root.edgeInsets?.bottom?.value == 20)
    }
}

// MARK: - RenderNode Schema Compliance Tests

/// Tests that RenderNode discriminated union matches schema oneOf structure
struct RenderNodeSchemaTests {
    
    @Test @MainActor func spacerNodeMatchesSchema() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(children: [.spacer])
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema: spacerNode = { nodeType: "spacer" }
        if case .spacer = renderTree.root.children[0] {
            // RenderNode.spacer maps to { "nodeType": "spacer" }
        } else {
            Issue.record("Expected spacer node")
        }
    }
    
    @Test @MainActor func containerNodeHasRequiredProperties() throws {
        let document = Document.Definition(
            id: "test",
            root: Document.RootComponent(
                children: [
                    .layout(Document.Layout(
                        type: .vstack,
                        horizontalAlignment: .leading,
                        spacing: 16,
                        padding: Document.Padding(top: 8, bottom: 8, leading: 8, trailing: 8),
                        children: [.spacer]
                    ))
                ]
            )
        )
        
        let registry = ComponentResolverRegistry()
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()
        
        // Schema containerNode requires:
        // nodeType: "container", layoutType, alignment, spacing, padding, style, children
        if case .container(let container) = renderTree.root.children[0] {
            // layoutType: enum ["vstack", "hstack", "zstack"]
            #expect(container.layoutType == .vstack)
            
            // spacing: number
            #expect(container.spacing == 16)
            
            // alignment: SwiftUI.Alignment (for VStack, this is horizontal alignment)
            #expect(container.alignment == .leading)
            
            // padding: directionalEdgeInsets { top, leading, bottom, trailing }
            #expect(container.padding.top == 8)
            #expect(container.padding.leading == 8)
            #expect(container.padding.bottom == 8)
            #expect(container.padding.trailing == 8)
            
            // children: array of renderNode
            #expect(container.children.count == 1)
        } else {
            Issue.record("Expected container node")
        }
    }
    
    @Test @MainActor func textNodeHasRequiredProperties() throws {
        // TextNode schema requires: nodeType, content, style, padding, isDynamic
        let textNode = TextNode(
            id: "label",
            content: "Hello",
            style: IR.Style(),
            padding: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        )
        
        // Schema: nodeType = "text"
        #expect(RenderNode.text(textNode).kind == .text)
        
        // Schema: content is string
        #expect(textNode.content == "Hello")
        
        // Schema: isDynamic is boolean
        #expect(textNode.isDynamic == false)
    }
    
    @Test @MainActor func textNodeWithBindingIsDynamic() throws {
        let textNode = TextNode(
            id: "dynamic",
            content: "Value",
            bindingPath: "state.value"
        )
        
        // Schema: bindingPath is optional string, isDynamic reflects this
        #expect(textNode.bindingPath == "state.value")
        #expect(textNode.isDynamic == true)
    }
    
    @Test @MainActor func buttonNodeHasRequiredProperties() throws {
        // Schema buttonNode requires: nodeType, label, styles, fillWidth
        var normalStyle = IR.Style()
        normalStyle.backgroundColor = Color.blue
        
        let buttonNode = ButtonNode(
            id: "btn",
            label: "Click",
            styles: ButtonStyles(normal: normalStyle),
            fillWidth: false
        )
        
        // Schema: nodeType = "button"
        #expect(RenderNode.button(buttonNode).kind == .button)
        
        // Schema: label is string
        #expect(buttonNode.label == "Click")
        
        // Schema: fillWidth is boolean
        #expect(buttonNode.fillWidth == false)
        
        // Schema: styles.normal is required
        #expect(buttonNode.styles.normal.backgroundColor == Color.blue)
    }
    
    @Test @MainActor func imageNodeSourceMatchesSchema() throws {
        // Schema imageSource oneOf: system, asset, url
        
        // System: { type: "system", name: string }
        let systemImage = ImageNode(
            id: "icon",
            source: .system(name: "star.fill")
        )
        if case .system(let name) = systemImage.source {
            #expect(name == "star.fill")
        } else {
            Issue.record("Expected system image")
        }
        
        // Asset: { type: "asset", name: string }
        let assetImage = ImageNode(
            id: "logo",
            source: .asset(name: "AppLogo")
        )
        if case .asset(let name) = assetImage.source {
            #expect(name == "AppLogo")
        } else {
            Issue.record("Expected asset image")
        }
        
        // URL: { type: "url", url: string (uri format) }
        let urlImage = ImageNode(
            id: "remote",
            source: .url(URL(string: "https://example.com/image.png")!)
        )
        if case .url(let url) = urlImage.source {
            #expect(url.absoluteString == "https://example.com/image.png")
        } else {
            Issue.record("Expected URL image")
        }
    }
    
    @Test @MainActor func sliderNodeHasMinMaxValues() throws {
        // Schema sliderNode requires: nodeType, minValue, maxValue, style
        let sliderNode = SliderNode(
            id: "slider",
            minValue: 0,
            maxValue: 100
        )
        
        #expect(RenderNode.slider(sliderNode).kind == .slider)
        #expect(sliderNode.minValue == 0)
        #expect(sliderNode.maxValue == 100)
    }
    
    @Test @MainActor func gradientNodeMatchesSchema() throws {
        // Schema gradientNode requires: nodeType, gradientType, colors, startPoint, endPoint, style
        let gradientNode = GradientNode(
            id: "gradient",
            gradientType: .linear,
            colors: [
                GradientNode.ColorStop(color: .fixed(Color.red), location: 0),
                GradientNode.ColorStop(color: .fixed(Color.blue), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        #expect(RenderNode.gradient(gradientNode).kind == .gradient)
        
        // Schema: gradientType enum ["linear", "radial"]
        #expect(gradientNode.gradientType == .linear)
        
        // Schema: colors array of colorStop { color, location }
        #expect(gradientNode.colors.count == 2)
        #expect(gradientNode.colors[0].location == 0)
        #expect(gradientNode.colors[1].location == 1)
        
        // Schema: startPoint/endPoint are unitPoint { x, y }
        #expect(gradientNode.startPoint == .top)
        #expect(gradientNode.endPoint == .bottom)
    }
}

// MARK: - SectionLayout Schema Compliance Tests

struct SectionLayoutSchemaTests {
    
    @Test @MainActor func sectionLayoutNodeHasRequiredProperties() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            id: "sections",
            sectionSpacing: 24,
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .horizontal),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        // Schema sectionLayoutNode requires: nodeType, sectionSpacing, sections
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.id == "sections")
            #expect(node.sectionSpacing == 24)
            #expect(node.sections.count == 1)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func sectionTypeMatchesSchemaOneOf() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        // Schema sectionType oneOf: horizontal, list, grid (with columns), flow
        
        // Horizontal: { type: "horizontal" }
        let horizontalLayout = Document.SectionLayout(
            sections: [Document.SectionDefinition(
                layout: Document.SectionLayoutConfig(type: .horizontal),
                children: []
            )]
        )
        let horizontalResult = try resolver.resolve(horizontalLayout, context: context)
        if case .sectionLayout(let node) = horizontalResult.renderNode {
            if case .horizontal = node.sections[0].layoutType {
                // Matches schema
            } else {
                Issue.record("Expected horizontal type")
            }
        }
        
        // Grid: { type: "grid", columns: { type: "fixed", count: N } }
        let gridLayout = Document.SectionLayout(
            sections: [Document.SectionDefinition(
                layout: Document.SectionLayoutConfig(type: .grid, columns: .fixed(3)),
                children: []
            )]
        )
        let gridResult = try resolver.resolve(gridLayout, context: context)
        if case .sectionLayout(let node) = gridResult.renderNode {
            if case .grid(let columns) = node.sections[0].layoutType {
                if case .fixed(let count) = columns {
                    #expect(count == 3)
                } else {
                    Issue.record("Expected fixed columns")
                }
            } else {
                Issue.record("Expected grid type")
            }
        }
    }
    
    @Test @MainActor func sectionConfigMatchesSchema() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        // Schema sectionConfig requires: alignment, itemSpacing, lineSpacing,
        // contentInsets, showsIndicators, isPagingEnabled, snapBehavior, showsDividers
        
        let sectionLayout = Document.SectionLayout(
            sections: [Document.SectionDefinition(
                layout: Document.SectionLayoutConfig(
                    type: .list,
                    alignment: .center,
                    itemSpacing: 12,
                    lineSpacing: 16,
                    contentInsets: Document.Padding(top: 8, bottom: 8, leading: 8, trailing: 8),
                    showsIndicators: true,
                    snapBehavior: .viewAligned,
                    showsDividers: false
                ),
                children: []
            )]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            let config = node.sections[0].config
            
            // Schema: alignment enum ["leading", "center", "trailing"]
            #expect(config.alignment == .center)
            
            // Schema: itemSpacing number
            #expect(config.itemSpacing == 12)
            
            // Schema: lineSpacing number
            #expect(config.lineSpacing == 16)
            
            // Schema: contentInsets directionalEdgeInsets
            #expect(config.contentInsets.top == 8)
            #expect(config.contentInsets.leading == 8)
            
            // Schema: showsIndicators boolean
            #expect(config.showsIndicators == true)
            
            // Schema: showsDividers boolean
            #expect(config.showsDividers == false)
            
            // Schema: snapBehavior enum ["none", "viewAligned", "paging"]
            #expect(config.snapBehavior == .viewAligned)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - ActionDefinition Schema Compliance Tests

struct ActionDefinitionSchemaTests {
    
    @Test func dismissActionMatchesSchema() {
        // Schema: { type: "dismiss" }
        let resolver = ActionResolver()
        let action = resolver.resolve(.dismiss)
        
        if case .dismiss = action {
            // Matches schema
        } else {
            Issue.record("Expected dismiss action")
        }
    }
    
    @Test func setStateActionMatchesSchema() {
        // Schema: { type: "setState", path: string, value: stateSetValue }
        let resolver = ActionResolver()
        let action = resolver.resolve(.setState(Document.SetStateAction(
            path: "user.name",
            value: .literal(.stringValue("John"))
        )))
        
        if case .setState(let path, let value) = action {
            #expect(path == "user.name")
            if case .literal(let stateValue) = value {
                #expect(stateValue == .stringValue("John"))
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
    
    @Test func navigateActionMatchesSchema() {
        // Schema: { type: "navigate", destination: string, presentation: enum }
        let resolver = ActionResolver()
        let action = resolver.resolve(.navigate(Document.NavigateAction(
            destination: "profile",
            presentation: .fullScreen
        )))
        
        if case .navigate(let dest, let pres) = action {
            #expect(dest == "profile")
            // Schema: presentation enum ["push", "present", "fullScreen"]
            #expect(pres == .fullScreen)
        } else {
            Issue.record("Expected navigate action")
        }
    }
    
    @Test func sequenceActionMatchesSchema() {
        // Schema: { type: "sequence", steps: [actionDefinition] }
        let resolver = ActionResolver()
        let action = resolver.resolve(.sequence(Document.SequenceAction(
            steps: [.dismiss, .dismiss]
        )))
        
        if case .sequence(let steps) = action {
            #expect(steps.count == 2)
        } else {
            Issue.record("Expected sequence action")
        }
    }
    
    @Test func showAlertActionMatchesSchema() {
        // Schema: { type: "showAlert", config: alertConfig }
        // alertConfig: { title, message?, buttons }
        let resolver = ActionResolver()
        let action = resolver.resolve(.showAlert(Document.ShowAlertAction(
            title: "Confirm",
            message: .static("Are you sure?"),
            buttons: [
                Document.AlertButton(label: "Yes", style: .default, action: "confirm"),
                Document.AlertButton(label: "No", style: .cancel)
            ]
        )))
        
        if case .showAlert(let config) = action {
            #expect(config.title == "Confirm")
            
            // Schema: message oneOf [{ type: "static", value }, { type: "template", value }]
            if case .static(let msg) = config.message {
                #expect(msg == "Are you sure?")
            }
            
            // Schema: buttons array of alertButton { label, style, action? }
            #expect(config.buttons.count == 2)
            #expect(config.buttons[0].label == "Yes")
            #expect(config.buttons[0].style == .default)
            #expect(config.buttons[0].action == "confirm")
            #expect(config.buttons[1].style == .cancel)
        } else {
            Issue.record("Expected showAlert action")
        }
    }
    
    @Test func customActionMatchesSchema() {
        // Schema: { type: string (not reserved), parameters?: object }
        let resolver = ActionResolver()
        let action = resolver.resolve(.custom(Document.CustomAction(
            type: "analytics.track",
            parameters: [
                "event": .stringValue("button_tap"),
                "count": .intValue(1)
            ]
        )))
        
        if case .custom(let type, let params) = action {
            #expect(type == "analytics.track")
            #expect(params["event"] == .stringValue("button_tap"))
            #expect(params["count"] == .intValue(1))
        } else {
            Issue.record("Expected custom action")
        }
    }
}

// MARK: - Style Schema Compliance Tests

struct StyleSchemaTests {
    
    @Test func stylePropertiesMatchSchema() {
        // Schema style has optional properties:
        // fontFamily, fontSize, fontWeight, textColor, textAlignment,
        // backgroundColor, cornerRadius, borderWidth, borderColor, tintColor,
        // width, height, minWidth, minHeight, maxWidth, maxHeight,
        // paddingTop, paddingBottom, paddingLeading, paddingTrailing
        
        var style = IR.Style()
        style.fontSize = 16
        style.fontWeight = .bold
        style.textColor = Color.black
        style.backgroundColor = Color.white
        style.cornerRadius = 8
        style.borderWidth = 1
        style.borderColor = Color.gray
        style.tintColor = Color.blue
        style.width = 100
        style.height = 50
        
        // All properties should be set
        #expect(style.fontSize == 16)
        #expect(style.fontWeight == .bold)
        #expect(style.cornerRadius == 8)
        #expect(style.borderWidth == 1)
        #expect(style.width == 100)
        #expect(style.height == 50)
    }
    
    @Test func fontWeightMatchesSchemaEnum() {
        // Schema: fontWeight enum ["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"]
        let allWeights: [Font.Weight] = [
            .ultraLight, .thin, .light, .regular, .medium,
            .semibold, .bold, .heavy, .black
        ]
        
        for weight in allWeights {
            var style = IR.Style()
            style.fontWeight = weight
            #expect(style.fontWeight == weight)
        }
    }
}

// MARK: - Cross-Platform Serialization Tests (Infrastructure)

/// Tests for JSON serialization - requires Codable conformance on IR types.
/// These tests document the expected serialization format for cross-platform use.
struct IRSerializationTests {
    
    @Test func actionDefinitionIsEncodable() throws {
        // ActionDefinition is already Codable
        let action = ActionDefinition.dismiss
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(action)
        let json = String(data: data, encoding: .utf8)!
        
        // Should produce: { "type": "dismiss" } per schema
        #expect(json.contains("dismiss"))
    }
    
    @Test func stateSetValueIsEncodable() throws {
        // StateSetValue is already Codable
        let value = StateSetValue.literal(.stringValue("test"))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("test"))
    }
    
    @Test func alertConfigIsEncodable() throws {
        let config = AlertActionConfig(
            title: "Test",
            message: .static("Message"),
            buttons: [AlertButtonConfig(label: "OK", style: .default)]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("Test"))
        #expect(json.contains("Message"))
        #expect(json.contains("OK"))
    }
    
    // TODO: Add tests for RenderTree, RootNode, RenderNode once Codable conformance is added
    // These would validate the full IR output against the JSON schema
}
