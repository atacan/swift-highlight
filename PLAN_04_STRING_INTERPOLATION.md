# Implementation Plan: String Interpolation Nested Highlighting

## Issue Summary

Operators and numbers inside string interpolation are not being highlighted correctly. This is related to the "Keywords + Contains" architectural issue but affects begin/end modes.

**Affected Test:** `testStrings`

## Failing Example

### testStrings (line 59)
```swift
#"""
interpolation \#(abs(x - 2) as Double)
"""#
```

Inside the interpolation `\#(abs(x - 2) as Double)`:
- **Expected:** `x - 2` should have `-` as `hljs-operator` and `2` as `hljs-number`
- **Actual:** `x - 2` is plain text (no highlighting)

Comparison:
```html
<!-- Expected -->
<span class="hljs-subst">\#(<span class="hljs-built_in">abs</span>(x <span class="hljs-operator">-</span> <span class="hljs-number">2</span>) <span class="hljs-keyword">as</span> Double)</span>

<!-- Actual -->
<span class="hljs-subst">\#(<span class="hljs-built_in">abs</span>(x - 2) <span class="hljs-keyword">as</span> Double)</span>
```

## Root Cause Analysis

The `interpolation` function in `Swift.swift` (lines 282-337) defines the mode for string interpolation:

```swift
func interpolation(_ rawDelimiter: String = "") -> Mode {
    // ...
    return Mode(
        scope: "subst",
        begin: .string(#"\\\#(rawDelimiter)\("#),
        end: .string(#"\)"#),
        keywords: keywords,
        contains: [
            .mode(number),
            // ...
            .mode(operatorGuard),
            .mode(operatorMode),
            // ...
        ]
    )
}
```

The mode has both `keywords` AND `contains`, which triggers the Keywords + Contains incompatibility issue.

The recent fix only handles **"match-only" modes** (modes where `terminatorEnd` is empty or `\B|\b`). The `number` and `operatorMode` in the interpolation context are match-only modes, BUT:

1. The text `x - 2` is being processed through `processKeywords`
2. `x` matches the keyword pattern `\b\w+`
3. `-` does NOT match the keyword pattern
4. `2` matches the keyword pattern
5. The spaces and `-` become "before" or "remaining" text, emitted as plain text

The issue is that `-` (operator) doesn't match the keyword pattern, so it never goes through `processWordWithContains`.

## Deep Dive: Why Operators Don't Match

The keyword pattern in Swift is:
```swift
pattern: .string(#"\b\w+|#\w+"#)
```

This matches word characters: `[a-zA-Z0-9_]`

The operator `-` doesn't match this pattern, so it's never extracted as a "word" to be checked against contains modes.

In `processKeywords`:
1. Input: `x - 2`
2. Keyword pattern matches: `x` at position 0, `2` at position 4
3. Between matches (positions 1-3): ` - ` is emitted as plain text via `emitter.addText()`
4. The `-` never gets a chance to be matched by `operatorMode`

## Proposed Solutions

### Option A: Extend processKeywords to Handle Non-Keyword Text (Recommended)

The current fix only processes words that match the keyword pattern but aren't in the keyword list. Extend it to also process text between keyword matches.

```swift
private func processKeywords(...) {
    // ... existing code to find keyword matches ...

    for result in matches {
        let matchRange = Range(result.range, in: text)!

        // Text before this match
        if matchRange.lowerBound > lastIndex {
            let beforeText = String(text[lastIndex..<matchRange.lowerBound])
            // NEW: Try to match operators and other patterns in beforeText
            processNonKeywordText(beforeText, emitter: emitter, mode: mode, relevance: &relevance)
        }

        // ... rest of keyword processing ...
    }

    // Text after last match
    if lastIndex < text.endIndex {
        let remainingText = String(text[lastIndex...])
        processNonKeywordText(remainingText, emitter: emitter, mode: mode, relevance: &relevance)
    }
}

private func processNonKeywordText(
    _ text: String,
    emitter: TokenTreeEmitter,
    mode: CompiledMode,
    relevance: inout Int
) {
    // Iterate through text, trying each match-only contains mode
    // Emit matched portions with scope, unmatched as plain text
}
```

