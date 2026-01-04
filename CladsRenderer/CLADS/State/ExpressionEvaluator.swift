//
//  ExpressionEvaluator.swift
//  CLADS
//
//  Evaluates expressions and interpolates template strings.
//  Extracted from StateStore for clarity and testability.
//

import Foundation

// MARK: - State Reading Protocol

/// Protocol for reading state values, used by ExpressionEvaluator.
/// This allows the evaluator to work with any state source.
public protocol StateValueReading {
    /// Get a value at the given keypath
    func getValue(_ keypath: String) -> Any?

    /// Get an array at the given keypath
    func getArray(_ keypath: String) -> [Any]?

    /// Check if an array contains a value
    func arrayContains(_ keypath: String, value: Any) -> Bool

    /// Get the count of an array
    func getArrayCount(_ keypath: String) -> Int
}

// MARK: - Expression Evaluator

/// Evaluates expressions and interpolates template strings against state.
///
/// Supports:
/// - Simple keypaths: `"count"`, `"user.name"`
/// - Array access: `"items[0]"`, `"items[0].name"`
/// - Array properties: `"items.count"`, `"items.isEmpty"`, `"items.first"`, `"items.last"`
/// - Array methods: `"items.contains(\"value\")"`, `"items.contains(varName)"`
/// - Ternary: `"condition ? 'trueValue' : 'falseValue'"`
/// - Arithmetic: `"count + 1"`, `"count - 1"`
/// - Template interpolation: `"Hello ${name}!"`
///
/// Example:
/// ```swift
/// let evaluator = ExpressionEvaluator()
///
/// // With a state reader
/// let result = evaluator.evaluate("count + 1", using: stateStore)
/// let message = evaluator.interpolate("Hello ${name}!", using: stateStore)
/// ```
public struct ExpressionEvaluator {

    public init() {}

    // MARK: - Main Evaluation

    /// Evaluate an expression against state.
    ///
    /// - Parameters:
    ///   - expression: The expression to evaluate
    ///   - stateReader: Source for reading state values
    /// - Returns: The evaluated result
    public func evaluate(_ expression: String, using stateReader: StateValueReading) -> Any {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        // Check for ternary expression first
        if let ternaryResult = evaluateTernary(trimmed, using: stateReader) {
            return ternaryResult
        }

        // Check for array expressions
        if let arrayResult = evaluateArrayExpression(trimmed, using: stateReader) {
            return arrayResult
        }

        // Check if it's a simple arithmetic expression
        if expression.contains("+") || expression.contains("-") {
            return evaluateArithmetic(expression, using: stateReader)
        }

        // Otherwise, just interpolate
        return interpolate(expression, using: stateReader)
    }

    // MARK: - Template Interpolation

