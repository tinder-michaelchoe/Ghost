//
//  ComponentResolverTests.swift
//  CLADSTests
//
//  Unit tests for individual component resolvers (Text, Button, TextField, etc.).
//  Note: These tests use test implementations since the actual resolvers are in CladsModules.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Text Component Resolution Tests

struct TextComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicTextNode() throws {
        // Test that a label component can be resolved to a TextNode
        let component = Document.Component(
            type: Document.ComponentKind(rawValue: "label"),
            id: "testLabel",
            text: "Hello World"
        )
        
        let textNode = TextNode(
            id: component.id,
            content: component.text ?? "",
            style: IR.Style()
        )
        
        #expect(textNode.id == "testLabel")
        #expect(textNode.content == "Hello World")
    }
    
    @Test @MainActor func textNodeWithStyle() throws {
        var style = IR.Style()
        style.fontSize = 18
        style.fontWeight = .bold
        style.textColor = Color.red
        
        let textNode = TextNode(
            id: "styled",
            content: "Styled Text",
            style: style
        )
        
        #expect(textNode.style.fontSize == 18)
        #expect(textNode.style.fontWeight == .bold)
        #expect(textNode.style.textColor == Color.red)
    }
    
    @Test @MainActor func textNodeWithPadding() throws {
        let padding = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        
        let textNode = TextNode(
            id: "padded",
            content: "Padded Text",
            padding: padding
        )
        
        #expect(textNode.padding.top == 10)
        #expect(textNode.padding.leading == 20)
    }
    
    @Test @MainActor func textNodeWithBindingPath() throws {
        let textNode = TextNode(
            id: "dynamic",
            content: "Initial",
            bindingPath: "user.name"
        )
        
        #expect(textNode.bindingPath == "user.name")
        #expect(textNode.isDynamic == true)
    }
    
    @Test @MainActor func textNodeWithBindingTemplate() throws {
        let textNode = TextNode(
            id: "templated",
            content: "Hello John",
            bindingTemplate: "Hello ${name}"
        )
        
        #expect(textNode.bindingTemplate == "Hello ${name}")
        #expect(textNode.isDynamic == true)
    }
    
    @Test @MainActor func textNodeStaticIsNotDynamic() throws {
        let textNode = TextNode(
            id: "static",
            content: "Static Text"
        )
        
        #expect(textNode.isDynamic == false)
    }
}

// MARK: - Button Component Resolution Tests

struct ButtonComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicButtonNode() throws {
        let buttonNode = ButtonNode(
            id: "testButton",
            label: "Click Me"
        )
        
        #expect(buttonNode.id == "testButton")
        #expect(buttonNode.label == "Click Me")
    }
    
    @Test @MainActor func buttonNodeWithStyles() throws {
        var normalStyle = IR.Style()
        normalStyle.backgroundColor = Color.blue
        
        var selectedStyle = IR.Style()
        selectedStyle.backgroundColor = Color.green
        
        let styles = ButtonStyles(
            normal: normalStyle,
            selected: selectedStyle
        )
        
        let buttonNode = ButtonNode(
            id: "styled",
            label: "Styled Button",
            styles: styles
        )
        
        #expect(buttonNode.styles.normal.backgroundColor == Color.blue)
        #expect(buttonNode.styles.selected?.backgroundColor == Color.green)
    }
    
    @Test @MainActor func buttonStylesReturnCorrectStyleForState() throws {
        var normalStyle = IR.Style()
        normalStyle.backgroundColor = Color.blue
        
        var selectedStyle = IR.Style()
        selectedStyle.backgroundColor = Color.green
        
        var disabledStyle = IR.Style()
        disabledStyle.backgroundColor = Color.gray
        
        let styles = ButtonStyles(
            normal: normalStyle,
            selected: selectedStyle,
            disabled: disabledStyle
        )
        
        #expect(styles.style(isSelected: false, isDisabled: false).backgroundColor == Color.blue)
        #expect(styles.style(isSelected: true, isDisabled: false).backgroundColor == Color.green)
        #expect(styles.style(isSelected: false, isDisabled: true).backgroundColor == Color.gray)
    }
    
    @Test @MainActor func buttonNodeWithFillWidth() throws {
        let buttonNode = ButtonNode(
            id: "fill",
            label: "Full Width",
            fillWidth: true
        )
        
        #expect(buttonNode.fillWidth == true)
    }
    
    @Test @MainActor func buttonNodeWithSelectedBinding() throws {
        let buttonNode = ButtonNode(
            id: "toggle",
            label: "Toggle",
            isSelectedBinding: "${isActive}"
        )
        
        #expect(buttonNode.isSelectedBinding == "${isActive}")
    }
    
    @Test @MainActor func buttonNodeWithOnTapAction() throws {
        let action = Document.Component.ActionBinding.reference("submitForm")
        
        let buttonNode = ButtonNode(
            id: "submit",
            label: "Submit",
            onTap: action
        )
        
        #expect(buttonNode.onTap != nil)
    }
}