**Note:** This is essentially what ARCHITECTURE_ISSUES.md Option A describes but for ALL non-keyword text, not just non-keyword words.

### Option B: Split Keywords and Contains

Remove `keywords` from the interpolation mode and let the `contains` modes handle everything:

```swift
return Mode(
    scope: "subst",
    begin: .string(#"\\\#(rawDelimiter)\("#),
    end: .string(#"\)"#),
    // NO keywords here
    contains: [
        .mode(keywordMode),  // Explicit keyword matching mode
        .mode(number),
        .mode(operatorGuard),
        .mode(operatorMode),
        // ...
    ]
)
```

Create a separate `keywordMode` that only matches keywords:
```swift
let keywordMode = Mode(
    scope: "keyword",
    match: .string(#"\b(if|else|as|...)\b"#)
)
```

**Cons:**
- Requires restructuring how keywords work
- May affect relevance scoring

### Option C: Process Operators as Special Tokens

In `processKeywords`, add special handling for operator characters:

```swift
// After finding keyword matches, scan for operators between them
let operatorPattern = try! NSRegularExpression(pattern: operatorPatternString)
// Match operators in the gaps between keywords
```

This is similar to Option A but specifically targets operators.

## Implementation Steps

1. **Understand the current flow**
   Add debug logging to trace:
   - What text enters `processKeywords` for interpolation
   - What the keyword pattern matches
   - What text is emitted as plain vs. highlighted

2. **Implement processNonKeywordText helper**
   ```swift
   private func processNonKeywordText(
       _ text: String,
       emitter: TokenTreeEmitter,
       mode: CompiledMode,
       relevance: inout Int
   ) {
       guard !text.isEmpty else { return }
       guard !mode.contains.isEmpty else {
           emitter.addText(text)
           return
       }

       // Try each match-only mode against the text
       // Build up highlighted output
   }
   ```

3. **Handle overlapping matches**
   When multiple patterns could match:
   - Use first match (leftmost)
   - After a match, continue from end of match
   - Emit unmatched text as plain

4. **Test incrementally**
   ```bash
   swift test --filter testStrings
   ```

5. **Ensure no regressions**
   ```bash
   swift test
   ```

## Files to Modify

- `Sources/SwiftHighlight/SwiftHighlight.swift`
  - Extend `processKeywords` to handle text between keyword matches
  - Add `processNonKeywordText` helper function

- Possibly `Sources/SwiftHighlight/Languages/Swift.swift`
  - If structural changes to interpolation mode are needed

## Test Cases to Verify

After implementation:

```swift
// Operators inside interpolation
"\(a + b)"       // + should be hljs-operator
"\(x - 2)"       // - and 2 should be highlighted
"\(a * b / c)"   // * and / should be operators

// Numbers inside interpolation
"\(123)"         // 123 should be hljs-number
"\(1.5)"         // 1.5 should be hljs-number
"\(1e10)"        // 1e10 should be hljs-number

// Mixed content
"\(abs(x - 2) as Double)"  // abs=built_in, -=operator, 2=number, as=keyword

// Nested parens
"\((a + b) * (c - d))"  // all operators should be highlighted
```

## Complexity Estimate

Medium-High - This is essentially completing the Keywords + Contains fix for all text, not just words. Requires careful handling of:
- Text scanning and segmentation
- Mode precedence
- Avoiding regressions in other highlighting

## Relationship to Other Issues

This issue is closely related to:
- **PLAN_03_PARAMETER_NAMES.md** - Both stem from the Keywords + Contains architectural issue
- **ARCHITECTURE_ISSUES.md** - Documents the root cause

Solving this issue properly may also fix the parameter names issue, or at least provide a foundation for it.

## References

- `Swift.swift` lines 282-337 (interpolation function)
- `SwiftHighlight.swift` processKeywords function
- `SwiftHighlight.swift` processWordWithContains function (recent fix)
- ARCHITECTURE_ISSUES.md (Keywords + Contains problem)
