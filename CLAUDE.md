# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftHighlight is a pure Swift port of highlight.js - a syntax highlighting library. It has no dependencies beyond Foundation and works on all Apple platforms and server-side Swift.

## Build Commands

```bash
# Build
swift build

# Run tests
swift test

# Run a single test
swift test --filter testPythonKeyword

# Run tests matching a pattern
swift test --filter Python
```

## Architecture

### Core Flow

```
Code → ModeCompiler → CompiledMode → Parser (in SwiftHighlight.swift) → TokenTree → HTML
```

### Key Components

**SwiftHighlight.swift** - Main entry point containing:
- `Highlight` class with `highlight()` and `highlightAuto()` methods
- The main parsing loop (`_highlight()`) that processes code against compiled modes
- Language registration and caching

**ModeCompiler.swift** - Compiles `Mode`/`Language` definitions into `CompiledMode`:
- Handles `.self` references (modes that can contain themselves) with cycle detection
- Expands variants into concrete modes
- Builds `ResumableMultiRegex` matchers for efficient pattern matching

**MultiRegex.swift** - Pattern matching engine:
- `MultiRegex`: Combines multiple patterns into one alternation
- `ResumableMultiRegex`: Supports skipping previously matched patterns (for mode precedence)

**TokenTree.swift** - Builds output structure:
- `TokenEmitter`: Accumulates highlighted tokens with proper nesting
- Handles scope opening/closing and text accumulation
- Renders final HTML with CSS classes

### Type Hierarchy

```
Language (defines a language)
  └── contains: [ModeReference]
        └── Mode (defines a highlighting rule)
              ├── begin/end patterns
              ├── keywords
              ├── contains: [ModeReference] (child modes)
              └── variants: [Mode]

ModeReference = .mode(Mode) | .self
```

### Adding a New Language

1. Create `Sources/SwiftHighlight/Languages/YourLang.swift`
2. Define a function `yourLangLanguage(_ hljs: Highlight) -> Language`
3. Add extension to `Highlight` with `registerYourLang()` method
4. Use common modes from `Highlight` (e.g., `Highlight.cLineCommentMode`, `Highlight.quoteStringMode`)
5. Add the language to `scripts/sync-fixtures.sh` LANGUAGES array
6. Run `./scripts/sync-fixtures.sh` to copy test fixtures from highlight.js submodule

Example pattern from Python.swift:
```swift
public func pythonLanguage(_ hljs: Highlight) -> Language {
    let lang = Language(name: "Python")
    lang.keywords = Keywords(keyword: ["if", "else", ...], builtIn: ["print", ...])
    lang.contains = [.mode(stringMode), .mode(commentMode), ...]
    return lang
}
```

## Important Implementation Details

### `.self` Reference Handling

Modes can reference themselves via `.self` in `contains` (e.g., f-strings containing expressions). The `ModeCompiler` prevents infinite recursion by:
- Tracking modes currently being compiled (`compilingModes` set)
- Using depth limits (`maxDepth = 50`)
- Creating shallow copies without recursive `.self` expansion

### `@unchecked Sendable`

Classes use `@unchecked Sendable` because they have mutable properties for the builder-style API. The safety contract: don't mutate after passing to another thread.

### UTF-16 String Handling

`NSRegularExpression` uses UTF-16 offsets. The parser converts between `String.Index` and UTF-16 positions carefully to avoid crashes with multi-byte characters.

## Benchmarks

Benchmarks are in a separate package (`Benchmarks/`) to keep the main library dependency-free.

```bash
# Run benchmarks (from Benchmarks directory)
cd Benchmarks
swift package --allow-writing-to-package-directory benchmark

# Or from project root
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark

# Run specific benchmark
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark --filter "Simple"

# Save a baseline
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark baseline update main

# Compare against baseline
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark baseline compare main

# Save results to history folder with timestamp
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark --no-progress > "history/benchmark_$(date +%Y-%m-%d_%H-%M-%S).txt" 2>&1
```

The Swift benchmarks compare SwiftHighlight against [HighlightSwift](https://github.com/appstefan/HighlightSwift) measuring wall clock time and malloc count.

### Node.js Benchmark (highlight.js)

To compare against the original highlight.js library running in Node.js:

```bash
cd Benchmarks/nodejs
npm install
node benchmark.js
```

Historical benchmark results are stored in the `history/` folder for tracking performance over time.

## Test Fixtures and highlight.js Submodule

Test fixtures are synced from the `highlight.js` git submodule to avoid duplication while keeping tests aligned with upstream.

### Initial Setup

When first cloning the repository or after pulling submodule changes:

```bash
# Initialize submodule
git submodule update --init --recursive

# Sync test fixtures
./scripts/sync-fixtures.sh
```

### Updating highlight.js Version

To update to a newer version of highlight.js:

```bash
# Update submodule to desired version
cd highlight.js
git fetch origin
git checkout main  # or specific tag like "11.11.1"
cd ..

# Update submodule reference
git add highlight.js

# Sync test fixtures from new version
./scripts/sync-fixtures.sh

# Run tests to check compatibility
swift test

# Commit if tests pass
git commit -m "Update highlight.js to <version>"
```

### Adding Fixtures for a New Language

1. Add the language name to the `LANGUAGES` array in `scripts/sync-fixtures.sh`
2. Run `./scripts/sync-fixtures.sh` to copy fixtures
3. Create corresponding test file in `Tests/SwiftHighlightTests/`

## Reference Material

The `highlight.js/` directory is a git submodule containing the original JavaScript library for reference when porting features or debugging behavior differences. Test fixtures are automatically synced from this submodule.

The `notes/spec.md` file contains the original API design document.
