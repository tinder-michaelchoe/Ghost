//
//  ExpressionEvaluatorTests.swift
//  CLADSTests
//
//  Unit tests for ExpressionEvaluator.
//

import Testing
@testable import CLADS

// MARK: - Mock State Reader

/// Mock implementation of StateValueReading for testing
struct MockStateReader: StateValueReading {
    var values: [String: Any] = [:]
    var arrays: [String: [Any]] = [:]

    func getValue(_ keypath: String) -> Any? {
        values[keypath]
    }

    func getArray(_ keypath: String) -> [Any]? {
        arrays[keypath]
    }

    func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = arrays[keypath] else { return false }
        return array.contains { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }
    }

    func getArrayCount(_ keypath: String) -> Int {
        arrays[keypath]?.count ?? 0
    }
}

// MARK: - Arithmetic Tests

struct ExpressionEvaluatorArithmeticTests {
    let evaluator = ExpressionEvaluator()

    @Test func additionWithPositiveNumbers() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} + 3", using: state)
        #expect(result as? Int == 8)
    }

    @Test func additionWithZero() {
        var state = MockStateReader()
        state.values["count"] = 0

        let result = evaluator.evaluate("${count} + 1", using: state)
        #expect(result as? Int == 1)
    }

    @Test func subtractionWithPositiveResult() {
        var state = MockStateReader()
        state.values["count"] = 10

        let result = evaluator.evaluate("${count} - 3", using: state)
        #expect(result as? Int == 7)
    }

    @Test func subtractionWithNegativeResult() {
        var state = MockStateReader()
        state.values["count"] = 0

        let result = evaluator.evaluate("${count} - 1", using: state)
        #expect(result as? Int == -1)
    }

    @Test func subtractionFromNegativeNumber() {
        var state = MockStateReader()
        state.values["count"] = -5

        let result = evaluator.evaluate("${count} - 3", using: state)
        #expect(result as? Int == -8)
    }

    @Test func additionToNegativeNumber() {
        var state = MockStateReader()
        state.values["count"] = -5

        let result = evaluator.evaluate("${count} + 3", using: state)
        #expect(result as? Int == -2)
    }

    @Test func subtractionResultingInZero() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} - 5", using: state)
        #expect(result as? Int == 0)
    }
}

// MARK: - Interpolation Tests

struct ExpressionEvaluatorInterpolationTests {
    let evaluator = ExpressionEvaluator()

    @Test func simpleInterpolation() {
        var state = MockStateReader()
        state.values["name"] = "John"

        let result = evaluator.interpolate("Hello ${name}!", using: state)
        #expect(result == "Hello John!")
    }

    @Test func multipleInterpolations() {
        var state = MockStateReader()
        state.values["firstName"] = "John"
        state.values["lastName"] = "Doe"

        let result = evaluator.interpolate("${firstName} ${lastName}", using: state)
        #expect(result == "John Doe")
    }

    @Test func integerInterpolation() {
        var state = MockStateReader()
        state.values["count"] = 42

        let result = evaluator.interpolate("Count: ${count}", using: state)
        #expect(result == "Count: 42")
    }

    @Test func missingValueInterpolation() {
        let state = MockStateReader()

        let result = evaluator.interpolate("Value: ${missing}", using: state)
        #expect(result == "Value: ")
    }

    @Test func noInterpolation() {
        let state = MockStateReader()

        let result = evaluator.interpolate("Plain text", using: state)
        #expect(result == "Plain text")
    }
}

// MARK: - Ternary Expression Tests

struct ExpressionEvaluatorTernaryTests {
    let evaluator = ExpressionEvaluator()

