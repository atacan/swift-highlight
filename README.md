# SwiftHighlight

A pure Swift port of [highlight.js](https://highlightjs.org/) for syntax highlighting. No dependencies beyond Foundation.

## Installation

```swift
.package(url: "https://github.com/user/swift-highlight.git", from: "1.0.0")
```

## Usage

### HTML Output (Default)

```swift
import SwiftHighlight

let hljs = Highlight()
await hljs.registerPython()

let result: HighlightResult<String> = await hljs.highlight("def hello():", language: "python")
let html: String = result.value
// <span class="hljs-keyword">def</span> <span class="hljs-title function_">hello</span>():
```

### AttributedString (SwiftUI)

```swift
import SwiftUI

struct CodeView: View {
    @State private var highlighted: AttributedString = ""
    let code: String

    var body: some View {
        Text(highlighted)
            .font(.system(.body, design: .monospaced))
            .task {
                let hljs = Highlight()
                await hljs.registerPython()
                let renderer = AttributedStringRenderer(theme: .dark)
                let result = await hljs.highlight(code, language: "python", renderer: renderer)
                highlighted = result.value
            }
    }
}
```

### NSAttributedString (AppKit/UIKit)

```swift
let hljs = Highlight()
await hljs.registerPython()
let renderer = NSAttributedStringRenderer(theme: .dark)
let result = await hljs.highlight(code, language: "python", renderer: renderer)

await MainActor.run {
    textView.attributedText = result.value  // UIKit
    textView.textStorage?.setAttributedString(result.value)  // AppKit
}
```

### ANSI Terminal Output

```swift
let hljs = Highlight()
await hljs.registerPython()
let renderer = ANSIRenderer(theme: .dark)
let result = await hljs.highlight(code, language: "python", renderer: renderer)
print(result.value)  // Colored terminal output
```

### Auto-Detection

```swift
let hljs = Highlight()
await hljs.registerPython()
await hljs.registerJSON()

let result = await hljs.highlightAuto(code)
let language: String = result.language
let html: String = result.value
```

### Custom Rendering

Access the token tree directly for custom output formats:

```swift
let hljs = Highlight()
await hljs.registerPython()

let parseResult = await hljs.parse(code, language: "python")
let tree: TokenTree = parseResult.tokenTree

func render(_ node: TokenNode) -> String {
    switch node {
    case .text(let text):
        return text
    case .scope(let scopeNode):
        let content = scopeNode.children.map(render).joined()
        if let scope = scopeNode.scope {
            return "[\(scope): \(content)]"
        }
        return content
    }
}

let output: String = render(.scope(tree.root))
```

### Custom Themes

```swift
let theme = AttributedStringTheme(styles: [
    "keyword": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF0000")!, textStyle: .bold),
    "string": ScopeStyle(foregroundColor: ThemeColor(hex: "#00FF00")!),
    "comment": ScopeStyle(foregroundColor: ThemeColor(hex: "#888888")!, textStyle: .italic),
])
let renderer = AttributedStringRenderer(theme: theme)

let hljs = Highlight()
await hljs.registerPython()
let result = await hljs.highlight(code, language: "python", renderer: renderer)
```

## Running the Example

```bash
cd Examples
swift run
```

This prints HTML, colored ANSI terminal output, and the token tree structure.

## Supported Languages

- Python
- JSON

## Attribution

SwiftHighlight is a Swift port of [highlight.js](https://github.com/highlightjs/highlight.js) by Ivan Sagalaev and contributors.

## License

BSD 3-Clause License - see [LICENSE](LICENSE) file for details.

This project is based on highlight.js, which is also licensed under the BSD 3-Clause License.
