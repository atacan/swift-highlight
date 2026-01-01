import XCTest
@testable import SwiftHighlight

/// Tests JSON highlighting against the original highlight.js test fixtures
final class JSONFixtureTests: XCTestCase {

    var hljs: Highlight!

    override func setUp() {
        super.setUp()
        hljs = Highlight()
        hljs.registerJSON()
    }

    // MARK: - Fixture Test Runner

    /// Runs a fixture test by comparing SwiftHighlight output to expected output
    private func runFixture(_ name: String, file: StaticString = #file, line: UInt = #line) {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/json"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/json") else {
            XCTFail("Could not find fixture files for '\(name)'", file: file, line: line)
            return
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            XCTFail("Could not read fixture files for '\(name)'", file: file, line: line)
            return
        }

        let result = hljs.highlight(input, language: "json")
        let actual = result.value

        // Compare the outputs
        if actual != expected {
            // Find first difference for better error message
            let actualLines = actual.components(separatedBy: "\n")
            let expectedLines = expected.components(separatedBy: "\n")

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
    private func runFixtureReport(_ name: String) -> (passed: Bool, diff: String?) {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/json"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/json") else {
            return (false, "Could not find fixture files")
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            return (false, "Could not read fixture files")
        }

        let result = hljs.highlight(input, language: "json")
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

    func testComments() throws {
        runFixture("comments")
    }

    func testJSON5() throws {
        runFixture("json5")
    }

    // MARK: - Summary Test

    /// Runs all fixtures and prints a summary report
    func testAllFixturesSummary() throws {
        let fixtures = [
            "comments",
            "json5"
        ]

        var passed = 0
        var failed = 0
        var report = "\n=== JSON Fixture Test Summary ===\n"

        for fixture in fixtures {
            let (success, diff) = runFixtureReport(fixture)
            if success {
                passed += 1
                report += "PASS \(fixture)\n"
            } else {
                failed += 1
                report += "FAIL \(fixture)\n"
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
