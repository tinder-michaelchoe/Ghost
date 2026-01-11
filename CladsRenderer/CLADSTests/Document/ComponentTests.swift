//
//  ComponentTests.swift
//  CLADSTests
//
//  Unit tests for Document.Component JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Basic Properties Tests

struct ComponentBasicPropertiesTests {
    
    @Test func decodesTypeProperty() throws {
        let json = """
        { "type": "label" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.type.rawValue == "label")
    }
    
    @Test func decodesIdProperty() throws {
        let json = """
        { "type": "label", "id": "myLabel" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.id == "myLabel")
    }
    
    @Test func decodesStyleIdProperty() throws {
        let json = """
        { "type": "label", "styleId": "titleStyle" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.styleId == "titleStyle")
    }
    
    @Test func decodesTextProperty() throws {
        let json = """
        { "type": "label", "text": "Hello World" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.text == "Hello World")
    }
    
    @Test func decodesPlaceholderProperty() throws {
        let json = """
        { "type": "textfield", "placeholder": "Enter name..." }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.placeholder == "Enter name...")
    }
    
    @Test func decodesDataSourceIdProperty() throws {
        let json = """
        { "type": "label", "dataSourceId": "welcomeText" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.dataSourceId == "welcomeText")
    }
    
    @Test func decodesFillWidthProperty() throws {
        let json = """
        { "type": "button", "fillWidth": true }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.fillWidth == true)
    }
}

// MARK: - Binding Tests

struct ComponentBindingTests {
    
    @Test func decodesGlobalBind() throws {
        let json = """
        { "type": "textfield", "bind": "user.name" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.bind == "user.name")
    }
    
    @Test func decodesLocalBind() throws {
        let json = """
        { "type": "textfield", "localBind": "searchText" }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.localBind == "searchText")
    }
    
    @Test func decodesIsSelectedBinding() throws {
        let json = """
        {
            "type": "button",
            "isSelectedBinding": "${selectedTab == 'home'}"
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.isSelectedBinding == "${selectedTab == 'home'}")
    }
}

// MARK: - Action Tests

struct ComponentActionTests {
    
