# SwiftHighlight - Swift Port of highlight.js

## Overview

SwiftHighlight is a pure Swift implementation of the highlight.js syntax highlighting library. It provides syntax highlighting for source code with no external dependencies beyond Foundation, making it suitable for any Apple platform or server-side Swift environment.

## Design Goals

1. **API Compatibility**: Similar API surface to highlight.js for familiarity
2. **Pure Swift**: No dependencies other than Foundation
3. **Cross-Platform**: Works on iOS, macOS, tvOS, watchOS, Linux, and Windows
4. **Type Safety**: Leverage Swift's type system for safer language definitions
5. **Performance**: Efficient regex compilation and matching
6. **Extensibility**: Easy to add new language definitions

## Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftHighlight                           │
├─────────────────────────────────────────────────────────────────┤
│  Public API                                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │  highlight() │ │highlightAuto()│ │ registerLanguage()      │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Core Engine                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │ ModeCompiler │ │   Parser     │ │      TokenEmitter        │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Rendering                                                       │
│  ┌──────────────┐ ┌──────────────┐                              │
│  │ HTMLRenderer │ │ TokenTree    │                              │
│  └──────────────┘ └──────────────┘                              │
├─────────────────────────────────────────────────────────────────┤
│  Languages                                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │    Python    │ │    Swift     │ │         ...              │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Public API Design

### Main Entry Point

```swift
public final class Highlight {
    /// Shared instance with default configuration
    public static let shared = Highlight()

    /// Creates a new instance for isolated use
    public static func newInstance() -> Highlight

    /// Configuration options
    public var options: HighlightOptions

    /// Highlights code with a specific language
    public func highlight(
        _ code: String,
        language: String,
        ignoreIllegals: Bool = true
    ) -> HighlightResult

    /// Highlights code with automatic language detection
    public func highlightAuto(
        _ code: String,
        languageSubset: [String]? = nil
    ) -> AutoHighlightResult

    /// Registers a language definition
    public func registerLanguage(
        _ name: String,
        definition: @escaping (Highlight) -> Language
    )

    /// Removes a registered language
    public func unregisterLanguage(_ name: String)

    /// Returns list of registered language names
    public func listLanguages() -> [String]

    /// Gets a language by name or alias
    public func getLanguage(_ name: String) -> Language?

    /// Registers aliases for a language
    public func registerAliases(_ aliases: [String], languageName: String)

    /// Library version
    public static let version = "1.0.0"
}
```

### Result Types

```swift
public struct HighlightResult {
    /// The language that was used
    public let language: String

    /// The highlighted HTML string
    public let value: String

    /// Relevance score (for auto-detection ranking)
    public let relevance: Int

    /// Whether illegal syntax was encountered
    public let illegal: Bool

    /// The original source code
    public let code: String
}

public struct AutoHighlightResult {
    /// The primary result
    public let result: HighlightResult

    /// The second-best match (if available)
    public let secondBest: HighlightResult?

    // Convenience accessors
    public var language: String { result.language }
    public var value: String { result.value }
    public var relevance: Int { result.relevance }
}
```

### Configuration

```swift
public struct HighlightOptions {
    /// CSS class prefix (default: "hljs-")
    public var classPrefix: String = "hljs-"

    /// Languages to consider for auto-detection (nil = all)
    public var languages: [String]? = nil

    public init()
}
```

## Core Types

### Language Definition

```swift
public struct Language {
    /// Display name
    public var name: String

    /// Alternative names for this language
    public var aliases: [String]?

    /// Whether to disable auto-detection
    public var disableAutodetect: Bool

    /// Case insensitive matching
    public var caseInsensitive: Bool

    /// Enable Unicode regex support
    public var unicodeRegex: Bool

    /// Keywords definition
    public var keywords: Keywords?

    /// Illegal patterns (cause highlighting to abort)
    public var illegal: RegexPattern?

    /// Child modes
    public var contains: [Mode]

    /// Class name aliases
    public var classNameAliases: [String: String]

    public init(name: String)
}
```

### Mode Definition

