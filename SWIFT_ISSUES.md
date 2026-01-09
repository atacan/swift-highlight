# Swift Language Support - Status Report

## Current Status
- **14/20 tests passing (70%)**
- Swift.swift language definition at `Sources/SwiftHighlight/Languages/Swift.swift`
- Test file at `Tests/SwiftHighlightTests/SwiftFixtureTests.swift`

## Recent Work (2026-01-04)

### ✅ Fixed Issues
1. **String Interpolation Content (partial)** - Numbers, strings, keywords, operators now highlight inside `\#(...)` interpolation
2. **Dot Number Pattern `.0`** - Now highlights correctly (moved earlier in contains array for proper precedence)

### ⚠️ Known Limitations

#### 1. Nested Parentheses in String Interpolation (strings test, line 59)
**Input:** `\#(abs(x - 2) as Double)`
**Expected:** Operators and numbers inside `(x - 2)` should be highlighted
**Actual:** Content inside nested parens not highlighted

**Root Cause:** Attempted fix with nested parentheses mode using `.self` reference doesn't highlight contained content. The mode prevents premature `end` matching but creates a "dead zone" where submodes aren't evaluated.

**Architecture Issue:** See ARCHITECTURE_ISSUES.md for details on keywords+contains conflict.

---

#### 2. Precedencegroup Types (precedencegroup test, lines 2-3)
**Input:** `higherThan: OtherGroup, AnotherGroup`
**Expected:** Type names highlighted as `<span class="hljs-type">`
**Actual:** Types not highlighted

**Root Cause:** **ARCHITECTURAL LIMITATION** - When a mode has both `keywords` and `contains`, SwiftHighlight's `processKeywords` function processes buffered text ONLY for keyword matching. Non-keywords are added as plain text without consulting `contains` modes.

In highlight.js:
```javascript
const PRECEDENCEGROUP = {
  contains: [ TYPE ],  // This works in JavaScript
  keywords: [...precedencegroupKeywords, ...literals]
};
```

In SwiftHighlight: The `keywords` property prevents `contains` modes from being evaluated on the buffered text between pattern matches.

**Workaround Attempted:** Creating explicit modes for keywords instead of using `keywords` property, but this also failed, suggesting deeper mode evaluation issues.

---

#### 3. Invalid Number Syntax Edge Cases (numbers test, lines 41-42)
**Examples:** `0b_0`, `0b02` (invalid binary literals)
**Expected:** No highlighting
**Actual:** Partial highlighting

**Status:** Low priority - these are invalid syntax. Valid syntax like `.0` now works correctly.

---

## Failing Tests (6 remaining)

### Not Yet Addressed

#### 4. Nested Generics `>>` (types test, line 23)
**Expected:** `Array<Array<Int?>>` with both `>` as part of generics
**Actual:** Second `>` highlighted as operator

**Likely Fix:** Add `typeMode` to `genericArguments.contains` to create recursive structure (as in highlight.js).

---

#### 5. Parameter Names After Keywords (parameterpack test, line 1)
**Expected:** `<span class="hljs-params">other</span>:` and `<span class="hljs-params">another</span>:`
**Actual:** Parameter names after `repeat`, `each` keywords not highlighted

**Likely Fix:** Enhance `functionParameterName` pattern with `(?:\b(?:repeat|each)\s+)?` prefix.

---

#### 6. Operator Function Generics (functions test, line 8)
**Expected:** `func < <T>()` with generic params not highlighted as operators
**Actual:** `<T>` matched as operators instead of generics

**Status:** Complex - may require investigation into mode precedence or operator guards.

---

## Architectural Issues Discovered

### Keywords + Contains Conflict

**File:** `Sources/SwiftHighlight/SwiftHighlight.swift:412-470` (`processKeywords`)

**Problem:** When a mode defines both `keywords` and `contains`:
1. Buffered text is processed by `processKeywords()`
2. Keywords are matched using the keyword pattern regex (default `\w+`)
3. **Non-keywords are added as plain text without consulting `contains` modes**
4. This prevents `contains` modes from highlighting non-keyword content

**JavaScript vs Swift:**
- **highlight.js:** Keywords and contains both participate in pattern matching
- **SwiftHighlight:** Keywords take precedence; contains only evaluated for begin/end/match patterns, not buffered text

**Impact:**
- Precedencegroup types can't be highlighted (keywords prevent type modes from matching)
- Any mode using both `keywords` and `contains` for different purposes will fail
- This is a fundamental architectural difference, not a simple porting issue

**Solution Required:** Modify `processKeywords` to:
1. Match keywords as it does now
2. For non-keyword text spans, evaluate `contains` modes before adding as plain text
3. This would align SwiftHighlight's behavior with highlight.js

See: `ARCHITECTURE_ISSUES.md` for detailed analysis and proposed solution.

---

## Key Files
- Language definition: `Sources/SwiftHighlight/Languages/Swift.swift`
- Tests: `Tests/SwiftHighlightTests/SwiftFixtureTests.swift`
- Fixtures: `Tests/SwiftHighlightTests/fixtures/swift/`
- highlight.js reference: `highlight.js/src/languages/swift.js`
- Core engine: `Sources/SwiftHighlight/SwiftHighlight.swift`
- Mode compiler: `Sources/SwiftHighlight/Core/ModeCompiler.swift`

## Commands
```bash
# Run all Swift fixture tests
swift test --filter SwiftFixtureTests

# Run specific test
swift test --filter testNumbers

# Sync fixtures from highlight.js
./scripts/sync-fixtures.sh
```

## Next Steps

1. **Architectural fix:** Implement keywords+contains compatibility (see ARCHITECTURE_ISSUES.md)
2. **After architectural fix:** Re-attempt precedencegroup types and nested interpolation parens
3. **Simple fixes:** Nested generics (#4) and parameter names (#5) - don't require architectural changes
4. **Investigation needed:** Operator function generics (#6)

---

## Summary

**Progress:** Valid syntax improvements (`.0` works, interpolation mostly works)
**Blockers:** Architectural differences between highlight.js and SwiftHighlight
**Path Forward:** Core engine modifications needed for full compatibility