// MARK: - TextField Component Resolution Tests

struct TextFieldComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicTextFieldNode() throws {
        let textFieldNode = TextFieldNode(
            id: "testField",
            placeholder: "Enter text..."
        )
        
        #expect(textFieldNode.id == "testField")
        #expect(textFieldNode.placeholder == "Enter text...")
    }
    
    @Test @MainActor func textFieldNodeWithBindingPath() throws {
        let textFieldNode = TextFieldNode(
            id: "nameField",
            placeholder: "Name",
            bindingPath: "user.name"
        )
        
        #expect(textFieldNode.bindingPath == "user.name")
    }
    
    @Test @MainActor func textFieldNodeWithStyle() throws {
        var style = IR.Style()
        style.backgroundColor = Color.white
        style.cornerRadius = 8
        
        let textFieldNode = TextFieldNode(
            id: "styled",
            placeholder: "Styled",
            style: style
        )
        
        #expect(textFieldNode.style.cornerRadius == 8)
    }
    
    @Test @MainActor func textFieldNodeWithEmptyPlaceholder() throws {
        let textFieldNode = TextFieldNode(
            id: "empty"
        )
        
        #expect(textFieldNode.placeholder == "")
    }
}

// MARK: - Toggle Component Resolution Tests

struct ToggleComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicToggleNode() throws {
        let toggleNode = ToggleNode(
            id: "testToggle"
        )
        
        #expect(toggleNode.id == "testToggle")
    }
    
    @Test @MainActor func toggleNodeWithBindingPath() throws {
        let toggleNode = ToggleNode(
            id: "notificationsToggle",
            bindingPath: "settings.notifications"
        )
        
        #expect(toggleNode.bindingPath == "settings.notifications")
    }
    
    @Test @MainActor func toggleNodeWithTintStyle() throws {
        var style = IR.Style()
        style.tintColor = Color.green
        
        let toggleNode = ToggleNode(
            id: "tinted",
            style: style
        )
        
        #expect(toggleNode.style.tintColor == Color.green)
    }
}

// MARK: - Slider Component Resolution Tests

struct SliderComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicSliderNode() throws {
        let sliderNode = SliderNode(
            id: "testSlider"
        )
        
        #expect(sliderNode.id == "testSlider")
        #expect(sliderNode.minValue == 0.0)
        #expect(sliderNode.maxValue == 1.0)
    }
    
    @Test @MainActor func sliderNodeWithCustomRange() throws {
        let sliderNode = SliderNode(
            id: "volume",
            minValue: 0,
            maxValue: 100
        )
        
        #expect(sliderNode.minValue == 0)
        #expect(sliderNode.maxValue == 100)
    }
    
    @Test @MainActor func sliderNodeWithBindingPath() throws {
        let sliderNode = SliderNode(
            id: "brightnessSlider",
            bindingPath: "settings.brightness"
        )
        
        #expect(sliderNode.bindingPath == "settings.brightness")
    }
    
    @Test @MainActor func sliderNodeWithTintStyle() throws {
        var style = IR.Style()
        style.tintColor = Color.orange
        
        let sliderNode = SliderNode(
            id: "styled",
            style: style
        )
        
        #expect(sliderNode.style.tintColor == Color.orange)
    }
}