    @Test func ternaryWithTrueCondition() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("isActive ? 'ON' : 'OFF'", using: state)
        #expect(result as? String == "ON")
    }

    @Test func ternaryWithFalseCondition() {
        var state = MockStateReader()
        state.values["isActive"] = false

        let result = evaluator.evaluate("isActive ? 'ON' : 'OFF'", using: state)
        #expect(result as? String == "OFF")
    }

    @Test func ternaryWithNegation() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("!isActive ? 'OFF' : 'ON'", using: state)
        #expect(result as? String == "ON")
    }

    @Test func ternaryWithDoubleQuotes() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("isActive ? \"yes\" : \"no\"", using: state)
        #expect(result as? String == "yes")
    }

    @Test func ternaryWithLiteralTrue() {
        let state = MockStateReader()

        let result = evaluator.evaluate("true ? 'yes' : 'no'", using: state)
        #expect(result as? String == "yes")
    }

    @Test func ternaryWithLiteralFalse() {
        let state = MockStateReader()

        let result = evaluator.evaluate("false ? 'yes' : 'no'", using: state)
        #expect(result as? String == "no")
    }
}

// MARK: - Array Expression Tests

struct ExpressionEvaluatorArrayTests {
    let evaluator = ExpressionEvaluator()

    @Test func arrayCount() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]

        let result = evaluator.evaluate("items.count", using: state)
        #expect(result as? Int == 3)
    }

    @Test func arrayCountEmpty() {
        var state = MockStateReader()
        state.arrays["items"] = []

        let result = evaluator.evaluate("items.count", using: state)
        #expect(result as? Int == 0)
    }

    @Test func arrayIsEmptyTrue() {
        var state = MockStateReader()
        state.arrays["items"] = []

        let result = evaluator.evaluate("items.isEmpty", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayIsEmptyFalse() {
        var state = MockStateReader()
        state.arrays["items"] = ["a"]

        let result = evaluator.evaluate("items.isEmpty", using: state)
        #expect(result as? Bool == false)
    }

    @Test func arrayFirst() {
        var state = MockStateReader()
        state.arrays["items"] = ["first", "second", "third"]

        let result = evaluator.evaluate("items.first", using: state)
        #expect(result as? String == "first")
    }

    @Test func arrayLast() {
        var state = MockStateReader()
        state.arrays["items"] = ["first", "second", "third"]

        let result = evaluator.evaluate("items.last", using: state)
        #expect(result as? String == "third")
    }

    @Test func arrayContainsWithStringLiteral() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains(\"swift\")", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayContainsWithSingleQuotes() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains('ios')", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayContainsFalse() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains('android')", using: state)
        #expect(result as? Bool == false)
    }

    @Test func arrayContainsWithVariable() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]
        state.values["searchTag"] = "clads"

        let result = evaluator.evaluate("tags.contains(searchTag)", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayCountInInterpolation() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]

        let result = evaluator.interpolate("You have ${items.count} items", using: state)
        #expect(result == "You have 3 items")
    }
}

// MARK: - Convenience Method Tests

struct ExpressionEvaluatorConvenienceTests {
    let evaluator = ExpressionEvaluator()

    @Test func containsExpressionTrue() {
        #expect(evaluator.containsExpression("Hello ${name}!") == true)
    }

    @Test func containsExpressionFalse() {
        #expect(evaluator.containsExpression("Hello World!") == false)
    }

    @Test func isPureExpressionTrue() {
        #expect(evaluator.isPureExpression("${count}") == true)
    }

    @Test func isPureExpressionWithWhitespace() {
        #expect(evaluator.isPureExpression("  ${count}  ") == true)
    }

    @Test func isPureExpressionFalse() {
        #expect(evaluator.isPureExpression("Count: ${count}") == false)
    }

    @Test func unwrapExpression() {
        let result = evaluator.unwrapExpression("${count}")
        #expect(result == "count")
    }

    @Test func unwrapExpressionWithWhitespace() {
        let result = evaluator.unwrapExpression("  ${user.name}  ")
        #expect(result == "user.name")
    }

    @Test func unwrapExpressionInvalid() {
        let result = evaluator.unwrapExpression("not an expression")
        #expect(result == nil)
    }
}