```swift
public struct Mode {
    /// Scope name for CSS class
    public var scope: String?

    /// Pattern to match the beginning of this mode
    public var begin: RegexPattern?

    /// Pattern to match the end of this mode
    public var end: RegexPattern?

    /// Keywords for this mode
    public var keywords: Keywords?

    /// Illegal patterns within this mode
    public var illegal: RegexPattern?

    /// Child modes
    public var contains: [ModeReference]

    /// Mode variants (alternative patterns)
    public var variants: [Mode]?

    /// Relevance score for this mode
    public var relevance: Int?

    /// Exclude the begin match from highlighting
    public var excludeBegin: Bool

    /// Exclude the end match from highlighting
    public var excludeEnd: Bool

    /// Return to parent after begin match
    public var returnBegin: Bool

    /// Return to parent after end match
    public var returnEnd: Bool

    /// End when parent ends
    public var endsWithParent: Bool

    /// End parent when this ends
    public var endsParent: Bool

    /// Skip this mode (used for sub-language parsing)
    public var skip: Bool

    /// Sub-language to use for content
    public var subLanguage: SubLanguage?

    /// Match pattern (shorthand for begin-only mode)
    public var match: RegexPattern?

    /// Begin scope for multi-class matching
    public var beginScope: Scope?

    /// End scope for multi-class matching
    public var endScope: Scope?

    /// Mode that starts after this mode ends
    public var starts: Mode?

    /// Callbacks
    public var onBegin: ModeCallback?
    public var onEnd: ModeCallback?

    public init()
}

/// Reference to another mode (for 'self' references)
public enum ModeReference {
    case mode(Mode)
    case `self`
}

/// Sub-language specification
public enum SubLanguage {
    case single(String)
    case multiple([String])
}

/// Scope for multi-class matching
public enum Scope {
    case simple(String)
    case indexed([Int: String])
}
```

### Keywords

```swift
public struct Keywords {
    /// Custom keyword pattern (default: \w+)
    public var pattern: RegexPattern?

    /// Keywords by category
    public var keyword: [String]?
    public var builtIn: [String]?
    public var literal: [String]?
    public var type: [String]?

    /// Custom categories
    public var custom: [String: [String]]

    public init()
}
```

### Regex Pattern

```swift
/// Pattern that can be a string or regex
public enum RegexPattern {
    case string(String)
    case regex(NSRegularExpression)

    /// Source string representation
    var source: String { get }
}

extension RegexPattern: ExpressibleByStringLiteral {
    public init(stringLiteral value: String)
}
```

## Common Modes (Built-in Helpers)

```swift
extension Highlight {
    // Common regex patterns
    public static let identifierRE = "[a-zA-Z]\\w*"
    public static let underscoreIdentifierRE = "[a-zA-Z_]\\w*"
    public static let numberRE = "\\b\\d+(\\.\\d+)?"
    public static let cNumberRE = "(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)"
    public static let binaryNumberRE = "\\b(0b[01]+)"

    // Common modes
    public static var backslashEscape: Mode { get }
    public static var aposStringMode: Mode { get }
    public static var quoteStringMode: Mode { get }
    public static var cLineCommentMode: Mode { get }
    public static var cBlockCommentMode: Mode { get }
    public static var hashCommentMode: Mode { get }
    public static var numberMode: Mode { get }
    public static var cNumberMode: Mode { get }
    public static var binaryNumberMode: Mode { get }

    /// Creates a comment mode
    public static func comment(
        begin: RegexPattern,
        end: RegexPattern
    ) -> Mode

    /// Creates a shebang mode
    public static func shebang(binary: String? = nil) -> Mode
}
```

## Regex Utilities

```swift
public enum Regex {
    /// Concatenates patterns
    public static func concat(_ patterns: RegexPattern...) -> String

    /// Creates an alternation (a|b|c)
    public static func either(_ patterns: RegexPattern...) -> String

    /// Creates a lookahead assertion
    public static func lookahead(_ pattern: RegexPattern) -> String

    /// Makes a pattern optional
    public static func optional(_ pattern: RegexPattern) -> String

    /// Makes a pattern repeat any number of times
    public static func anyNumberOfTimes(_ pattern: RegexPattern) -> String

    /// Escapes regex special characters
    public static func escape(_ value: String) -> String
}
```

## Internal Components

### Compiled Language

```swift
internal struct CompiledLanguage {
    let name: String
    let caseInsensitive: Bool
    let unicodeRegex: Bool
    let keywords: CompiledKeywords?
    let illegal: NSRegularExpression?
    let matcher: ResumableMultiRegex
    let classNameAliases: [String: String]
}
```

