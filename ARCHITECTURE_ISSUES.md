# SwiftHighlight Architecture Issues

## Issue #1: Keywords + Contains Incompatibility

### Summary
Modes with both `keywords` and `contains` properties cannot highlight non-keyword content using their `contains` modes. This is a fundamental architectural difference from highlight.js that prevents direct language definition porting.

### Severity
**HIGH** - Blocks multiple language features, prevents 1:1 porting from highlight.js

### Affected Components
- `Sources/SwiftHighlight/SwiftHighlight.swift:412-470` - `processKeywords()` function
- Any language mode using both `keywords` and `contains` properties
- Currently blocks: Swift precedencegroup types, potentially affects other languages

---

## Technical Analysis

### How highlight.js Works

In highlight.js, when processing a mode with both `keywords` and `contains`:

```javascript
const MODE = {
  begin: /start/,
  end: /end/,
  keywords: ['keyword1', 'keyword2'],
  contains: [
    { className: 'type', match: /[A-Z]\w+/ },
    { className: 'number', match: /\d+/ }
  ]
};
```

**Processing flow:**
1. Begin pattern matches → mode activated
2. Content between begin and end is scanned
3. **Both keywords AND contains modes participate in matching**
4. Keywords get highlighted as keywords
5. Patterns from `contains` also match and highlight (types, numbers, etc.)
6. Unmatched text remains plain
7. End pattern matches → mode deactivated

**Result:** Keywords like "keyword1" are highlighted, AND type names like "MyType" are highlighted, AND numbers are highlighted.

---

### How SwiftHighlight Works

```swift
let mode = Mode(
    begin: .string("start"),
    end: .string("end"),
    keywords: Keywords(keyword: ["keyword1", "keyword2"]),
    contains: [
        .mode(Mode(scope: "type", match: .string(#"[A-Z]\w+"#))),
        .mode(Mode(scope: "number", match: .string(#"\d+"#)))
    ]
)
```

**Processing flow:**
1. Begin pattern matches → mode activated
2. Content between begin and end is **buffered**
3. When buffer is processed (`processBuffer()`), it calls `processKeywords()`
4. `processKeywords()` **ONLY looks for keywords:**
   ```swift
   // SwiftHighlight.swift:412-470
   private func processKeywords(...) {
       guard let keywords = mode.keywords,
             let patternRe = mode.keywordPatternRe else {
           emitter.addText(text)  // No keywords = add as plain text
           return
       }

       // Find all words matching keyword pattern (default: \w+)
       let matches = patternRe.matches(in: text, ...)

       for result in matches {
           let word = String(text[matchRange])
           if let (scope, _) = keywords.keywords[key] {
               // Highlight keyword
               emitter.startScope(scope)
               emitter.addText(word)
               emitter.endScope()
           } else {
               // NOT A KEYWORD = PLAIN TEXT
               // ❌ contains modes are NEVER consulted
               emitter.addText(word)
           }
       }
   }
   ```

5. **Contains modes are NEVER evaluated for buffered text**
6. End pattern matches → mode deactivated

**Result:** Keywords are highlighted, but type names and numbers remain plain text even though `contains` defines modes for them.

---

## Root Cause

The `processKeywords` function treats buffered text as a keyword-only domain:
- ✅ Text matching keywords → highlighted
- ❌ Text NOT matching keywords → plain text (should check `contains` modes!)

**The `contains` modes are only evaluated for:**
- `begin`/`end`/`match` pattern matching (to enter/exit modes)
- NOT for highlighting content within the buffered text

---

## Real-World Example: Swift Precedencegroup

### JavaScript (works correctly):
```javascript
const PRECEDENCEGROUP = {
  begin: [/precedencegroup/, /\s+/, Swift.typeIdentifier],
  end: /}/,
  keywords: ['higherThan', 'lowerThan', 'assignment', ...],
  contains: [ TYPE ]  // ← This works!
};
```

Input:
```swift
precedencegroup MyGroup {
  higherThan: OtherGroup, AnotherGroup
}
```

Output:
- `higherThan` → highlighted as keyword ✅
- `OtherGroup`, `AnotherGroup` → highlighted as types ✅ (via `contains: [ TYPE ]`)

### SwiftHighlight (broken):
```swift
let precedencegroupDecl = Mode(
    begin: .string(#"\b(precedencegroup)\s+(\#(typeIdentifier))"#),
    end: .string("}"),
    keywords: Keywords(keyword: precedencegroupKeywordList),
    contains: [
        .mode(typeMode)  // ← This is IGNORED for buffered text!
    ]
)
```

Output:
- `higherThan` → highlighted as keyword ✅
- `OtherGroup`, `AnotherGroup` → plain text ❌ (`typeMode` never consulted)

---

## Proposed Solution

### Option A: Modify `processKeywords` (Recommended)

**File:** `Sources/SwiftHighlight/SwiftHighlight.swift`

**Current logic:**
```swift
private func processKeywords(_ text: String, ...) {
    // 1. Find keyword matches
    // 2. For each word:
    //    - If keyword: highlight
    //    - If not keyword: plain text ❌
}
```