// MARK: - Image Component Resolution Tests

struct ImageComponentResolutionTests {
    
    @Test @MainActor func resolvesSystemImageNode() throws {
        let imageNode = ImageNode(
            id: "icon",
            source: .system(name: "star.fill")
        )
        
        #expect(imageNode.id == "icon")
        if case .system(let name) = imageNode.source {
            #expect(name == "star.fill")
        } else {
            Issue.record("Expected system image source")
        }
    }
    
    @Test @MainActor func resolvesAssetImageNode() throws {
        let imageNode = ImageNode(
            id: "logo",
            source: .asset(name: "AppLogo")
        )
        
        if case .asset(let name) = imageNode.source {
            #expect(name == "AppLogo")
        } else {
            Issue.record("Expected asset image source")
        }
    }
    
    @Test @MainActor func resolvesURLImageNode() throws {
        let url = URL(string: "https://example.com/image.png")!
        let imageNode = ImageNode(
            id: "remote",
            source: .url(url)
        )
        
        if case .url(let imageURL) = imageNode.source {
            #expect(imageURL.absoluteString == "https://example.com/image.png")
        } else {
            Issue.record("Expected URL image source")
        }
    }
    
    @Test @MainActor func imageNodeWithTintColor() throws {
        var style = IR.Style()
        style.tintColor = Color.red
        
        let imageNode = ImageNode(
            id: "tinted",
            source: .system(name: "heart"),
            style: style
        )
        
        #expect(imageNode.style.tintColor == Color.red)
    }
    
    @Test @MainActor func imageNodeWithSize() throws {
        var style = IR.Style()
        style.width = 48
        style.height = 48
        
        let imageNode = ImageNode(
            id: "sized",
            source: .system(name: "star"),
            style: style
        )
        
        #expect(imageNode.style.width == 48)
        #expect(imageNode.style.height == 48)
    }
    
    @Test @MainActor func imageNodeWithOnTapAction() throws {
        let action = Document.Component.ActionBinding.reference("openImage")
        
        let imageNode = ImageNode(
            id: "tappable",
            source: .system(name: "photo"),
            onTap: action
        )
        
        #expect(imageNode.onTap != nil)
    }
}

// MARK: - Gradient Component Resolution Tests

struct GradientComponentResolutionTests {
    
    @Test @MainActor func resolvesLinearGradientNode() throws {
        let gradientNode = GradientNode(
            id: "gradient",
            gradientType: .linear,
            colors: [
                GradientNode.ColorStop(color: .fixed(Color.red), location: 0),
                GradientNode.ColorStop(color: .fixed(Color.blue), location: 1)
            ]
        )
        
        #expect(gradientNode.id == "gradient")
        #expect(gradientNode.gradientType == .linear)
        #expect(gradientNode.colors.count == 2)
    }
    
    @Test @MainActor func resolvesRadialGradientNode() throws {
        let gradientNode = GradientNode(
            id: "radial",
            gradientType: .radial,
            colors: [
                GradientNode.ColorStop(color: .fixed(Color.white), location: 0),
                GradientNode.ColorStop(color: .fixed(Color.black), location: 1)
            ]
        )
        
        #expect(gradientNode.gradientType == .radial)
    }
    
