import XCTest
@testable import SwiftHighlight

/// Tests Diff highlighting against the original highlight.js test fixtures
final class DiffFixtureTests: XCTestCase {

    var hljs: Highlight!

    override func setUp() async throws {
        try await super.setUp()
        hljs = Highlight()
        await hljs.registerDiff()
    }

    // MARK: - Fixture Test Runner

    /// Runs a fixture test by comparing SwiftHighlight output to expected output
    private func runFixture(_ name: String, file: StaticString = #file, line: UInt = #line) async {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/diff"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/diff") else {
            XCTFail("Could not find fixture files for '\(name)'", file: file, line: line)
            return
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            XCTFail("Could not read fixture files for '\(name)'", file: file, line: line)
            return
        }

        let result = await hljs.highlight(input, language: "diff")
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

    // MARK: - Individual Fixture Tests

    func testComments() async throws {
        await runFixture("comments")
    }

    func testGitFormatPatch() async throws {
        await runFixture("git-format-patch")
    }
}
