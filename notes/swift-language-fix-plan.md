# Swift.swift fixture fixes plan

## Problems observed
- Generic angle brackets in `class func` generic params are not highlighted as operators; `genericBracketGuard` in `Sources/SwiftHighlight/Languages/Swift.swift` suppresses `<`/`>` and conflicts with the highlight.js fixture.
- Function/macro parameter name highlighting is off: `_` is treated as `params` instead of `keyword`, and `name:` spans include the colon.
- Tuple element names inside parameter tuples are being highlighted as params because tuples are not parsed inside `functionParameters`.
- String interpolation marks plain identifiers as operators (`x` in `abs(x - 2)`), meaning interpolation submodes are not aligned with highlight.js.

## Fix plan
1. Delete `genericBracketGuard` entirely (definition and all `.mode(genericBracketGuard)` entries). This lets `<`/`>` be highlighted by `operatorMode` when not consumed by `genericParameters`/`genericArguments`.
2. Replace `functionParameterExternalInternal`, `functionParameterUnderscore`, and `functionParameterName` with a single mode modeled after highlight.js:
   - `begin`: lookahead for `name:` or `external internal:` using `#"(?:\#(identifier)\s*:|\#(identifier)\s+\#(identifier)\s*:)"#`.
   - `end`: `":"` so the colon is excluded from the highlight span.
   - `contains`: `_` as `keyword` (`\\b_\\b`) and identifiers as `params` (`#(identifier)`).
   - `relevance: 0`.
3. Move `tuple` above `functionParameters` and add `.mode(tuple)` to `functionParameters.contains` so tuple element names are parsed by `tupleElementName` and do not become `params`.
4. Align string interpolation to highlight.js submodes:
   - Define `keywordModes`, `builtIns`, and `operators` arrays (as `[ModeReference]`) and reuse them.
   - Set interpolation `contains` to `keywordModes + builtIns + operators + [number, stringMode, quotedIdentifier, implicitParameter, propertyWrapperProjection]`.
   - The nested parens mode should include `.self` plus the same submodes.
5. Re-run `swift test --filter SwiftFixtureTests` and verify the six failing fixtures now match.
