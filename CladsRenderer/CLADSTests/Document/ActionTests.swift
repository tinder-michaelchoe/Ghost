//
//  ActionTests.swift
//  CLADSTests
//
//  Unit tests for Document.Action JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Dismiss Action Tests

struct DismissActionTests {
    
    @Test func decodesDismissAction() throws {
        let json = """
        { "type": "dismiss" }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .dismiss = action {
            // Success
        } else {
            Issue.record("Expected dismiss action")
        }
    }
}

// MARK: - SetState Action Tests

struct SetStateActionTests {
    
    @Test func decodesSetStateWithStringLiteral() throws {
        let json = """
        {
            "type": "setState",
            "path": "user.name",
            "value": "John"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let setStateAction) = action {
            #expect(setStateAction.path == "user.name")
            if case .literal(let value) = setStateAction.value {
                #expect(value == .stringValue("John"))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
    
    @Test func decodesSetStateWithIntLiteral() throws {
        let json = """
        {
            "type": "setState",
            "path": "counter",
            "value": 42
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let setStateAction) = action {
            #expect(setStateAction.path == "counter")
            if case .literal(let value) = setStateAction.value {
                #expect(value == .intValue(42))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
    
    @Test func decodesSetStateWithBoolLiteral() throws {
        let json = """
        {
            "type": "setState",
            "path": "isActive",
            "value": true
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let setStateAction) = action {
            if case .literal(let value) = setStateAction.value {
                #expect(value == .boolValue(true))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
    
    @Test func decodesSetStateWithExpression() throws {
        let json = """
        {
            "type": "setState",
            "path": "counter",
            "value": { "$expr": "${counter} + 1" }
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let setStateAction) = action {
            #expect(setStateAction.path == "counter")
            if case .expression(let expr) = setStateAction.value {
                #expect(expr == "${counter} + 1")
            } else {
                Issue.record("Expected expression value")
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
    
    @Test func decodesSetStateWithArrayLiteral() throws {
        let json = """
        {
            "type": "setState",
            "path": "items",
            "value": ["a", "b", "c"]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let setStateAction) = action {
            if case .literal(let value) = setStateAction.value {
                #expect(value == .arrayValue([
                    .stringValue("a"),
                    .stringValue("b"),
                    .stringValue("c")
                ]))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action")
        }
    }
}

// MARK: - ToggleState Action Tests

struct ToggleStateActionTests {
    
    @Test func decodesToggleStateAction() throws {
        let json = """
        {
            "type": "toggleState",
            "path": "selected.technology"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .toggleState(let toggleAction) = action {
            #expect(toggleAction.path == "selected.technology")
        } else {
            Issue.record("Expected toggleState action")
        }
    }
    
    @Test func decodesToggleStateWithSimplePath() throws {
        let json = """
        {
            "type": "toggleState",
            "path": "isActive"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .toggleState(let toggleAction) = action {
            #expect(toggleAction.path == "isActive")
        } else {
            Issue.record("Expected toggleState action")
        }
    }
}

// MARK: - ShowAlert Action Tests

struct ShowAlertActionTests {
    
    @Test func decodesShowAlertWithStaticMessage() throws {
        let json = """
        {
            "type": "showAlert",
            "title": "Warning",
            "message": "Are you sure?"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .showAlert(let alertAction) = action {
            #expect(alertAction.title == "Warning")
            if case .static(let msg) = alertAction.message {
                #expect(msg == "Are you sure?")
            } else {
                Issue.record("Expected static message")
            }
        } else {
            Issue.record("Expected showAlert action")
        }
    }
    
    @Test func decodesShowAlertWithTemplateMessage() throws {
        let json = """
        {
            "type": "showAlert",
            "title": "Info",
            "message": {
                "type": "binding",
                "template": "Count is ${count}"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .showAlert(let alertAction) = action {
            #expect(alertAction.title == "Info")
            if case .template(let template) = alertAction.message {
                #expect(template == "Count is ${count}")
            } else {
                Issue.record("Expected template message")
            }
        } else {
            Issue.record("Expected showAlert action")
        }
    }
    
    @Test func decodesShowAlertWithButtons() throws {
        let json = """
        {
            "type": "showAlert",
            "title": "Confirm",
            "message": "Delete this item?",
            "buttons": [
                { "label": "Cancel", "style": "cancel" },
                { "label": "Delete", "style": "destructive", "action": "deleteItem" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .showAlert(let alertAction) = action {
            #expect(alertAction.buttons?.count == 2)
            #expect(alertAction.buttons?[0].label == "Cancel")
            #expect(alertAction.buttons?[0].style == .cancel)
            #expect(alertAction.buttons?[1].label == "Delete")
            #expect(alertAction.buttons?[1].style == .destructive)
            #expect(alertAction.buttons?[1].action == "deleteItem")
        } else {
            Issue.record("Expected showAlert action")
        }
    }
    
    @Test func decodesShowAlertWithDefaultButton() throws {
        let json = """
        {
            "type": "showAlert",
            "title": "Notice",
            "buttons": [
                { "label": "OK", "style": "default" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .showAlert(let alertAction) = action {
            #expect(alertAction.buttons?[0].style == .default)
        } else {
            Issue.record("Expected showAlert action")
        }
    }
    
    @Test func decodesShowAlertWithoutMessage() throws {
        let json = """
        {
            "type": "showAlert",
            "title": "Title Only"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .showAlert(let alertAction) = action {
            #expect(alertAction.title == "Title Only")
            #expect(alertAction.message == nil)
        } else {
            Issue.record("Expected showAlert action")
        }
    }
}

// MARK: - Navigate Action Tests

struct NavigateActionTests {
    
    @Test func decodesNavigateWithDestinationOnly() throws {
        let json = """
        {
            "type": "navigate",
            "destination": "home"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .navigate(let navigateAction) = action {
            #expect(navigateAction.destination == "home")
            #expect(navigateAction.presentation == nil)
        } else {
            Issue.record("Expected navigate action")
        }
    }
    
    @Test func decodesNavigateWithPushPresentation() throws {
        let json = """
        {
            "type": "navigate",
            "destination": "details",
            "presentation": "push"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .navigate(let navigateAction) = action {
            #expect(navigateAction.destination == "details")
            #expect(navigateAction.presentation == .push)
        } else {
            Issue.record("Expected navigate action")
        }
    }
    
    @Test func decodesNavigateWithPresentPresentation() throws {
        let json = """
        {
            "type": "navigate",
            "destination": "settings",
            "presentation": "present"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .navigate(let navigateAction) = action {
            #expect(navigateAction.presentation == .present)
        } else {
            Issue.record("Expected navigate action")
        }
    }
    
    @Test func decodesNavigateWithFullScreenPresentation() throws {
        let json = """
        {
            "type": "navigate",
            "destination": "onboarding",
            "presentation": "fullScreen"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .navigate(let navigateAction) = action {
            #expect(navigateAction.presentation == .fullScreen)
        } else {
            Issue.record("Expected navigate action")
        }
    }
}

// MARK: - Sequence Action Tests

struct SequenceActionTests {
    
    @Test func decodesSequenceWithMultipleActions() throws {
        let json = """
        {
            "type": "sequence",
            "steps": [
                { "type": "setState", "path": "loading", "value": true },
                { "type": "navigate", "destination": "results" },
                { "type": "dismiss" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .sequence(let sequenceAction) = action {
            #expect(sequenceAction.steps.count == 3)
            
            if case .setState(let step0) = sequenceAction.steps[0] {
                #expect(step0.path == "loading")
            } else {
                Issue.record("Expected setState as first step")
            }
            
            if case .navigate(let step1) = sequenceAction.steps[1] {
                #expect(step1.destination == "results")
            } else {
                Issue.record("Expected navigate as second step")
            }
            
            if case .dismiss = sequenceAction.steps[2] {
                // Success
            } else {
                Issue.record("Expected dismiss as third step")
            }
        } else {
            Issue.record("Expected sequence action")
        }
    }
    
    @Test func decodesSequenceWithSingleAction() throws {
        let json = """
        {
            "type": "sequence",
            "steps": [
                { "type": "dismiss" }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .sequence(let sequenceAction) = action {
            #expect(sequenceAction.steps.count == 1)
        } else {
            Issue.record("Expected sequence action")
        }
    }
    
    @Test func decodesNestedSequence() throws {
        let json = """
        {
            "type": "sequence",
            "steps": [
                {
                    "type": "sequence",
                    "steps": [
                        { "type": "dismiss" }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .sequence(let sequenceAction) = action {
            if case .sequence(let nestedSequence) = sequenceAction.steps[0] {
                #expect(nestedSequence.steps.count == 1)
            } else {
                Issue.record("Expected nested sequence")
            }
        } else {
            Issue.record("Expected sequence action")
        }
    }
}

// MARK: - Custom Action Tests

struct CustomActionTests {
    
    @Test func decodesCustomAction() throws {
        let json = """
        {
            "type": "analytics.track",
            "event": "button_clicked",
            "category": "ui"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .custom(let customAction) = action {
            #expect(customAction.type == "analytics.track")
            #expect(customAction.parameters["event"] == .stringValue("button_clicked"))
            #expect(customAction.parameters["category"] == .stringValue("ui"))
        } else {
            Issue.record("Expected custom action")
        }
    }
    
    @Test func decodesCustomActionWithComplexParams() throws {
        let json = """
        {
            "type": "myCustomAction",
            "count": 5,
            "enabled": true,
            "tags": ["a", "b"]
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .custom(let customAction) = action {
            #expect(customAction.type == "myCustomAction")
            #expect(customAction.parameters["count"] == .intValue(5))
            #expect(customAction.parameters["enabled"] == .boolValue(true))
            #expect(customAction.parameters["tags"] == .arrayValue([
                .stringValue("a"),
                .stringValue("b")
            ]))
        } else {
            Issue.record("Expected custom action")
        }
    }
    
    @Test func decodesCustomActionWithNoParams() throws {
        let json = """
        {
            "type": "unknownAction"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .custom(let customAction) = action {
            #expect(customAction.type == "unknownAction")
            #expect(customAction.parameters.isEmpty)
        } else {
            Issue.record("Expected custom action")
        }
    }
}

// MARK: - SetValue Tests

struct SetValueTests {
    
    @Test func decodesLiteralString() throws {
        let json = "\"hello\""
        let data = json.data(using: .utf8)!
        let setValue = try JSONDecoder().decode(Document.SetValue.self, from: data)
        
        if case .literal(let value) = setValue {
            #expect(value == .stringValue("hello"))
        } else {
            Issue.record("Expected literal value")
        }
    }
    
    @Test func decodesLiteralNumber() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let setValue = try JSONDecoder().decode(Document.SetValue.self, from: data)
        
        if case .literal(let value) = setValue {
            #expect(value == .intValue(42))
        } else {
            Issue.record("Expected literal value")
        }
    }
    
    @Test func decodesExpression() throws {
        let json = """
        { "$expr": "count + 1" }
        """
        let data = json.data(using: .utf8)!
        let setValue = try JSONDecoder().decode(Document.SetValue.self, from: data)
        
        if case .expression(let expr) = setValue {
            #expect(expr == "count + 1")
        } else {
            Issue.record("Expected expression value")
        }
    }
    
    @Test func decodesLiteralNull() throws {
        let json = "null"
        let data = json.data(using: .utf8)!
        let setValue = try JSONDecoder().decode(Document.SetValue.self, from: data)
        
        if case .literal(let value) = setValue {
            #expect(value == .nullValue)
        } else {
            Issue.record("Expected literal null value")
        }
    }
}

// MARK: - AlertMessageContent Tests

struct AlertMessageContentTests {
    
    @Test func decodesStaticString() throws {
        let json = "\"Simple message\""
        let data = json.data(using: .utf8)!
        let content = try JSONDecoder().decode(Document.AlertMessageContent.self, from: data)
        
        if case .static(let message) = content {
            #expect(message == "Simple message")
        } else {
            Issue.record("Expected static message")
        }
    }
    
    @Test func decodesTemplateBinding() throws {
        let json = """
        {
            "type": "binding",
            "template": "Hello ${name}!"
        }
        """
        let data = json.data(using: .utf8)!
        let content = try JSONDecoder().decode(Document.AlertMessageContent.self, from: data)
        
        if case .template(let template) = content {
            #expect(template == "Hello ${name}!")
        } else {
            Issue.record("Expected template message")
        }
    }
}

// MARK: - AlertButton Tests

struct AlertButtonTests {
    
    @Test func decodesMinimalButton() throws {
        let json = """
        { "label": "OK" }
        """
        let data = json.data(using: .utf8)!
        let button = try JSONDecoder().decode(Document.AlertButton.self, from: data)
        
        #expect(button.label == "OK")
        #expect(button.style == nil)
        #expect(button.action == nil)
    }
    
    @Test func decodesFullButton() throws {
        let json = """
        {
            "label": "Delete",
            "style": "destructive",
            "action": "confirmDelete"
        }
        """
        let data = json.data(using: .utf8)!
        let button = try JSONDecoder().decode(Document.AlertButton.self, from: data)
        
        #expect(button.label == "Delete")
        #expect(button.style == .destructive)
        #expect(button.action == "confirmDelete")
    }
}

// MARK: - Action Dictionary Tests

struct ActionDictionaryTests {
    
    @Test func decodesActionsDictionary() throws {
        let json = """
        {
            "dismiss": { "type": "dismiss" },
            "increment": {
                "type": "setState",
                "path": "count",
                "value": { "$expr": "${count} + 1" }
            },
            "goHome": {
                "type": "navigate",
                "destination": "home"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let actions = try JSONDecoder().decode([String: Document.Action].self, from: data)
        
        #expect(actions.count == 3)
        
        if case .dismiss = actions["dismiss"] {
            // Success
        } else {
            Issue.record("Expected dismiss action")
        }
        
        if case .setState = actions["increment"] {
            // Success
        } else {
            Issue.record("Expected setState action")
        }
        
        if case .navigate = actions["goHome"] {
            // Success
        } else {
            Issue.record("Expected navigate action")
        }
    }
}

// MARK: - Round Trip Tests

struct ActionRoundTripTests {
    
    @Test func roundTripsDismissAction() throws {
        let original = Document.Action.dismiss
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .dismiss = decoded {
            // Success
        } else {
            Issue.record("Expected dismiss action after round trip")
        }
    }
    
    @Test func roundTripsSetStateAction() throws {
        let original = Document.Action.setState(
            Document.SetStateAction(path: "count", value: .literal(.intValue(10)))
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .setState(let action) = decoded {
            #expect(action.path == "count")
        } else {
            Issue.record("Expected setState action after round trip")
        }
    }
    
    @Test func roundTripsNavigateAction() throws {
        let original = Document.Action.navigate(
            Document.NavigateAction(destination: "home", presentation: .push)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.Action.self, from: data)
        
        if case .navigate(let action) = decoded {
            #expect(action.destination == "home")
            #expect(action.presentation == .push)
        } else {
            Issue.record("Expected navigate action after round trip")
        }
    }
}
