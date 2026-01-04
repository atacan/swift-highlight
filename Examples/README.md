# SwiftHighlight Examples

This directory contains example code demonstrating how to use SwiftHighlight in different contexts.

## Examples Included

### 1. Command-Line Demo (`HighlightDemo`)

A simple command-line executable that demonstrates:
- HTML output generation
- ANSI terminal output with colors
- Token tree parsing for custom rendering

**Run it:**
```bash
swift run HighlightDemo
```

### 2. SwiftUI Views (`HighlightDemoViews`)

A library containing reusable SwiftUI components for displaying syntax-highlighted code with live previews.

**Components:**
- `CodeView`: Basic syntax-highlighted code display
- `MultiLanguageCodeView`: Interactive demo with language selection

**Use Xcode Previews:**
1. Open the package in Xcode
2. Navigate to `Sources/HighlightDemoViews/SwiftUIExample.swift`
3. Enable the preview canvas (⌥⌘↵)
4. See live previews of the syntax highlighting

**Import in your SwiftUI app:**
```swift
import HighlightDemoViews

struct ContentView: View {
    var body: some View {
        CodeView(
            code: "print('Hello, World!')",
            language: "python"
        )
    }
}
```

## Using the Async API

SwiftHighlight uses Swift actors for thread safety. All methods must be called with `await`:

```swift
let hljs = Highlight()
await hljs.registerPython()

// Parse only
let parseResult = await hljs.parse(code, language: "python")

// Highlight with default HTML renderer
let htmlResult = await hljs.highlight(code, language: "python")

// Highlight with custom renderer
let renderer = AttributedStringRenderer()
let result = await hljs.highlight(code, language: "python", renderer: renderer)
```

## Building

Build all examples:
```bash
swift build
```

Build specific target:
```bash
swift build --target HighlightDemo
swift build --target HighlightDemoViews
```
