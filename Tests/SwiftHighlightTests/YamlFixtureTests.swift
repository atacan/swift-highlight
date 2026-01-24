import XCTest
@testable import SwiftHighlight

/// Tests YAML highlighting against the original highlight.js test fixtures
final class YamlFixtureTests: XCTestCase {

    var hljs: Highlight!

    override func setUp() async throws {
        try await super.setUp()
        hljs = Highlight()
        await hljs.registerYaml()
    }

    // MARK: - Fixture Test Runner

    /// Runs a fixture test by comparing SwiftHighlight output to expected output
    private func runFixture(_ name: String, file: StaticString = #file, line: UInt = #line) async {
        guard let inputURL = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/yaml"),
              let expectedURL = Bundle.module.url(forResource: "\(name).expect", withExtension: "txt", subdirectory: "Fixtures/yaml") else {
            XCTFail("Could not find fixture files for '\(name)'", file: file, line: line)
            return
        }

        guard let input = try? String(contentsOf: inputURL, encoding: .utf8),
              let expected = try? String(contentsOf: expectedURL, encoding: .utf8) else {
            XCTFail("Could not read fixture files for '\(name)'", file: file, line: line)
            return
        }

        let result = await hljs.highlight(input, language: "yaml")
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

    func testBlock() async throws {
        await runFixture("block")
    }

    func testInline() async throws {
        await runFixture("inline")
    }

    func testKeys() async throws {
        await runFixture("keys")
    }

    func testNumbers() async throws {
        await runFixture("numbers")
    }

    func testSpecialChars() async throws {
        await runFixture("special_chars")
    }

    func testString() async throws {
        await runFixture("string")
    }

    func testTag() async throws {
        await runFixture("tag")
    }
}
