import XCTest
@testable import SwiftHighlight

/// Tests Swift highlighting against the original highlight.js test fixtures
final class SwiftFixtureTests: XCTestCase {

    var hljs: Highlight!

    override func setUp() async throws {
        try await super.setUp()
        hljs = Highlight()
        await hljs.registerSwift()
    }

    // MARK: - Fixture Test Runner

    /// Runs a fixture test by comparing SwiftHighlight output to expected output
    private func runFixture(_ name: String, file: StaticString = #file, line: UInt = #line) async {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/swift"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/swift") else {
            XCTFail("Could not find fixture files for '\(name)'", file: file, line: line)
            return
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            XCTFail("Could not read fixture files for '\(name)'", file: file, line: line)
            return
        }

        let result = await hljs.highlight(input, language: "swift")
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
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/swift"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/swift") else {
            return (false, "Could not find fixture files")
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            return (false, "Could not read fixture files")
        }

        let result = await hljs.highlight(input, language: "swift")
        let actual = result.value

        if actual == expected {
            return (true, nil)
        }

        // Generate diff
        let actualLines = actual.components(separatedBy: "\n")
        let expectedLines = expected.components(separatedBy: "\n")
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

    func testAttributes() async throws {
        await runFixture("attributes")
    }

    func testAvailability() async throws {
        await runFixture("availability")
    }

    func testClassFuncVar() async throws {
        await runFixture("class-func-var")
    }

    func testDistributedActorRuntime() async throws {
        await runFixture("distributed-actor-runtime")
    }

    func testFunctions() async throws {
        await runFixture("functions")
    }

    func testIdentifiers() async throws {
        await runFixture("identifiers")
    }

    func testKeywords() async throws {
        await runFixture("keywords")
    }

    func testMacro() async throws {
        await runFixture("macro")
    }

    func testNumbers() async throws {
        await runFixture("numbers")
    }

    func testOperatorDeclarations() async throws {
        await runFixture("operator-declarations")
    }

    func testOperators() async throws {
        await runFixture("operators")
    }

    func testOwnership() async throws {
        await runFixture("ownership")
    }

    func testParameterpack() async throws {
        await runFixture("parameterpack")
    }

    func testPrecedencegroup() async throws {
        await runFixture("precedencegroup")
    }

    func testRegex() async throws {
        await runFixture("regex")
    }

    func testStrings() async throws {
        await runFixture("strings")
    }

    func testSwiftUI() async throws {
        await runFixture("swiftui")
    }

    func testTuples() async throws {
        await runFixture("tuples")
    }

    func testTypeDefinition() async throws {
        await runFixture("type-definition")
    }

    func testTypes() async throws {
        await runFixture("types")
    }

    // MARK: - Summary Test

    /// Runs all fixtures and prints a summary report
    func testAllFixturesSummary() async throws {
        let fixtures = [
            "attributes",
            "availability",
            "class-func-var",
            "distributed-actor-runtime",
            "functions",
            "identifiers",
            "keywords",
            "macro",
            "numbers",
            "operator-declarations",
            "operators",
            "ownership",
            "parameterpack",
            "precedencegroup",
            "regex",
            "strings",
            "swiftui",
            "tuples",
            "type-definition",
            "types"
        ]

        var passed = 0
        var failed = 0
        var report = "\n=== Swift Fixture Test Summary ===\n"

        for fixture in fixtures {
            let (success, diff) = await runFixtureReport(fixture)
            if success {
                passed += 1
                report += "  \(fixture)\n"
            } else {
                failed += 1
                report += "  \(fixture)\n"
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
    }
}
