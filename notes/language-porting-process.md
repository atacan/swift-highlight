# Faster, safer language porting plan (native Swift only)

## Goal
Port highlight.js languages to Swift with minimal manual tweaking, no JS runtime, and fast feedback when parity drifts.

## Proposed approach

### 1) Introduce a shared intermediate representation (IR)
Create a small, language-agnostic JSON IR for highlight.js modes. It should encode:
- `name`, `keywords`, `contains`, `variants`, `begin/end/match`, `beginScope/endScope`
- flags (`relevance`, `illegal`, `endsParent`, `endsWithParent`, `returnBegin`, `excludeBegin`, etc.)
- references (by ID) to allow cycles and `.self`

This IR becomes the single source for codegen, fixture alignment, and diff tooling.

### 2) Build a JS-to-IR extractor (one-time per highlight.js update)
Write a tiny Node script that:
- loads highlight.js language modules
- materializes their in-memory language definitions
- serializes them into IR JSON

This uses Node only for generating IR, not at runtime. Run it only during porting or updates.

### 3) Implement a Swift code generator from IR
Build a Swift (or Python) codegen tool that:
- reads IR JSON
- emits `Sources/SwiftHighlight/Languages/<Lang>.swift`
- uses shared helpers for keywords, regex patterns, and common modes

This guarantees structural parity with highlight.js definitions and removes most manual edits.

### 4) Create a shared Swift DSL for modes
Define a small DSL or helpers for common patterns:
- `kw(...)`, `lit(...)`, `mode(...)`, `ref(...)`, `variants(...)`
- prebuilt modes for comments, strings, attributes, function params, etc.

The generator should use the DSL to keep generated Swift readable and diff-friendly.

### 5) Add a fixture parity runner for all languages
Keep using highlight.js fixtures. Add a script to:
- run Swift tests per language
- group mismatches by feature (strings, numbers, params)
- emit a concise summary

Use this to batch-fix common issues across languages.

### 6) Define a "parity shim layer"
Some highlight.js behaviors are tied to JS quirks. Create a small set of Swift-only shims:
- regex helpers for lookahead/alternation
- generic parsing guards
- interpolation helpers

This is where mismatches are fixed once and reused across languages.

### 7) Validate IR compatibility early
Add a validator that checks for:
- unsupported regex features
- missing `contains` modes
- cyclic references without `.self` handling

Fail fast before codegen or tests.

### 8) Automate updates
When highlight.js changes:
- re-run JS extractor to update IR
- re-run Swift codegen
- run fixture suite
- only then hand-edit if needed

This keeps manual work minimal and localized to the shim layer or generator.

## Why this is faster
- Most languages become "data" rather than hand-ported code.
- Fixes are centralized in the generator or shims.
- Updates are repeatable: extract IR -> generate -> test.

## Suggested repository additions
- `tools/extract-hljs-ir.js` (Node, dev-only)
- `tools/generate-swift-from-ir.swift` or `tools/generate-swift-from-ir.py`
- `Sources/SwiftHighlight/DSL/` for reusable mode helpers
- `notes/ir-schema.md` documenting the JSON IR

## Immediate next steps
1. Define IR schema with a couple of representative languages (Swift, Python).
2. Build the JS extractor and confirm the IR matches expected highlight.js structures.
3. Implement Swift codegen + minimal DSL.
4. Run fixtures for 2-3 languages and tune shims until parity is solid.
5. Scale to all languages with batch generation.
