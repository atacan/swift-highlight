import XCTest
@testable import SwiftHighlight

final class SwiftHighlightTests: XCTestCase {
    func testBasicSetup() async throws {
        let hljs = Highlight()
        XCTAssertNotNil(hljs)
    }

    func testRegisterPython() async throws {
        let hljs = Highlight()
        await hljs.registerPython()
        let lang = await hljs.getLanguage("python")
        XCTAssertNotNil(lang)
    }

    func testListLanguages() async throws {
        let hljs = Highlight()
        await hljs.registerPython()
        let languages = await hljs.listLanguages()
        XCTAssertTrue(languages.contains("python"))
    }

    func testSimplePlaintextLanguage() async throws {
        let hljs = Highlight()

        // Register a minimal language
        await hljs.registerLanguage("plaintest") { _ in
            Language(name: "PlainTest", disableAutodetect: true)
        }

        let code = "hello"
        let result = await hljs.highlight(code, language: "plaintest")

        XCTAssertEqual(result.language, "plaintest")
        XCTAssertEqual(result.value, "hello")
    }

    func testMinimalLanguage() async throws {
        let hljs = Highlight()

        // Register a language with just one keyword
        await hljs.registerLanguage("minimal") { _ in
            Language(name: "Minimal", keywords: Keywords(keyword: ["if", "else"]))
        }

        let code = "if true"
        let result = await hljs.highlight(code, language: "minimal")

        XCTAssertEqual(result.language, "minimal")
        XCTAssertFalse(result.value.isEmpty)
    }

    func testPythonRegistration() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let lang = await hljs.getLanguage("python")
        XCTAssertNotNil(lang)
        XCTAssertEqual(lang?.name, "Python")
    }

    func testPythonSimpleCode() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        // Test very simple code
        let code = "x"
        let result = await hljs.highlight(code, language: "python")

        XCTAssertEqual(result.language, "python")
        XCTAssertEqual(result.value, "x")
    }

    func testPythonKeyword() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("if True", language: "python")
        XCTAssertTrue(result.value.contains("hljs-keyword"), "Should contain keyword highlighting: \(result.value)")
    }

    func testPythonBuiltIn() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("print(x)", language: "python")
        XCTAssertTrue(result.value.contains("hljs-built_in"), "Should contain built-in highlighting: \(result.value)")
    }

    func testPythonLiteral() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("x = None", language: "python")
        XCTAssertTrue(result.value.contains("hljs-literal"), "Should contain literal highlighting: \(result.value)")
    }

    func testPythonString() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("'hello'", language: "python")
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain string highlighting: \(result.value)")
    }

    func testPythonNumber() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("42", language: "python")
        XCTAssertTrue(result.value.contains("hljs-number"), "Should contain number highlighting: \(result.value)")
    }

    func testPythonComment() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let result = await hljs.highlight("# comment", language: "python")
        XCTAssertTrue(result.value.contains("hljs-comment"), "Should contain comment highlighting: \(result.value)")
    }

    func testLargeInputDoesNotHitIterationGuard() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        // 150k single-token matches: exceeds the 100000-iteration guard
        // even though parsing is progressing normally.
        let code = String(repeating: "# c\n", count: 150_000)
        let result = await hljs.highlight(code, language: "python")

        XCTAssertNil(result.errorRaised, "Large but valid input should not error: \(String(describing: result.errorRaised))")
        XCTAssertFalse(result.value.isEmpty, "Large valid input should produce output")
    }

    func testGenuineInfiniteLoopIsCaught() async throws {
        let hljs = Highlight()

        // A mode whose begin and end patterns both match zero-width:
        // push/pop cycles forever without consuming input; the parser
        // should detect the stall and throw .infiniteLoop (surfaced via
        // errorRaised), not hang forever.
        await hljs.registerLanguage("staller") { _ in
            Language(
                name: "Staller",
                disableAutodetect: true,
                contains: [
                    .mode(Mode(scope: "stall", begin: "(?=.)", end: "^"))
                ]
            )
        }

        let result = await hljs.highlight("abc", language: "staller")

        guard case .infiniteLoop = (result.errorRaised as? HighlightError) ?? .unknownLanguage("") else {
            XCTFail("Expected .infiniteLoop, got: \(String(describing: result.errorRaised))")
            return
        }
        // Error fallback should still produce plain-text output
        XCTAssertTrue(result.value.contains("abc"), "Fallback output should contain source text: \(result.value)")
    }

    func testHTMLEscaping() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let code = "<script>"
        let result = await hljs.highlight(code, language: "python")
        XCTAssertFalse(result.value.contains("<script>"), "HTML should be escaped")
        XCTAssertTrue(result.value.contains("&lt;"), "Should contain escaped <")
    }

    func testComplexCode() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let code = """
        def hello():
            print('Hello, World!')
        """
        let result = await hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertFalse(result.value.isEmpty)
        // With the function definition mode, 'def' might be captured as part of the function scope
        // rather than being highlighted as a standalone keyword
        XCTAssertTrue(result.value.contains("hljs-function") || result.value.contains("hljs-keyword"), "Should contain function or keyword 'def': \(result.value)")
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain string")
    }

    func testFStringWithSelfReference() async throws {
        // This test verifies that .self references don't cause infinite recursion
        let hljs = Highlight()
        await hljs.registerPython()

        let code = "f'{x + 1}'"
        let result = await hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertFalse(result.value.isEmpty)
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain f-string: \(result.value)")
    }

    func testTripleQuoteDocstring() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let code = """
        def hello():
            \"\"\"This is a docstring.\"\"\"
            pass
        """
        let result = await hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain docstring: \(result.value)")
    }

    func testDecorator() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let code = """
        @decorator
        def hello():
            pass
        """
        let result = await hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-meta"), "Should contain decorator: \(result.value)")
    }

    func testClassDefinition() async throws {
        let hljs = Highlight()
        await hljs.registerPython()

        let code = "class MyClass:"
        let result = await hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-class") || result.value.contains("hljs-title"), "Should contain class: \(result.value)")
    }
}