    @Test @MainActor func gradientNodeWithStartEndPoints() throws {
        let gradientNode = GradientNode(
            id: "diagonal",
            colors: [
                GradientNode.ColorStop(color: .fixed(Color.red), location: 0),
                GradientNode.ColorStop(color: .fixed(Color.blue), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        #expect(gradientNode.startPoint == .topLeading)
        #expect(gradientNode.endPoint == .bottomTrailing)
    }
    
    @Test @MainActor func gradientNodeWithAdaptiveColors() throws {
        let gradientNode = GradientNode(
            id: "adaptive",
            colors: [
                GradientNode.ColorStop(
                    color: .adaptive(light: Color.white, dark: Color.black),
                    location: 0
                ),
                GradientNode.ColorStop(
                    color: .adaptive(light: Color.gray, dark: Color.gray),
                    location: 1
                )
            ]
        )
        
        if case .adaptive(let light, let dark) = gradientNode.colors[0].color {
            #expect(light == Color.white)
            #expect(dark == Color.black)
        } else {
            Issue.record("Expected adaptive color")
        }
    }
    
    @Test @MainActor func gradientColorResolvesForLightScheme() throws {
        let adaptiveColor = GradientColor.adaptive(light: Color.white, dark: Color.black)
        
        let resolved = adaptiveColor.resolved(for: .light, systemScheme: .light)
        #expect(resolved == Color.white)
    }
    
    @Test @MainActor func gradientColorResolvesForDarkScheme() throws {
        let adaptiveColor = GradientColor.adaptive(light: Color.white, dark: Color.black)
        
        let resolved = adaptiveColor.resolved(for: .dark, systemScheme: .light)
        #expect(resolved == Color.black)
    }
    
    @Test @MainActor func gradientColorResolvesForSystemScheme() throws {
        let adaptiveColor = GradientColor.adaptive(light: Color.white, dark: Color.black)
        
        let resolvedInDarkSystem = adaptiveColor.resolved(for: .system, systemScheme: .dark)
        #expect(resolvedInDarkSystem == Color.black)
        
        let resolvedInLightSystem = adaptiveColor.resolved(for: .system, systemScheme: .light)
        #expect(resolvedInLightSystem == Color.white)
    }
    
    @Test @MainActor func fixedGradientColorAlwaysResolvesSame() throws {
        let fixedColor = GradientColor.fixed(Color.red)
        
        #expect(fixedColor.resolved(for: .light, systemScheme: .light) == Color.red)
        #expect(fixedColor.resolved(for: .dark, systemScheme: .dark) == Color.red)
        #expect(fixedColor.resolved(for: .system, systemScheme: .light) == Color.red)
    }
}

// MARK: - Divider Component Resolution Tests

struct DividerComponentResolutionTests {
    
    @Test @MainActor func resolvesBasicDividerNode() throws {
        let dividerNode = DividerNode(
            id: "separator"
        )
        
        #expect(dividerNode.id == "separator")
    }
    
    @Test @MainActor func dividerNodeWithStyle() throws {
        var style = IR.Style()
        style.backgroundColor = Color.gray
        style.height = 1
        
        let dividerNode = DividerNode(
            id: "styled",
            style: style
        )
        
        #expect(dividerNode.style.backgroundColor == Color.gray)
        #expect(dividerNode.style.height == 1)
    }
}

// MARK: - Render Node Kind Tests

struct RenderNodeKindTests {
    
    @Test func builtInKindsHaveCorrectRawValues() {
        #expect(RenderNodeKind.container.rawValue == "container")
        #expect(RenderNodeKind.sectionLayout.rawValue == "sectionLayout")
        #expect(RenderNodeKind.text.rawValue == "text")
        #expect(RenderNodeKind.button.rawValue == "button")
        #expect(RenderNodeKind.textField.rawValue == "textField")
        #expect(RenderNodeKind.toggle.rawValue == "toggle")
        #expect(RenderNodeKind.slider.rawValue == "slider")
        #expect(RenderNodeKind.image.rawValue == "image")
        #expect(RenderNodeKind.gradient.rawValue == "gradient")
        #expect(RenderNodeKind.spacer.rawValue == "spacer")
        #expect(RenderNodeKind.divider.rawValue == "divider")
        #expect(RenderNodeKind.custom.rawValue == "custom")
    }
    
    @Test func renderNodeReturnsCorrectKind() {
        let textNode = RenderNode.text(TextNode(content: ""))
        #expect(textNode.kind == .text)
        
        let buttonNode = RenderNode.button(ButtonNode(label: ""))
        #expect(buttonNode.kind == .button)
        
        let spacer = RenderNode.spacer
        #expect(spacer.kind == .spacer)
    }
    
    @Test func customKindCanBeCreated() {
        let customKind = RenderNodeKind(rawValue: "myCustomWidget")
        #expect(customKind.rawValue == "myCustomWidget")
    }
}