### Mode Compiler

```swift
internal final class ModeCompiler {
    /// Compiles a language definition into executable form
    static func compile(_ language: Language) -> CompiledLanguage
}
```

### Multi-Regex Matcher

```swift
internal final class ResumableMultiRegex {
    /// Adds a rule to the matcher
    func addRule(_ pattern: NSRegularExpression, type: MatchType, rule: CompiledMode?)

    /// Compiles all rules into a single regex
    func compile()

    /// Executes the match at the given position
    func exec(_ string: String, at index: String.Index) -> Match?

    /// Resets to consider all rules
    func considerAll()
}
```

### Token Tree

```swift
internal final class TokenTree {
    /// Root node
    var root: Node { get }

    /// Adds text to current node
    func addText(_ text: String)

    /// Opens a new scope
    func openNode(_ scope: String)

    /// Closes current scope
    func closeNode()

    /// Finalizes the tree
    func finalize()
}
```

### HTML Renderer

```swift
internal struct HTMLRenderer {
    /// Renders a token tree to HTML
    static func render(_ tree: TokenTree, options: HighlightOptions) -> String
}
```

## Implementation Plan

### Phase 1: Core Infrastructure
1. RegexPattern type and utilities
2. Mode and Language types
3. Keywords compilation
4. Basic mode compiler

### Phase 2: Parsing Engine
1. ResumableMultiRegex implementation
2. Token tree and emitter
3. Main parsing loop
4. Keyword processing

### Phase 3: Rendering
1. HTML renderer
2. Scope to CSS class conversion
3. HTML escaping

### Phase 4: Public API
1. Highlight class
2. Options handling
3. Language registry
4. Auto-detection

### Phase 5: Python Language
1. Port Python language definition
2. All string variants (f-strings, raw strings, etc.)
3. Number formats
4. Keywords and builtins

### Phase 6: Testing
1. Port markup tests from highlight.js
2. Unit tests for components
3. Integration tests

## Test Strategy

### Markup Tests
The JavaScript library uses a simple test format:
- `*.txt` - Input source code
- `*.expect.txt` - Expected HTML output

We will port these tests directly, loading the files and comparing output.

```swift
func testPythonKeywords() throws {
    let input = try loadFixture("python/keywords.txt")
    let expected = try loadFixture("python/keywords.expect.txt")

    let result = Highlight.shared.highlight(input, language: "python")
    XCTAssertEqual(result.value, expected)
}
```

### Unit Tests
- Regex utilities
- Keyword compilation
- Mode compilation
- Token tree operations
- HTML rendering

## File Structure

```
Sources/
  SwiftHighlight/
    SwiftHighlight.swift          # Main entry point
    Types/
      Language.swift              # Language definition type
      Mode.swift                  # Mode definition type
      Keywords.swift              # Keywords type
      RegexPattern.swift          # Regex pattern type
      Results.swift               # Result types
      Options.swift               # Configuration options
    Core/
      ModeCompiler.swift          # Compiles language definitions
      MultiRegex.swift            # Multi-pattern regex matcher
      TokenTree.swift             # Token tree for output
      HTMLRenderer.swift          # Renders to HTML
      RegexUtils.swift            # Regex helper functions
      Utils.swift                 # General utilities
    Modes/
      CommonModes.swift           # Built-in mode templates
    Languages/
      Python.swift                # Python language definition
Tests/
  SwiftHighlightTests/
    HighlightTests.swift          # Main API tests
    ModeCompilerTests.swift       # Compiler tests
    MarkupTests.swift             # Ported markup tests
    Fixtures/
      python/                     # Python test fixtures
```

## Notes

### Differences from JavaScript

1. **No DOM APIs**: Swift version only provides string-based highlighting
2. **No Plugins**: Plugin system may be added later if needed
3. **Static Registration**: Languages can be registered at compile time
4. **Value Types**: Extensive use of structs for immutability

### Unicode Support

Swift's String type handles Unicode natively, but NSRegularExpression requires explicit Unicode flags. The `unicodeRegex` option on languages enables this.

### Performance Considerations

1. Compile language definitions once and cache
2. Use String.Index for efficient string traversal
3. Avoid unnecessary string copies
4. Consider lazy compilation of unused language features