    @Test func decodesOnTapReferenceAction() throws {
        let json = """
        {
            "type": "button",
            "actions": {
                "onTap": "submitForm"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        if case .reference(let ref) = component.actions?.onTap {
            #expect(ref == "submitForm")
        } else {
            Issue.record("Expected reference action binding")
        }
    }
    
    @Test func decodesOnTapInlineAction() throws {
        let json = """
        {
            "type": "button",
            "actions": {
                "onTap": { "type": "dismiss" }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        if case .inline(let action) = component.actions?.onTap {
            if case .dismiss = action {
                // Success
            } else {
                Issue.record("Expected dismiss action")
            }
        } else {
            Issue.record("Expected inline action binding")
        }
    }
    
    @Test func decodesOnValueChangedAction() throws {
        let json = """
        {
            "type": "slider",
            "actions": {
                "onValueChanged": {
                    "type": "setState",
                    "path": "volume",
                    "value": { "$expr": "value" }
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        if case .inline(let action) = component.actions?.onValueChanged {
            if case .setState = action {
                // Success
            } else {
                Issue.record("Expected setState action")
            }
        } else {
            Issue.record("Expected inline action binding")
        }
    }
    
    @Test func decodesBothActions() throws {
        let json = """
        {
            "type": "slider",
            "actions": {
                "onTap": "activate",
                "onValueChanged": "updateValue"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        if case .reference(let tapRef) = component.actions?.onTap {
            #expect(tapRef == "activate")
        }
        
        if case .reference(let changeRef) = component.actions?.onValueChanged {
            #expect(changeRef == "updateValue")
        }
    }
}

// MARK: - ComponentStyles Tests

struct ComponentStylesTests {
    
    @Test func decodesNormalStyle() throws {
        let json = """
        {
            "type": "button",
            "styles": {
                "normal": "buttonNormal"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.styles?.normal == "buttonNormal")
    }
    
    @Test func decodesSelectedStyle() throws {
        let json = """
        {
            "type": "button",
            "styles": {
                "selected": "buttonSelected"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.styles?.selected == "buttonSelected")
    }
    
    @Test func decodesDisabledStyle() throws {
        let json = """
        {
            "type": "button",
            "styles": {
                "disabled": "buttonDisabled"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.styles?.disabled == "buttonDisabled")
    }
    
    @Test func decodesAllStyles() throws {
        let json = """
        {
            "type": "button",
            "styles": {
                "normal": "pillButton",
                "selected": "pillButtonSelected",
                "disabled": "pillButtonDisabled"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        #expect(component.styles?.normal == "pillButton")
        #expect(component.styles?.selected == "pillButtonSelected")
        #expect(component.styles?.disabled == "pillButtonDisabled")
    }
}

// MARK: - Data Reference Tests

struct ComponentDataReferenceTests {
    
    @Test func decodesStaticDataReference() throws {
        let json = """
        {
            "type": "label",
            "data": {
                "value": {
                    "type": "static",
                    "value": "Hello World"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.data?["value"]?.type == .static)
        #expect(component.data?["value"]?.value == "Hello World")
    }
    
    @Test func decodesBindingDataReference() throws {
        let json = """
        {
            "type": "label",
            "data": {
                "value": {
                    "type": "binding",
                    "path": "user.name"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.data?["value"]?.type == .binding)
        #expect(component.data?["value"]?.path == "user.name")
    }
    
    @Test func decodesLocalBindingDataReference() throws {
        let json = """
        {
            "type": "label",
            "data": {
                "value": {
                    "type": "localBinding",
                    "path": "localCounter"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.data?["value"]?.type == .localBinding)
        #expect(component.data?["value"]?.path == "localCounter")
    }
    
    @Test func decodesTemplateDataReference() throws {
        let json = """
        {
            "type": "label",
            "data": {
                "value": {
                    "type": "binding",
                    "template": "Hello ${name}!"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.data?["value"]?.template == "Hello ${name}!")
    }
    
    @Test func decodesMultipleDataReferences() throws {
        let json = """
        {
            "type": "customComponent",
            "data": {
                "temperature": { "type": "binding", "path": "weather.temp" },
                "condition": { "type": "static", "value": "Sunny" },
                "humidity": { "type": "binding", "path": "weather.humidity" }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.data?.count == 3)
        #expect(component.data?["temperature"]?.path == "weather.temp")
        #expect(component.data?["condition"]?.value == "Sunny")
    }
}

// MARK: - Image Tests

struct ComponentImageTests {
    
    @Test func decodesSystemImage() throws {
        let json = """
        {
            "type": "image",
            "image": { "system": "star.fill" }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.image?.system == "star.fill")
        #expect(component.image?.url == nil)
    }
    
    @Test func decodesURLImage() throws {
        let json = """
        {
            "type": "image",
            "image": { "url": "https://example.com/image.png" }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.image?.url == "https://example.com/image.png")
        #expect(component.image?.system == nil)
    }
}

// MARK: - Gradient Tests

struct ComponentGradientTests {
    
    @Test func decodesGradientColors() throws {
        let json = """
        {
            "type": "gradient",
            "gradientColors": [
                { "color": "#FF0000", "location": 0.0 },
                { "color": "#00FF00", "location": 0.5 },
                { "color": "#0000FF", "location": 1.0 }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.gradientColors?.count == 3)
        #expect(component.gradientColors?[0].color == "#FF0000")
        #expect(component.gradientColors?[0].location == 0.0)
        #expect(component.gradientColors?[1].color == "#00FF00")
        #expect(component.gradientColors?[1].location == 0.5)
        #expect(component.gradientColors?[2].color == "#0000FF")
        #expect(component.gradientColors?[2].location == 1.0)
    }
    
    @Test func decodesAdaptiveGradientColors() throws {
        let json = """
        {
            "type": "gradient",
            "gradientColors": [
                { "lightColor": "#FFFFFF", "darkColor": "#000000", "location": 0.0 },
                { "lightColor": "#EEEEEE", "darkColor": "#111111", "location": 1.0 }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.gradientColors?[0].lightColor == "#FFFFFF")
        #expect(component.gradientColors?[0].darkColor == "#000000")
    }
    
    @Test func decodesGradientStartEnd() throws {
        let json = """
        {
            "type": "gradient",
            "gradientStart": "leading",
            "gradientEnd": "trailing"
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.gradientStart == "leading")
        #expect(component.gradientEnd == "trailing")
    }
}

// MARK: - Slider Tests

struct ComponentSliderTests {
    
    @Test func decodesSliderMinMax() throws {
        let json = """
        {
            "type": "slider",
            "minValue": 0,
            "maxValue": 100
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.minValue == 0)
        #expect(component.maxValue == 100)
    }
    
    @Test func decodesSliderWithDecimalRange() throws {
        let json = """
        {
            "type": "slider",
            "minValue": 0.0,
            "maxValue": 1.0
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.minValue == 0.0)
        #expect(component.maxValue == 1.0)
    }
}

// MARK: - Padding Tests

struct ComponentPaddingTests {
    
    @Test func decodesComponentPadding() throws {
        let json = """
        {
            "type": "label",
            "padding": {
                "top": 8,
                "bottom": 8,
                "leading": 16,
                "trailing": 16
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.padding?.top == 8)
        #expect(component.padding?.bottom == 8)
        #expect(component.padding?.leading == 16)
        #expect(component.padding?.trailing == 16)
    }
}

// MARK: - Local State Tests

struct ComponentLocalStateTests {
    
    @Test func decodesLocalState() throws {
        let json = """
        {
            "type": "button",
            "state": {
                "isPressed": false,
                "tapCount": 0
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.state?.initialValues["isPressed"] == .boolValue(false))
        #expect(component.state?.initialValues["tapCount"] == .intValue(0))
    }
}

// MARK: - Additional Properties Tests

struct ComponentAdditionalPropertiesTests {
    
    @Test func capturesUnknownProperties() throws {
        let json = """
        {
            "type": "customWidget",
            "customString": "hello",
            "customNumber": 42,
            "customBool": true
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.additionalProperties?["customString"]?.stringValue == "hello")
        #expect(component.additionalProperties?["customNumber"]?.intValue == 42)
        #expect(component.additionalProperties?["customBool"]?.boolValue == true)
    }
    
    @Test func capturesComplexAdditionalProperties() throws {
        let json = """
        {
            "type": "chart",
            "dataPoints": [1, 2, 3, 4, 5],
            "config": {
                "showLabels": true,
                "color": "#FF0000"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.additionalProperties?["dataPoints"]?.arrayValue?.count == 5)
        #expect(component.additionalProperties?["config"]?.objectValue?["showLabels"]?.boolValue == true)
    }
}

// MARK: - Full Component Tests

struct ComponentFullTests {
    
    @Test func decodesFullComponent() throws {
        let json = """
        {
            "type": "button",
            "id": "submitBtn",
            "styleId": "primaryButton",
            "text": "Submit",
            "styles": {
                "normal": "btnNormal",
                "selected": "btnSelected"
            },
            "padding": { "horizontal": 20 },
            "isSelectedBinding": "${isActive}",
            "fillWidth": true,
            "actions": {
                "onTap": "submitForm"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(component.type.rawValue == "button")
        #expect(component.id == "submitBtn")
        #expect(component.styleId == "primaryButton")
        #expect(component.text == "Submit")
        #expect(component.styles?.normal == "btnNormal")
        #expect(component.styles?.selected == "btnSelected")
        #expect(component.padding?.horizontal == 20)
        #expect(component.isSelectedBinding == "${isActive}")
        #expect(component.fillWidth == true)
    }
}

// MARK: - ActionBinding Tests

struct ActionBindingTests {
    
    @Test func decodesReferenceBinding() throws {
        let json = "\"actionId\""
        let data = json.data(using: .utf8)!
        let binding = try JSONDecoder().decode(Document.Component.ActionBinding.self, from: data)
        
        if case .reference(let ref) = binding {
            #expect(ref == "actionId")
        } else {
            Issue.record("Expected reference binding")
        }
    }
    
    @Test func decodesInlineBinding() throws {
        let json = """
        { "type": "dismiss" }
        """
        let data = json.data(using: .utf8)!
        let binding = try JSONDecoder().decode(Document.Component.ActionBinding.self, from: data)
        
        if case .inline(let action) = binding {
            if case .dismiss = action {
                // Success
            } else {
                Issue.record("Expected dismiss action")
            }
        } else {
            Issue.record("Expected inline binding")
        }
    }
}

// MARK: - ImageSource Tests

struct ImageSourceTests {
    
    @Test func imageSourceEquality() {
        let system1 = Document.ImageSource(system: "star")
        let system2 = Document.ImageSource(system: "star")
        let system3 = Document.ImageSource(system: "heart")
        let url1 = Document.ImageSource(url: "https://example.com")
        
        #expect(system1 == system2)
        #expect(system1 != system3)
        #expect(system1 != url1)
    }
}

// MARK: - Round Trip Tests

struct ComponentRoundTripTests {
    
    @Test func roundTripsComponent() throws {
        let original = Document.Component(
            type: Document.ComponentKind(rawValue: "button"),
            id: "testBtn",
            styleId: "myStyle",
            text: "Click Me",
            fillWidth: true
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.Component.self, from: data)
        
        #expect(decoded.type.rawValue == "button")
        #expect(decoded.id == "testBtn")
        #expect(decoded.styleId == "myStyle")
        #expect(decoded.text == "Click Me")
        #expect(decoded.fillWidth == true)
    }
}
