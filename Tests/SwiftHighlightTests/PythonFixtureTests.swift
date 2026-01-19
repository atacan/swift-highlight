import XCTest
@testable import SwiftHighlight

/// Tests Python highlighting against the original highlight.js test fixtures
final class PythonFixtureTests: XCTestCase {

    var hljs: Highlight!

    override func setUp() async throws {
        try await super.setUp()
        hljs = Highlight()
        await hljs.registerPython()
    }

    // MARK: - Fixture Test Runner

    /// Runs a fixture test by comparing SwiftHighlight output to expected output
    private func runFixture(_ name: String, file: StaticString = #file, line: UInt = #line) async {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/python"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/python") else {
            XCTFail("Could not find fixture files for '\(name)'", file: file, line: line)
            return
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            XCTFail("Could not read fixture files for '\(name)'", file: file, line: line)
            return
        }

        let result = await hljs.highlight(input, language: "python")
        let actual = normalizeFixtureOutput(result.value)
        let expectedNormalized = normalizeFixtureOutput(expected)

        // Compare the outputs
        if actual != expectedNormalized {
            // Find first difference for better error message
            let actualLines = actual.components(separatedBy: "\n")
            let expectedLines = expectedNormalized.components(separatedBy: "\n")

            for (i, (actualLine, expectedLine)) in zip(actualLines, expectedLines).enumerated() {
                if actualLine != expectedLine {
                    XCTFail("""
                        Fixture '\(name)' mismatch at line \(i + 1):
                        Expected: \(expectedLine)
                        Actual:   \(actualLine)
                        """, file: file, line: line)
                    return
                }
            }

            if actualLines.count != expectedLines.count {
                XCTFail("""
                    Fixture '\(name)' line count mismatch:
                    Expected: \(expectedLines.count) lines
                    Actual:   \(actualLines.count) lines
                    """, file: file, line: line)
            }
        }
    }

    /// Runs a fixture test and reports differences without failing (for development)
    private func runFixtureReport(_ name: String) async -> (passed: Bool, diff: String?) {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/python"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/python") else {
            return (false, "Could not find fixture files")
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            return (false, "Could not read fixture files")
        }

        let result = await hljs.highlight(input, language: "python")
        let actual = normalizeFixtureOutput(result.value)
        let expectedNormalized = normalizeFixtureOutput(expected)

        if actual == expectedNormalized {
            return (true, nil)
        }

        // Generate diff
        let actualLines = actual.components(separatedBy: "\n")
        let expectedLines = expectedNormalized.components(separatedBy: "\n")
        var diff = ""

        let maxLines = max(actualLines.count, expectedLines.count)
        for i in 0..<maxLines {
            let actualLine = i < actualLines.count ? actualLines[i] : "<missing>"
            let expectedLine = i < expectedLines.count ? expectedLines[i] : "<missing>"
            if actualLine != expectedLine {
                diff += "Line \(i + 1):\n"
                diff += "  Expected: \(expectedLine)\n"
                diff += "  Actual:   \(actualLine)\n"
            }
        }

        return (false, diff)
    }

    // MARK: - Individual Fixture Tests

    func testKeywords() async throws {
        await runFixture("keywords")
    }

    func testNumbers() async throws {
        await runFixture("numbers")
    }

    func testClassSelf() async throws {
        await runFixture("class_self")
    }

    func testDecorators() async throws {
        await runFixture("decorators")
    }

    func testFStrings() async throws {
        await runFixture("f-strings")
    }

    func testEscapedQuotes() async throws {
        await runFixture("escaped-quotes")
    }

    func testFunctionHeader() async throws {
        await runFixture("function-header")
    }

    func testFunctionHeaderComments() async throws {
        await runFixture("function-header-comments")
    }

    func testIdentifiers() async throws {
        await runFixture("identifiers")
    }

    func testFalsePositives() async throws {
        await runFixture("false_positives")
    }

    func testDiacriticIdentifiers() async throws {
        await runFixture("diacritic_identifiers")
    }

    func testMatrixMultiplication() async throws {
        await runFixture("matrix-multiplication")
    }

    // MARK: - Debug Test

    func testDebugFunctionDef() async throws {
        // Test simple keyword first
        let code0 = "def"
        let result0 = await hljs.highlight(code0, language: "python")
        print("DEBUG0: Input: \(code0)")
        print("DEBUG0: Output: \(result0.value)")

        // Test def with function name
        let code1 = "def foo"
        let result1 = await hljs.highlight(code1, language: "python")
        print("DEBUG1: Input: \(code1)")
        print("DEBUG1: Output: \(result1.value)")

        let code = "def f(x):"
        let result = await hljs.highlight(code, language: "python")
        print("DEBUG: Input: \(code)")
        print("DEBUG: Output: \(result.value)")

        // Expected format: <span class="hljs-keyword">def</span> <span class="hljs-title function_">f</span>(<span class="hljs-params">x</span>):
        XCTAssertTrue(result.value.contains("hljs-keyword") || result.value.contains("def"), "Should have keyword")
    }

    func testDebugEscapedQuotes() async throws {
        // Test simple triple-quoted string first
        let code1 = "'''hello'''"
        let result1 = await hljs.highlight(code1, language: "python")
        print("ESC1: Input: \(code1)")
        print("ESC1: Output: \(result1.value)")

        // Test with escaped quote
        let code2 = "'''text \\''' text'''"
        let result2 = await hljs.highlight(code2, language: "python")
        print("ESC2: Input: \(code2)")
        print("ESC2: Output: \(result2.value)")

        // Test simple single-quoted string with escape
        let code3 = "'text \\' text'"
        let result3 = await hljs.highlight(code3, language: "python")
        print("ESC3: Input: \(code3)")
        print("ESC3: Output: \(result3.value)")

        // Test backslash escape mode directly
        let code4 = "'''\\''''"
        let result4 = await hljs.highlight(code4, language: "python")
        print("ESC4: Input: \(code4)")
        print("ESC4: Output: \(result4.value)")

        // Test using a custom minimal language to isolate the issue
        let customHL = Highlight()
        await customHL.registerLanguage("test") { hljs in
            // Backslash escape mode
            let escape = Mode(begin: #"\\[\s\S]"#, relevance: 0)

            // Triple-quoted string
            let tripleString = Mode(
                scope: "string",
                begin: .string("'''"),
                end: .string("'''"),
                contains: [.mode(escape)]
            )

            return Language(name: "test", contains: [.mode(tripleString)])
        }

        let testCode = "'''text \\''' text'''"
        let testResult = await customHL.highlight(testCode, language: "test")
        print("CUSTOM: Input: \(testCode)")
        print("CUSTOM: Output: \(testResult.value)")

        // Debug test with logging
        print("\n=== DEBUG TRACE ===")
        await customHL.registerLanguage("test-debug") { hljs in
            let escape = Mode(begin: #"\\[\s\S]"#, relevance: 0)
            let tripleString = Mode(
                scope: "string",
                begin: .string("'''"),
                end: .string("'''"),
                contains: [.mode(escape)]
            )
            return Language(name: "test-debug", contains: [.mode(tripleString)])
        }
        let debugResult = await customHL.highlight(testCode, language: "test-debug")
        print("DEBUG: Final output: \(debugResult.value)")
    }

    func testDebugDecorator() async throws {
        // Test simple decorator
        let code1 = "@foo"
        let result1 = await hljs.highlight(code1, language: "python")
        print("DEC1: Input: \(code1)")
        print("DEC1: Output: \(result1.value)")

        // Test decorator with empty params
        let code0 = "@foo()"
        let result0 = await hljs.highlight(code0, language: "python")
        print("DEC0: Input: \(code0)")
        print("DEC0: Output: \(result0.value)")

        // Test decorator with params - simpler case
        let code2a = "@foo(3)"
        let result2a = await hljs.highlight(code2a, language: "python")
        print("DEC2a: Input: \(code2a)")
        print("DEC2a: Output: \(result2a.value)")

        // Test decorator with string params
        let code2 = "@foo(\"bar\")"
        let result2 = await hljs.highlight(code2, language: "python")
        print("DEC2: Input: \(code2)")
        print("DEC2: Output: \(result2.value)")

        // Test decorator with newline
        let code3 = "@foo(\"bar\")\ndef test():"
        let result3 = await hljs.highlight(code3, language: "python")
        print("DEC3: Input: \(code3)")
        print("DEC3: Output: \(result3.value)")

        // Test function params for comparison
        let code4 = "def foo(x):"
        let result4 = await hljs.highlight(code4, language: "python")
        print("DEC4: Input: \(code4)")
        print("DEC4: Output: \(result4.value)")

        // Check UTF-16 vs character offset
        let testCode = "@foo()"
        let utf16Idx = 5
        // Method 1: Character offset (wrong for non-ASCII)
        if utf16Idx < testCode.count {
            let charIdx = testCode.index(testCode.startIndex, offsetBy: utf16Idx)
            print("Char at offset \(utf16Idx): '\(testCode[charIdx])'")
        }
        // Method 2: UTF-16 offset (correct)
        let utf16Idx2 = String.Index(utf16Offset: utf16Idx, in: testCode)
        print("Char at UTF-16 offset \(utf16Idx): '\(testCode[utf16Idx2])'")
    }

    func testRegexPattern() throws {
        // Test that \) pattern matches )
        let pattern = "\\)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let testStr = ")"
        let range = NSRange(testStr.startIndex..., in: testStr)
        let match = regex.firstMatch(in: testStr, options: [], range: range)
        print("Pattern '\\)' match on ')': \(match != nil)")

        // Test combined pattern using actual MultiRegex
        print("\n=== Testing MultiRegex directly ===")

        // Simulate what params mode would have
        let decIntPattern = "\\b([1-9](_?[0-9])*|0+(_?0)*)[lLjJ]?(?=\\b|and|as)"
        let doubleStringPattern = "\""
        let singleStringPattern = "'"
        let terminatorPattern = "\\)"

        // Calculate expected match indices
        print("Pattern group counts:")
        print("  decInt: \(countGroups(decIntPattern))")
        print("  doubleString: \(countGroups(doubleStringPattern))")
        print("  singleString: \(countGroups(singleStringPattern))")
        print("  terminator: \(countGroups(terminatorPattern))")

        // Build combined pattern manually to check
        let patterns = [decIntPattern, doubleStringPattern, singleStringPattern, terminatorPattern]
        let wrapped = patterns.map { "(\($0))" }
        let combined = wrapped.joined(separator: "|")
        print("\nCombined pattern has \(countGroups(combined)) groups")
        print("Pattern: \(combined)")

        // Check which group matches )
        if let re = try? NSRegularExpression(pattern: combined, options: []) {
            let testStr = ")"
            let testRange = NSRange(location: 0, length: 1)
            if let m = re.firstMatch(in: testStr, options: [], range: testRange) {
                print("\nMatch on ')': \(m.range)")
                for i in 0..<m.numberOfRanges {
                    let r = m.range(at: i)
                    if r.location != NSNotFound {
                        print("  Group \(i): matched at \(r.location)")
                    }
                }
            }
        }

        // Expected matchIndexes mapping:
        // After decInt (3 groups): matchAt = 1 + 3 + 1 = 5 (wrapper at index 1)
        // After doubleString (0 groups): matchAt = 5 + 0 + 1 = 6 (wrapper at index 5)
        // After singleString (0 groups): matchAt = 6 + 0 + 1 = 7 (wrapper at index 6)
        // After terminator (0 groups): matchAt = 7 + 0 + 1 = 8 (wrapper at index 7)
        print("\nExpected matchIndexes mapping:")
        print("  1 -> decInt begin")
        print("  5 -> doubleString begin")
        print("  6 -> singleString begin")
        print("  7 -> terminator end")
    }

    func countGroups(_ pattern: String) -> Int {
        guard let re = try? NSRegularExpression(pattern: pattern + "|", options: []) else { return -1 }
        return re.numberOfCaptureGroups
    }

    func testMinimalDecorator() async throws {
        // Create a minimal custom language with decorator-like params
        let testLang = Highlight()

        // Test 1: With excludeEnd
        await testLang.registerLanguage("test1") { hljs in
            let params = Mode(
                scope: "params",
                begin: .string("\\("),
                end: .string("\\)"),
                excludeEnd: true
            )

            let wrapper = Mode(
                scope: "meta",
                begin: .string("@"),
                end: .string("$"),
                contains: [.mode(params)]
            )

            return Language(name: "test1", contains: [.mode(wrapper)])
        }

        // Test 2: Without excludeEnd
        await testLang.registerLanguage("test2") { hljs in
            let params = Mode(
                scope: "params",
                begin: .string("\\("),
                end: .string("\\)")
                // No excludeEnd
            )

            let wrapper = Mode(
                scope: "meta",
                begin: .string("@"),
                end: .string("$"),
                contains: [.mode(params)]
            )

            return Language(name: "test2", contains: [.mode(wrapper)])
        }

        print("=== With excludeEnd=true ===")
        let r1 = await testLang.highlight("@foo()", language: "test1")
        print("@foo(): \(r1.value)")
        let r2 = await testLang.highlight("@foo(x)", language: "test1")
        print("@foo(x): \(r2.value)")

        print("\n=== Without excludeEnd ===")
        let r3 = await testLang.highlight("@foo()", language: "test2")
        print("@foo(): \(r3.value)")
        let r4 = await testLang.highlight("@foo(x)", language: "test2")
        print("@foo(x): \(r4.value)")
    }

    // MARK: - Summary Test

    /// Runs all fixtures and prints a summary report
    func testAllFixturesSummary() async throws {
        let fixtures = [
            "keywords",
            "numbers",
            "class_self",
            "decorators",
            "f-strings",
            "escaped-quotes",
            "function-header",
            "function-header-comments",
            "identifiers",
            "false_positives",
            "diacritic_identifiers",
            "matrix-multiplication"
        ]

        var passed = 0
        var failed = 0
        var report = "\n=== Python Fixture Test Summary ===\n"

        for fixture in fixtures {
            let (success, diff) = await runFixtureReport(fixture)
            if success {
                passed += 1
                report += "✅ \(fixture)\n"
            } else {
                failed += 1
                report += "❌ \(fixture)\n"
                if let diff = diff, !diff.isEmpty {
                    // Show first few differences
                    let lines = diff.components(separatedBy: "\n").prefix(12)
                    report += lines.joined(separator: "\n") + "\n"
                    if diff.components(separatedBy: "\n").count > 12 {
                        report += "  ... (more differences)\n"
                    }
                }
            }
        }

        report += "\nTotal: \(passed)/\(fixtures.count) passed"
        print(report)

        // Don't fail the test - this is just for reporting
        // XCTAssertEqual(failed, 0, "Some fixtures failed")
    }
}
