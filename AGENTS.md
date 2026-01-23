# Repository Guidelines

## Project Structure & Module Organization
- `Sources/SwiftHighlight/`: core library, parsers, renderers, and language definitions in `Sources/SwiftHighlight/Languages/`.
- `Tests/SwiftHighlightTests/`: XCTest suites; fixtures live in `Tests/SwiftHighlightTests/Fixtures/<lang>/`.
- `tools/`: language porting pipeline (`extract-hljs-ir.mjs`, `generate-swift-from-ir.py`, `ir/` output).
- `scripts/`: helper scripts (fixture sync, etc.).
- `highlight.js/`: upstream submodule used for fixtures and reference.
- `notes/` and `Benchmarks/`: documentation and performance tooling.

## Build, Test, and Development Commands
- `swift build`: build the library.
- `swift test`: run the full XCTest suite.
- `swift test --filter GoFixtureTests`: run a single test class.
- `swift test --filter Python`: run tests matching a pattern.
- `git submodule update --init --recursive`: initialize `highlight.js`.
- `./scripts/sync-fixtures.sh`: sync fixtures from the submodule.
- Language porting: `node --loader ./tools/hljs-esm-loader.mjs ./tools/extract-hljs-ir.mjs --lang <lang>` then `python3 tools/generate-swift-from-ir.py --lang <lang>`.

## Coding Style & Naming Conventions
- Swift style: 4-space indentation, lowerCamelCase for functions/vars, UpperCamelCase for types.
- Prefer `scope` over `className` in modes; keep regexes in `HLJS.re("...")`.
- Keep changes ASCII unless a fixture or source already uses Unicode.

## Testing Guidelines
- Framework: XCTest.
- Test classes use `*FixtureTests` naming; fixtures are paired `name.txt` / `name.expect.txt`.
- When adding a language, add fixtures to `scripts/sync-fixtures.sh` and a new test file in `Tests/SwiftHighlightTests/`.

## Language Porting Workflow
- Generate IR and Swift: `node --loader ./tools/hljs-esm-loader.mjs ./tools/extract-hljs-ir.mjs --lang <lang>` then `python3 tools/generate-swift-from-ir.py --lang <lang>`.
- Sync fixtures and add tests: update `scripts/sync-fixtures.sh`, run `./scripts/sync-fixtures.sh`, and add `Tests/SwiftHighlightTests/<Lang>FixtureTests.swift`.
- Keep generated files in `Sources/SwiftHighlight/Languages/` and `tools/ir/` committed for traceability.

## Commit & Pull Request Guidelines
- Commit messages in history are short, imperative phrases (e.g., `diff yaml`). Keep them concise and scoped.
- PRs should include: summary of changes, tests run, and any fixture sync or generated files added/updated.

## Architecture Overview (Optional)
Core flow: `ModeCompiler` -> `Parser` (in `SwiftHighlight.swift`) -> `TokenTree` -> HTML renderer. Language definitions are compiled into `CompiledMode` for fast scanning.
