# Adding a New Language (Step-by-Step)

This guide is for porting a new highlight.js language to native Swift in this repo. Follow the steps in order and avoid editing core files unless noted.

## 1) Gather Inputs
- Identify the highlight.js language name (e.g., `go`, `rust`, `markdown`).
- Ensure the `highlight.js` submodule is initialized:
  - `git submodule update --init --recursive`

## 2) Generate the IR (do not hand-write modes)
- Run the IR extraction:
  - `node --loader ./tools/hljs-esm-loader.mjs ./tools/extract-hljs-ir.mjs --lang <lang>`
- This writes `tools/ir/<lang>.json`.
- If this fails, fix the JS side first; do not edit generated Swift manually.

## 3) Generate Swift Language File
- Run the generator:
  - `python3 tools/generate-swift-from-ir.py --lang <lang>`
- This creates `Sources/SwiftHighlight/Languages/<Lang>.swift`.
- Do not edit the generated file unless a specific fixture mismatch requires a tiny patch.

## 4) Register the Language
- Add a `register<Lang>()` in the generated file (the generator usually includes it).
- If it’s missing, create it in the same file.
- Example:
  - `registerLanguage("go") { hljs in goLanguage(hljs) }`

## 5) Add Fixtures
- Add the language name to `scripts/sync-fixtures.sh` `LANGUAGES` array.
- Run:
  - `./scripts/sync-fixtures.sh`
- Fixtures land in `Tests/SwiftHighlightTests/Fixtures/<lang>/`.

## 6) Add Tests
- Create `Tests/SwiftHighlightTests/<Lang>FixtureTests.swift`.
- Use existing fixture test files as templates (e.g., `GoFixtureTests.swift`).
- Point the fixture loader to `Fixtures/<lang>/`.
- Do not add custom output logic; keep it consistent with other fixtures.

## 7) Run Tests (Targeted First)
- Run language-only tests:
  - `swift test --filter <Lang>FixtureTests`
- Fix mismatches by adjusting the language file only if needed.

## 8) When You Must Edit the Swift Language File
- Only adjust patterns or flags when fixtures fail.
- Prefer minimal changes:
  - add `endsParent`, `returnBegin`, `excludeEnd`
  - tighten regexes
- Do not change parser/core unless multiple languages break the same way.

## 9) When You Must Edit Core Code (rare)
- Only after confirming a mismatch in multiple languages.
- Open a PR explaining the behavior change and include a test.

## 10) Final Verification
- Run full suite:
  - `swift test`
- Ensure no debug prints remain.

## Files You Should Avoid Editing
- `Sources/SwiftHighlight/Core/*` unless a shared engine bug is proven.
- `tools/extract-hljs-ir.mjs` and `tools/generate-swift-from-ir.py` unless the generator itself is wrong.

## Quick Checklist
- IR generated in `tools/ir/`
- Swift language file generated in `Sources/SwiftHighlight/Languages/`
- Fixtures synced to `Tests/SwiftHighlightTests/Fixtures/`
- New `*FixtureTests.swift` file added
- `swift test --filter <Lang>FixtureTests` passes
- `swift test` passes