**Proposed logic:**
```swift
private func processKeywords(_ text: String, mode: CompiledMode, ...) {
    guard let keywords = mode.keywords else {
        // No keywords: process with contains modes as usual
        processTextWithContains(text, mode: mode, ...)
        return
    }

    var lastIndex = text.startIndex
    let matches = keywordPatternRe.matches(in: text, ...)

    for result in matches {
        let matchRange = Range(result.range, in: text)

        // Text before this match
        if matchRange.lowerBound > lastIndex {
            let beforeText = String(text[lastIndex..<matchRange.lowerBound])
            // ✅ NEW: Try to match with contains modes
            processTextWithContains(beforeText, mode: mode, ...)
        }

        let word = String(text[matchRange])
        if let (scope, _) = keywords.keywords[word] {
            // Highlight as keyword
            emitter.startScope(scope)
            emitter.addText(word)
            emitter.endScope()
        } else {
            // ✅ NEW: Not a keyword, try contains modes
            processTextWithContains(word, mode: mode, ...)
        }

        lastIndex = matchRange.upperBound
    }

    // Remaining text
    if lastIndex < text.endIndex {
        let remaining = String(text[lastIndex...])
        // ✅ NEW: Try to match with contains modes
        processTextWithContains(remaining, mode: mode, ...)
    }
}

// New helper function
private func processTextWithContains(_ text: String, mode: CompiledMode, ...) {
    // Try to match text against mode.contains
    // Similar logic to main highlighting loop but for a text segment
    // If no contains mode matches, add as plain text
}
```

**Benefits:**
- Aligns SwiftHighlight behavior with highlight.js
- Enables direct porting of language definitions
- Fixes precedencegroup, nested interpolation, and potentially other languages
- Backward compatible (modes without `contains` work as before)

**Challenges:**
- Requires careful implementation to avoid infinite recursion
- Need to handle mode context correctly (parent modes, relevance, etc.)
- Performance considerations (more pattern matching)

---

### Option B: Language-Level Workaround (Not Recommended)

Remove `keywords` property and create explicit keyword modes:

```swift
let precedencegroupDecl = Mode(
    begin: .string(#"\b(precedencegroup)\s+(\#(typeIdentifier))"#),
    end: .string("}"),
    // NO keywords property
    contains: [
        .mode(Mode(scope: "keyword", match: .string("higherThan"))),
        .mode(Mode(scope: "keyword", match: .string("lowerThan"))),
        // ... one mode per keyword
        .mode(typeMode)
    ]
)
```

**Problems:**
- Verbose and error-prone
- Doesn't match highlight.js semantics
- **Still doesn't work** (tested and failed - suggests even deeper issues)
- Not a scalable solution

---

## Impact Assessment

### Languages Affected
- ✅ **Swift:** precedencegroup types, nested interpolation parens
- ⚠️ **Potentially all languages** that use `keywords` + `contains` together
- Need to audit other language definitions

### Backward Compatibility
- Option A (modify `processKeywords`) should be backward compatible
- Modes without `contains` continue to work as before
- Modes with `contains` but no `keywords` unaffected

### Performance
- Option A adds pattern matching for non-keyword text
- Should be negligible for most use cases
- May need optimization for very large files or many contains modes

---

## Testing Strategy

### Unit Tests Needed
1. Mode with `keywords` only (existing behavior)
2. Mode with `contains` only (existing behavior)
3. **Mode with both `keywords` and `contains` (new behavior)**
   - Keywords highlighted correctly
   - Contains modes match non-keyword text
   - Unmatched text remains plain
4. Nested modes with keywords+contains
5. Performance benchmarks

### Integration Tests
1. Swift precedencegroup (currently failing)
2. Swift string interpolation with nested structures
3. Audit other languages for similar patterns

---

## References

### Code Locations
- **Bug location:** `Sources/SwiftHighlight/SwiftHighlight.swift:412-470`
- **Mode compilation:** `Sources/SwiftHighlight/Core/ModeCompiler.swift`
- **Affected language:** `Sources/SwiftHighlight/Languages/Swift.swift`

### Related Issues
- `SWIFT_ISSUES.md` - Swift-specific manifestations
- Swift test failures: precedencegroup (lines 2-3), strings (line 59)

### highlight.js Reference
- `highlight.js/src/languages/swift.js:445-460` - PRECEDENCEGROUP definition
- `highlight.js/src/languages/swift.js:521-545` - String interpolation population

---

## Recommendation

**Implement Option A (Modify processKeywords)**

This is the correct architectural fix that aligns SwiftHighlight with highlight.js semantics. While it requires core engine changes, it:

1. Enables proper language definition porting
2. Fixes multiple current issues
3. Prevents future issues in new languages
4. Maintains backward compatibility

**Priority:** HIGH - Blocks Swift language completion and potentially affects other languages.

**Estimated Effort:** 2-4 hours for implementation + testing

---

## Next Steps

1. Create unit tests for keywords+contains behavior
2. Implement `processTextWithContains` helper function
3. Modify `processKeywords` to call helper for non-keyword text
4. Run full test suite (all languages)
5. Performance profiling
6. Update documentation

---

*Document created: 2026-01-04*
*Last updated: 2026-01-04*
