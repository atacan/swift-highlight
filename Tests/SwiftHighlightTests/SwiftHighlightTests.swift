import XCTest
@testable import SwiftHighlight

final class SwiftHighlightTests: XCTestCase {
    func testBasicSetup() throws {
        let hljs = Highlight()
        XCTAssertNotNil(hljs)
    }

    func testRegisterPython() throws {
        let hljs = Highlight()
        hljs.registerPython()
        XCTAssertNotNil(hljs.getLanguage("python"))
    }

    func testListLanguages() throws {
        let hljs = Highlight()
        hljs.registerPython()
        let languages = hljs.listLanguages()
        XCTAssertTrue(languages.contains("python"))
    }

    func testSimplePlaintextLanguage() throws {
        let hljs = Highlight()

        // Register a minimal language
        hljs.registerLanguage("plaintest") { _ in
            let lang = Language(name: "PlainTest")
            lang.disableAutodetect = true
            return lang
        }

        let code = "hello"
        let result = hljs.highlight(code, language: "plaintest")

        XCTAssertEqual(result.language, "plaintest")
        XCTAssertEqual(result.value, "hello")
    }

    func testMinimalLanguage() throws {
        let hljs = Highlight()

        // Register a language with just one keyword
        hljs.registerLanguage("minimal") { _ in
            let lang = Language(name: "Minimal")
            lang.keywords = Keywords(keyword: ["if", "else"])
            return lang
        }

        let code = "if true"
        let result = hljs.highlight(code, language: "minimal")

        XCTAssertEqual(result.language, "minimal")
        XCTAssertFalse(result.value.isEmpty)
    }

    func testPythonRegistration() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let lang = hljs.getLanguage("python")
        XCTAssertNotNil(lang)
        XCTAssertEqual(lang?.name, "Python")
    }

    func testPythonSimpleCode() throws {
        let hljs = Highlight()
        hljs.registerPython()

        // Test very simple code
        let code = "x"
        let result = hljs.highlight(code, language: "python")

        XCTAssertEqual(result.language, "python")
        XCTAssertEqual(result.value, "x")
    }

    func testPythonKeyword() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("if True", language: "python")
        XCTAssertTrue(result.value.contains("hljs-keyword"), "Should contain keyword highlighting: \(result.value)")
    }

    func testPythonBuiltIn() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("print(x)", language: "python")
        XCTAssertTrue(result.value.contains("hljs-built_in"), "Should contain built-in highlighting: \(result.value)")
    }

    func testPythonLiteral() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("x = None", language: "python")
        XCTAssertTrue(result.value.contains("hljs-literal"), "Should contain literal highlighting: \(result.value)")
    }

    func testPythonString() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("'hello'", language: "python")
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain string highlighting: \(result.value)")
    }

    func testPythonNumber() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("42", language: "python")
        XCTAssertTrue(result.value.contains("hljs-number"), "Should contain number highlighting: \(result.value)")
    }

    func testPythonComment() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let result = hljs.highlight("# comment", language: "python")
        XCTAssertTrue(result.value.contains("hljs-comment"), "Should contain comment highlighting: \(result.value)")
    }

    func testHTMLEscaping() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let code = "<script>"
        let result = hljs.highlight(code, language: "python")
        XCTAssertFalse(result.value.contains("<script>"), "HTML should be escaped")
        XCTAssertTrue(result.value.contains("&lt;"), "Should contain escaped <")
    }

    func testComplexCode() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let code = """
        def hello():
            print('Hello, World!')
        """
        let result = hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertFalse(result.value.isEmpty)
        // With the function definition mode, 'def' might be captured as part of the function scope
        // rather than being highlighted as a standalone keyword
        XCTAssertTrue(result.value.contains("hljs-function") || result.value.contains("hljs-keyword"), "Should contain function or keyword 'def': \(result.value)")
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain string")
    }

    func testFStringWithSelfReference() throws {
        // This test verifies that .self references don't cause infinite recursion
        let hljs = Highlight()
        hljs.registerPython()

        let code = "f'{x + 1}'"
        let result = hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertFalse(result.value.isEmpty)
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain f-string: \(result.value)")
    }

    func testTripleQuoteDocstring() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let code = """
        def hello():
            \"\"\"This is a docstring.\"\"\"
            pass
        """
        let result = hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-string"), "Should contain docstring: \(result.value)")
    }

    func testDecorator() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let code = """
        @decorator
        def hello():
            pass
        """
        let result = hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-meta"), "Should contain decorator: \(result.value)")
    }

    func testClassDefinition() throws {
        let hljs = Highlight()
        hljs.registerPython()

        let code = "class MyClass:"
        let result = hljs.highlight(code, language: "python")

        XCTAssertFalse(result.illegal)
        XCTAssertTrue(result.value.contains("hljs-class") || result.value.contains("hljs-title"), "Should contain class: \(result.value)")
    }
}
