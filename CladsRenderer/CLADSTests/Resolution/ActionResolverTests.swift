//
//  ActionResolverTests.swift
//  CLADSTests
//
//  Unit tests for ActionResolver - converting Document.Action to ActionDefinition.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Dismiss Action Tests

struct ActionResolverDismissTests {
    
    @Test func resolvesDismissAction() {
        let resolver = ActionResolver()
        let action = Document.Action.dismiss
        
        let result = resolver.resolve(action)
        
        if case .dismiss = result {
            // Success
        } else {
            Issue.record("Expected dismiss action definition")
        }
    }
}

// MARK: - SetState Action Tests

struct ActionResolverSetStateTests {
    
    @Test func resolvesSetStateWithLiteralString() {
        let resolver = ActionResolver()
        let action = Document.Action.setState(Document.SetStateAction(
            path: "user.name",
            value: .literal(.stringValue("John"))
        ))
        
        let result = resolver.resolve(action)
        
        if case .setState(let path, let value) = result {
            #expect(path == "user.name")
            if case .literal(let stateValue) = value {
                #expect(stateValue == .stringValue("John"))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action definition")
        }
    }
    
    @Test func resolvesSetStateWithLiteralInt() {
        let resolver = ActionResolver()
        let action = Document.Action.setState(Document.SetStateAction(
            path: "counter",
            value: .literal(.intValue(42))
        ))
        
        let result = resolver.resolve(action)
        
        if case .setState(let path, let value) = result {
            #expect(path == "counter")
            if case .literal(let stateValue) = value {
                #expect(stateValue == .intValue(42))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action definition")
        }
    }
    
    @Test func resolvesSetStateWithLiteralBool() {
        let resolver = ActionResolver()
        let action = Document.Action.setState(Document.SetStateAction(
            path: "isActive",
            value: .literal(.boolValue(true))
        ))
        
        let result = resolver.resolve(action)
        
        if case .setState(let path, let value) = result {
            #expect(path == "isActive")
            if case .literal(let stateValue) = value {
                #expect(stateValue == .boolValue(true))
            } else {
                Issue.record("Expected literal value")
            }
        } else {
            Issue.record("Expected setState action definition")
        }
    }
    
    @Test func resolvesSetStateWithExpression() {
        let resolver = ActionResolver()
        let action = Document.Action.setState(Document.SetStateAction(
            path: "count",
            value: .expression("${count} + 1")
        ))
        
        let result = resolver.resolve(action)
        
        if case .setState(let path, let value) = result {
            #expect(path == "count")
            if case .expression(let expr) = value {
                #expect(expr == "${count} + 1")
            } else {
                Issue.record("Expected expression value")
            }
        } else {
            Issue.record("Expected setState action definition")
        }
    }
    
    @Test func resolvesSetStateWithNestedPath() {
        let resolver = ActionResolver()
        let action = Document.Action.setState(Document.SetStateAction(
            path: "user.profile.settings.theme",
            value: .literal(.stringValue("dark"))
        ))
        
        let result = resolver.resolve(action)
        
        if case .setState(let path, _) = result {
            #expect(path == "user.profile.settings.theme")
        } else {
            Issue.record("Expected setState action definition")
        }
    }
}

// MARK: - ToggleState Action Tests

struct ActionResolverToggleStateTests {
    
    @Test func resolvesToggleStateAction() {
        let resolver = ActionResolver()
        let action = Document.Action.toggleState(Document.ToggleStateAction(path: "isEnabled"))
        
        let result = resolver.resolve(action)
        
        if case .toggleState(let path) = result {
            #expect(path == "isEnabled")
        } else {
            Issue.record("Expected toggleState action definition")
        }
    }
    
    @Test func resolvesToggleStateWithNestedPath() {
        let resolver = ActionResolver()
        let action = Document.Action.toggleState(Document.ToggleStateAction(path: "settings.notifications.enabled"))
        
        let result = resolver.resolve(action)
        
        if case .toggleState(let path) = result {
            #expect(path == "settings.notifications.enabled")
        } else {
            Issue.record("Expected toggleState action definition")
        }
    }
}

// MARK: - ShowAlert Action Tests

struct ActionResolverShowAlertTests {
    
    @Test func resolvesShowAlertWithTitleOnly() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Alert Title"
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            #expect(config.title == "Alert Title")
            #expect(config.message == nil)
            #expect(config.buttons.isEmpty)
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
    
    @Test func resolvesShowAlertWithStaticMessage() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Error",
            message: .static("Something went wrong")
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            #expect(config.title == "Error")
            if case .static(let message) = config.message {
                #expect(message == "Something went wrong")
            } else {
                Issue.record("Expected static message")
            }
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
    
    @Test func resolvesShowAlertWithTemplateMessage() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Welcome",
            message: .template("Hello ${username}!")
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            if case .template(let template) = config.message {
                #expect(template == "Hello ${username}!")
            } else {
                Issue.record("Expected template message")
            }
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
    
    @Test func resolvesShowAlertWithButtons() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Confirm",
            buttons: [
                Document.AlertButton(label: "OK", style: .default),
                Document.AlertButton(label: "Cancel", style: .cancel)
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            #expect(config.buttons.count == 2)
            #expect(config.buttons[0].label == "OK")
            #expect(config.buttons[0].style == .default)
            #expect(config.buttons[1].label == "Cancel")
            #expect(config.buttons[1].style == .cancel)
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
    
    @Test func resolvesShowAlertWithButtonAction() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Delete?",
            buttons: [
                Document.AlertButton(label: "Delete", style: .destructive, action: "confirmDelete")
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            #expect(config.buttons[0].action == "confirmDelete")
            #expect(config.buttons[0].style == .destructive)
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
    
    @Test func resolvesShowAlertWithDefaultButtonStyle() {
        let resolver = ActionResolver()
        let action = Document.Action.showAlert(Document.ShowAlertAction(
            title: "Info",
            buttons: [
                Document.AlertButton(label: "OK")
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .showAlert(let config) = result {
            #expect(config.buttons[0].style == .default)
        } else {
            Issue.record("Expected showAlert action definition")
        }
    }
}

// MARK: - Navigate Action Tests

struct ActionResolverNavigateTests {
    
    @Test func resolvesNavigateWithDefaultPresentation() {
        let resolver = ActionResolver()
        let action = Document.Action.navigate(Document.NavigateAction(
            destination: "settings"
        ))
        
        let result = resolver.resolve(action)
        
        if case .navigate(let destination, let presentation) = result {
            #expect(destination == "settings")
            #expect(presentation == .push)
        } else {
            Issue.record("Expected navigate action definition")
        }
    }
    
    @Test func resolvesNavigateWithPush() {
        let resolver = ActionResolver()
        let action = Document.Action.navigate(Document.NavigateAction(
            destination: "profile",
            presentation: .push
        ))
        
        let result = resolver.resolve(action)
        
        if case .navigate(let destination, let presentation) = result {
            #expect(destination == "profile")
            #expect(presentation == .push)
        } else {
            Issue.record("Expected navigate action definition")
        }
    }
    
    @Test func resolvesNavigateWithPresent() {
        let resolver = ActionResolver()
        let action = Document.Action.navigate(Document.NavigateAction(
            destination: "modal",
            presentation: .present
        ))
        
        let result = resolver.resolve(action)
        
        if case .navigate(_, let presentation) = result {
            #expect(presentation == .present)
        } else {
            Issue.record("Expected navigate action definition")
        }
    }
    
    @Test func resolvesNavigateWithFullScreen() {
        let resolver = ActionResolver()
        let action = Document.Action.navigate(Document.NavigateAction(
            destination: "fullscreen",
            presentation: .fullScreen
        ))
        
        let result = resolver.resolve(action)
        
        if case .navigate(_, let presentation) = result {
            #expect(presentation == .fullScreen)
        } else {
            Issue.record("Expected navigate action definition")
        }
    }
}

// MARK: - Sequence Action Tests

struct ActionResolverSequenceTests {
    
    @Test func resolvesEmptySequence() {
        let resolver = ActionResolver()
        let action = Document.Action.sequence(Document.SequenceAction(steps: []))
        
        let result = resolver.resolve(action)
        
        if case .sequence(let steps) = result {
            #expect(steps.isEmpty)
        } else {
            Issue.record("Expected sequence action definition")
        }
    }
    
    @Test func resolvesSingleStepSequence() {
        let resolver = ActionResolver()
        let action = Document.Action.sequence(Document.SequenceAction(
            steps: [.dismiss]
        ))
        
        let result = resolver.resolve(action)
        
        if case .sequence(let steps) = result {
            #expect(steps.count == 1)
            if case .dismiss = steps[0] {
                // Success
            } else {
                Issue.record("Expected dismiss step")
            }
        } else {
            Issue.record("Expected sequence action definition")
        }
    }
    
    @Test func resolvesMultiStepSequence() {
        let resolver = ActionResolver()
        let action = Document.Action.sequence(Document.SequenceAction(
            steps: [
                .setState(Document.SetStateAction(path: "loading", value: .literal(.boolValue(true)))),
                .showAlert(Document.ShowAlertAction(title: "Processing...")),
                .dismiss
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .sequence(let steps) = result {
            #expect(steps.count == 3)
            if case .setState = steps[0] { } else { Issue.record("Expected setState") }
            if case .showAlert = steps[1] { } else { Issue.record("Expected showAlert") }
            if case .dismiss = steps[2] { } else { Issue.record("Expected dismiss") }
        } else {
            Issue.record("Expected sequence action definition")
        }
    }
    
    @Test func resolvesNestedSequence() {
        let resolver = ActionResolver()
        let action = Document.Action.sequence(Document.SequenceAction(
            steps: [
                .sequence(Document.SequenceAction(
                    steps: [.dismiss]
                ))
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .sequence(let steps) = result {
            if case .sequence(let nested) = steps[0] {
                #expect(nested.count == 1)
            } else {
                Issue.record("Expected nested sequence")
            }
        } else {
            Issue.record("Expected sequence action definition")
        }
    }
}

// MARK: - Custom Action Tests

struct ActionResolverCustomTests {
    
    @Test func resolvesCustomActionWithType() {
        let resolver = ActionResolver()
        let action = Document.Action.custom(Document.CustomAction(
            type: "analytics.track"
        ))
        
        let result = resolver.resolve(action)
        
        if case .custom(let type, let params) = result {
            #expect(type == "analytics.track")
            #expect(params.isEmpty)
        } else {
            Issue.record("Expected custom action definition")
        }
    }
    
    @Test func resolvesCustomActionWithParameters() {
        let resolver = ActionResolver()
        let action = Document.Action.custom(Document.CustomAction(
            type: "api.call",
            parameters: [
                "endpoint": .stringValue("/users"),
                "method": .stringValue("GET")
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .custom(let type, let params) = result {
            #expect(type == "api.call")
            #expect(params["endpoint"] == .stringValue("/users"))
            #expect(params["method"] == .stringValue("GET"))
        } else {
            Issue.record("Expected custom action definition")
        }
    }
    
    @Test func resolvesCustomActionWithNestedParameters() {
        let resolver = ActionResolver()
        let action = Document.Action.custom(Document.CustomAction(
            type: "complex.action",
            parameters: [
                "config": .objectValue([
                    "enabled": .boolValue(true),
                    "count": .intValue(5)
                ])
            ]
        ))
        
        let result = resolver.resolve(action)
        
        if case .custom(_, let params) = result {
            if case .objectValue(let config) = params["config"] {
                #expect(config["enabled"] == .boolValue(true))
                #expect(config["count"] == .intValue(5))
            } else {
                Issue.record("Expected object parameter")
            }
        } else {
            Issue.record("Expected custom action definition")
        }
    }
}

// MARK: - ResolveAll Tests

struct ActionResolverResolveAllTests {
    
    @Test func resolvesNilActionsToEmptyDictionary() {
        let resolver = ActionResolver()
        
        let result = resolver.resolveAll(nil)
        
        #expect(result.isEmpty)
    }
    
    @Test func resolvesEmptyActionsToEmptyDictionary() {
        let resolver = ActionResolver()
        
        let result = resolver.resolveAll([:])
        
        #expect(result.isEmpty)
    }
    
    @Test func resolvesMultipleActions() {
        let resolver = ActionResolver()
        let actions: [String: Document.Action] = [
            "close": .dismiss,
            "toggle": .toggleState(Document.ToggleStateAction(path: "flag")),
            "submit": .navigate(Document.NavigateAction(destination: "confirmation"))
        ]
        
        let result = resolver.resolveAll(actions)
        
        #expect(result.count == 3)
        #expect(result.keys.contains("close"))
        #expect(result.keys.contains("toggle"))
        #expect(result.keys.contains("submit"))
    }
    
    @Test func preservesActionIds() {
        let resolver = ActionResolver()
        let actions: [String: Document.Action] = [
            "mySpecialAction": .dismiss
        ]
        
        let result = resolver.resolveAll(actions)
        
        if case .dismiss = result["mySpecialAction"] {
            // Success
        } else {
            Issue.record("Expected action with correct ID")
        }
    }
}