    /// Interpolate template strings like "You pressed ${count} times".
    ///
    /// - Parameters:
    ///   - template: The template string with ${} placeholders
    ///   - stateReader: Source for reading state values
    /// - Returns: The interpolated string
    public func interpolate(_ template: String, using stateReader: StateValueReading) -> String {
        var result = template
        let pattern = #"\$\{([^}]+)\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return template
        }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range, in: template),
                  let keypathRange = Range(match.range(at: 1), in: template) else {
                continue
            }

            let expression = String(template[keypathRange])

            // Evaluate the expression (handles ternary, array expressions, etc.)
            let value = evaluateInterpolationExpression(expression, using: stateReader)

            let replacement = stringValue(from: value)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }

    /// Evaluate an expression found inside ${...} during interpolation
    private func evaluateInterpolationExpression(_ expression: String, using stateReader: StateValueReading) -> Any? {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        // Check for ternary expression
        if let ternaryResult = evaluateTernary(trimmed, using: stateReader) {
            return ternaryResult
        }

        // Check for array expressions
        if let arrayResult = evaluateArrayExpression(trimmed, using: stateReader) {
            return arrayResult
        }

        // Otherwise just get the value
        return stateReader.getValue(trimmed)
    }

    // MARK: - Ternary Expressions

    /// Evaluate ternary expressions: `condition ? 'trueValue' : 'falseValue'`
    private func evaluateTernary(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // Find the ? and : positions, being careful about nested quotes
        guard let questionIndex = findTernaryOperator(expression, char: "?") else { return nil }
        guard let colonIndex = findTernaryOperator(expression[expression.index(after: questionIndex)...], char: ":") else { return nil }

        let conditionStr = String(expression[..<questionIndex]).trimmingCharacters(in: .whitespaces)
        let trueExprStart = expression.index(after: questionIndex)
        let trueExprEnd = colonIndex
        let falseExprStart = expression.index(after: colonIndex)

        let trueValue = String(expression[trueExprStart..<trueExprEnd]).trimmingCharacters(in: .whitespaces)
        let falseValue = String(expression[falseExprStart...]).trimmingCharacters(in: .whitespaces)

        // Evaluate the condition
        let conditionResult = evaluateCondition(conditionStr, using: stateReader)

        // Return the appropriate value (strip quotes if present)
        let result = conditionResult ? trueValue : falseValue
        return stripQuotes(result)
    }

    /// Find ternary operator position, ignoring those inside quotes.
    private func findTernaryOperator(_ str: some StringProtocol, char: Character) -> String.Index? {
        var inSingleQuote = false
        var inDoubleQuote = false

        for index in str.indices {
            let c = str[index]
            if c == "'" && !inDoubleQuote {
                inSingleQuote.toggle()
            } else if c == "\"" && !inSingleQuote {
                inDoubleQuote.toggle()
            } else if c == char && !inSingleQuote && !inDoubleQuote {
                return index
            }
        }
        return nil
    }

    /// Evaluate a condition expression.
    private func evaluateCondition(_ condition: String, using stateReader: StateValueReading) -> Bool {
        // Try array expressions that return bool
        if let arrayResult = evaluateArrayExpression(condition, using: stateReader) as? Bool {
            return arrayResult
        }

        // Try direct boolean state value
        if let boolValue = stateReader.getValue(condition) as? Bool {
            return boolValue
        }

        // Try string "true"/"false"
        if condition.lowercased() == "true" {
            return true
        }
        if condition.lowercased() == "false" {
            return false
        }

        // Check for negation
        if condition.hasPrefix("!") {
            let inner = String(condition.dropFirst()).trimmingCharacters(in: .whitespaces)
            return !evaluateCondition(inner, using: stateReader)
        }

        // Default to false for unknown conditions
        return false
    }

    /// Strip single or double quotes from a string.
    private func stripQuotes(_ str: String) -> String {
        if (str.hasPrefix("'") && str.hasSuffix("'")) ||
           (str.hasPrefix("\"") && str.hasSuffix("\"")) {
            return String(str.dropFirst().dropLast())
        }
        return str
    }

    // MARK: - Array Expressions

    /// Evaluate array-specific expressions.
    private func evaluateArrayExpression(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // items.count
        if expression.hasSuffix(".count") {
            let path = String(expression.dropLast(6))
            return stateReader.getArrayCount(path)
        }

        // items.isEmpty
        if expression.hasSuffix(".isEmpty") {
            let path = String(expression.dropLast(8))
            return stateReader.getArrayCount(path) == 0
        }

        // items.first
        if expression.hasSuffix(".first") {
            let path = String(expression.dropLast(6))
            return stateReader.getArray(path)?.first
        }

        // items.last
        if expression.hasSuffix(".last") {
            let path = String(expression.dropLast(5))
            return stateReader.getArray(path)?.last
        }

        // items.contains("value") or items.contains(varName)
        if let match = matchContainsExpression(expression, using: stateReader) {
            let (arrayPath, searchValue) = match
            return stateReader.arrayContains(arrayPath, value: searchValue)
        }

        return nil
    }

    /// Match expressions like `items.contains("value")` or `items.contains(varName)`.
    private func matchContainsExpression(_ expression: String, using stateReader: StateValueReading) -> (arrayPath: String, value: Any)? {
        // Pattern: path.contains("stringLiteral") or path.contains(variableName)
        guard let containsRange = expression.range(of: ".contains(") else { return nil }
        guard expression.hasSuffix(")") else { return nil }

        let arrayPath = String(expression[..<containsRange.lowerBound])
        let argsStart = containsRange.upperBound
        let argsEnd = expression.index(before: expression.endIndex)
        let args = String(expression[argsStart..<argsEnd])

        // Check if it's a string literal "value" or 'value'
        if (args.hasPrefix("\"") && args.hasSuffix("\"")) ||
           (args.hasPrefix("'") && args.hasSuffix("'")) {
            let value = String(args.dropFirst().dropLast())
            return (arrayPath, value)
        }

        // Otherwise treat as a variable reference
        if let varValue = stateReader.getValue(args) {
            return (arrayPath, varValue)
        }

        return nil
    }

    // MARK: - Arithmetic

    /// Evaluate simple arithmetic expressions.
    private func evaluateArithmetic(_ expression: String, using stateReader: StateValueReading) -> Any {
        // Simple arithmetic: "${count} + 1"
        let interpolated = interpolate(expression, using: stateReader)

        // Try to evaluate as simple addition (split on " + " to avoid issues with signs)
        if let addRange = interpolated.range(of: " + ") {
            let left = String(interpolated[..<addRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(interpolated[addRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = Int(left), let rightNum = Int(right) {
                return leftNum + rightNum
            }
        }

        // Try to evaluate as simple subtraction (split on " - " to avoid issues with negative numbers)
        if let subRange = interpolated.range(of: " - ") {
            let left = String(interpolated[..<subRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(interpolated[subRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = Int(left), let rightNum = Int(right) {
                return leftNum - rightNum
            }
        }

        return interpolated
    }

    // MARK: - Helpers

    /// Convert any value to a string representation.
    private func stringValue(from value: Any?) -> String {
        switch value {
        case let int as Int: return String(int)
        case let double as Double: return String(double)
        case let string as String: return string
        case let bool as Bool: return String(bool)
        case nil: return ""
        default: return String(describing: value)
        }
    }
}

// MARK: - Convenience Extensions

extension ExpressionEvaluator {
    /// Check if a string contains expression syntax (${...}).
    public func containsExpression(_ string: String) -> Bool {
        return string.contains("${") && string.contains("}")
    }

    /// Check if a string is a pure expression (starts with ${ and ends with }).
    public func isPureExpression(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("${") && trimmed.hasSuffix("}")
    }

    /// Extract the expression from a ${...} wrapper.
    public func unwrapExpression(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("${") && trimmed.hasSuffix("}") else { return nil }
        return String(trimmed.dropFirst(2).dropLast())
    }
}
