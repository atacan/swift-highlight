import SwiftHighlight


let code = """
    def fibonacci(n):
        \"\"\"Calculate the nth Fibonacci number.\"\"\"
        if n <= 1:
            return n
        return fibonacci(n - 1) + fibonacci(n - 2)

    # Print first 10 Fibonacci numbers
    for i in range(10):
        print(f"fib({i}) = {fibonacci(i)}")
    """

let hljs = Highlight()
await hljs.registerPython()

// HTML Output
print("=" * 60)
print("HTML OUTPUT")
print("=" * 60)
let htmlResult: HighlightResult<String> = await hljs.highlight(code, language: "python")
print(htmlResult.value)
print()

// ANSI Terminal Output
print("=" * 60)
print("ANSI TERMINAL OUTPUT")
print("=" * 60)
let ansiRenderer = ANSIRenderer(theme: .dark)
let ansiResult: HighlightResult<String> = await hljs.highlight(code, language: "python", renderer: ansiRenderer)
print(ansiResult.value)
print()

// Token Tree (for custom rendering)
print("=" * 60)
print("TOKEN TREE STRUCTURE")
print("=" * 60)
let parseResult: ParseResult = await hljs.parse(code, language: "python")
printTree(parseResult.tokenTree.root, indent: 0)

func printTree(_ node: ScopeNode, indent: Int) {
    let prefix = String(repeating: "  ", count: indent)
    if let scope = node.scope {
        print("\(prefix)[\(scope)]")
    }
    for child in node.children {
        switch child {
        case .text(let text):
            let escaped = text.replacingOccurrences(of: "\n", with: "\\n")
            let truncated = escaped.count > 40 ? String(escaped.prefix(40)) + "..." : escaped
            print("\(prefix)  \"\(truncated)\"")
        case .scope(let childNode):
            printTree(childNode, indent: indent + 1)
        }
    }
}

func * (lhs: String, rhs: Int) -> String {
    String(repeating: lhs, count: rhs)
}
