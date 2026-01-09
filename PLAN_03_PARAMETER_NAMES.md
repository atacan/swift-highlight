# Implementation Plan: Parameter Name Highlighting Inconsistency

## Issue Summary

Function parameter names are inconsistently highlighted. Some parameters get `hljs-params` highlighting while others don't, despite having the same structure.

**Affected Test:** `testParameterpack`

## Failing Example

### testParameterpack (line 1)
```swift
func expand<each T, repeat each U>(value: (repeat each T), other: each U, another: repeat each T) -> ...
```

- **Expected:** `value`, `other`, and `another` all highlighted as `hljs-params`
- **Actual:** Only `value` is highlighted, `other` and `another` are plain text

Comparison:
```html
<!-- Expected -->
(<span class="hljs-params">value</span>: ..., <span class="hljs-params">other</span>: ..., <span class="hljs-params">another</span>: ...)

<!-- Actual -->
(<span class="hljs-params">value</span>: ..., other: ..., another: ...)
```

## Root Cause Analysis

The `functionParameterName` mode in `Swift.swift` (lines 524-532) uses a lookahead pattern:

```swift
let functionParameterName = Mode(
    begin: .string(#"(?=\#(identifier)\s*:)|(?=\#(identifier)\s+\#(identifier)\s*:)"#),
    end: .string(":"),
    contains: [
        .mode(Mode(scope: "keyword", match: .string(#"\b_\b"#))),
        .mode(Mode(scope: "params", match: .string(identifier)))
    ],
    relevance: 0
)
```

The pattern has two variants:
1. `(?=identifier\s*:)` - single name like `value:`
2. `(?=identifier\s+identifier\s*:)` - two names like `external internal:`

**Hypothesis:** The issue is that the parameter names after keywords like `each` or `repeat` don't match the pattern correctly.

Looking at the actual text:
- `value:` - matches pattern 1 ✓
- `other:` - preceded by `each U, ` - the pattern should match but may be failing
- `another:` - preceded by `repeat each T) ` - same issue

The problem appears to be related to context. After types like `U` or `T)`, the pattern may not be matching because:
1. The comma `,` resets the context
2. There may be interference from the type highlighting

## Investigation Steps

1. **Check mode ordering in `functionParameters`**
   Looking at `functionParameters` mode (lines 535-563):
   ```swift
   let functionParameters = Mode(
       begin: .string(#"\("#),
       end: .string(#"\)"#),
       keywords: keywords,
       illegal: .string(#"[\"']"#),
       contains: [
           .mode(functionParameterName),  // First in list
           // ... other modes
       ]
   )
   ```
   The `functionParameterName` is first, which should give it priority.

2. **Test the pattern matching**
   The pattern `(?=identifier\s*:)` where `identifier = [a-zA-Z_][a-zA-Z_0-9]*`

   For `other:`, the lookahead should work because:
   - Position is at `o` in `other:`
   - Lookahead checks: `[a-zA-Z_][a-zA-Z_0-9]*\s*:` = `other:`  ✓

3. **Check for keyword interference**
   The word `other` is NOT a keyword, so it shouldn't be consumed by keyword processing.

   But wait - the `functionParameters` mode has `keywords: keywords` which includes the main keyword list. The `processKeywords` function may be consuming the text before `functionParameterName` can match.

## Root Cause (Most Likely)

The `processKeywords` function in `SwiftHighlight.swift` processes the keyword buffer which includes non-keyword text like parameter names. When text goes through keyword processing:

1. The keyword pattern `\b\w+|#\w+` matches `other`
2. It's not in the keyword list, so it's emitted as plain text
3. The `functionParameterName` mode never gets a chance to match

This is the same class of issue as the Keywords + Contains problem, but for a different context.

## Proposed Solutions

### Option A: Make functionParameterName a "begin-only" Mode

Convert `functionParameterName` to use `match` instead of `begin/end`:

```swift
let functionParameterName = Mode(
    match: .string(#"(?:\b_\b|\b\#(identifier))\s*(?=:)"#),
    beginScope: .indexed([1: "params"]),
    relevance: 0
)
```

This makes it a "match-only" mode that can be picked up by the Keywords + Contains fix.

**Issue:** Doesn't handle the two-name case `external internal:`

### Option B: Prioritize functionParameterName Before Keywords

Modify the mode to be processed before keyword matching:

```swift
let functionParameterName = Mode(
    scope: "params",
    match: .string(#"\b\#(identifier)(?=\s*:)"#),
    relevance: 0
)

let functionParameterExternalInternal = Mode(
    match: .string(#"\b(\#(identifier))\s+(\#(identifier))(?=\s*:)"#),
    beginScope: .indexed([1: "params", 2: "params"]),
    relevance: 0
)
```

Add both before other modes in `functionParameters.contains`.

### Option C: Fix the Begin/End Pattern (Recommended)

The current begin pattern uses lookahead but may not be entering the mode correctly. Debug and fix:

```swift
let functionParameterName = Mode(
    // More robust begin pattern
    begin: .string(#"(?<=[(,]\s*)(?=\#(identifier)\s*:)|(?<=[(,]\s*)(?=\#(identifier)\s+\#(identifier)\s*:)"#),
    end: .string(":"),
    excludeEnd: true,
    contains: [
        .mode(Mode(scope: "keyword", match: .string(#"\b_\b"#))),
        .mode(Mode(scope: "params", match: .string(identifier)))
    ],
    relevance: 0
)
```

Adding lookbehind `(?<=[(,]\s*)` ensures we're at the start of a parameter.

**Note:** Need to verify if lookbehind is supported in the regex engine.

### Option D: Extend Keywords + Contains Fix

The recent fix for Keywords + Contains only handles "match-only" modes. Extend it to also handle begin/end modes when appropriate:

In `processWordWithContains`, also check modes that have `begin` pattern and can match single words.

## Implementation Steps

1. **Add debug logging**
   In `SwiftHighlight.swift`, add logging to see:
   - What text enters `processKeywords`
   - What modes are in `contains` for function parameters
   - Which modes match and which don't

2. **Test the lookahead pattern**
   ```swift
   let pattern = #"(?=[a-zA-Z_][a-zA-Z_0-9]*\s*:)"#
   // Test against "other:" at various positions
   ```

3. **Implement Option B** (simplest fix)
   - Change `functionParameterName` to use `match` instead of `begin/end`
   - Create separate pattern for two-name parameters
   - Run tests

4. **If Option B fails, try Option C**
   - Add lookbehind to ensure proper context
   - May need to handle lookbehind support in NSRegularExpression

5. **Run full test suite**
   ```bash
   swift test --filter parameterpack
   swift test
   ```

## Files to Modify

- `Sources/SwiftHighlight/Languages/Swift.swift`
  - Lines 524-532: Modify `functionParameterName` mode
  - Lines 535-563: Possibly adjust `functionParameters` mode

## Test Cases to Verify

After implementation:

```swift
// All parameter names should be highlighted as hljs-params
func f(a: Int)
func f(a: Int, b: Int)
func f(_ a: Int)  // _ is keyword, a is params
func f(external internal: Int)  // both should be params
func f(value: T, other: U, another: V)  // all should be params
func f<each T>(value: (repeat each T), other: each U)  // value and other should be params
```

## Complexity Estimate

Medium - requires understanding mode precedence and possibly extending the Keywords + Contains fix.

## References

- `Swift.swift` lines 524-532 (functionParameterName)
- `Swift.swift` lines 535-563 (functionParameters)
- `SwiftHighlight.swift` processKeywords function
- ARCHITECTURE_ISSUES.md (Keywords + Contains problem)
