# Issue: ModeCompiler Filtering Out Parameter Name Modes

## Status
**Blocking:** Parameter name highlighting fix (PLAN_03_PARAMETER_NAMES.md)
**Severity:** High - Affects core mode compilation logic

## Summary

The ModeCompiler is silently filtering out or failing to compile certain modes that are correctly defined in the source language definition. Specifically, the function parameter name modes (with scope="params") are present in the source `Mode.contains` array but completely absent from the compiled `CompiledMode.contains` array at runtime.

## Affected Code

### Test Case
`testParameterpack` in SwiftFixtureTests.swift (line 150)

```swift
func expand<each T, repeat each U>(value: (repeat each T), other: each U, another: repeat each T) -> ...
```

**Expected:** All three parameter names (`value`, `other`, `another`) highlighted with `hljs-params`
**Actual:** Only `value` is highlighted; `other` and `another` appear as plain text

## Investigation Timeline

### Attempt 1: Lookahead Patterns
**Code:** Sources/SwiftHighlight/Languages/Swift.swift:565
```swift
let functionParameterName = Mode(
    scope: "params",
    match: .string(#"\b\#(identifier)(?=\s*:)"#),
    relevance: 0
)
```

**Issue:** Pattern compiles successfully in isolation but mode doesn't appear in compiled contains list.

### Attempt 2: Lookbehind Patterns
**Code:**
```swift
let functionParameterName = Mode(
    match: .string(#"(?<=\(|,)\s*(\#(identifier))\s*:"#),
    relevance: 0,
    beginScope: .indexed([1: "params"])
)
```

**Issue:** NSRegularExpression compiles the pattern successfully with `.anchorsMatchLines` option, but mode still doesn't appear in compiled contains list.

### Attempt 3: Simple Patterns
**Code:**
```swift
let functionParameterName = Mode(
    scope: "params",
    match: .string(#"\b\#(identifier)\s*:"#),
    relevance: 0
)
```

**Issue:** Even with the simplest possible pattern, mode doesn't appear in compiled contains list.

## Key Evidence

### Source Definition (Swift.swift)
```
DEBUG Swift.swift: functionParameterName pattern = \b[a-zA-Z_][a-zA-Z_0-9]*\s*:
DEBUG Swift.swift: functionParameters.contains.count = 23
DEBUG Swift.swift: contains[2] scope = params, match = \b[a-zA-Z_][a-zA-Z_0-9]*\s*:
```

✅ Mode is correctly defined
✅ Mode is added to contains array
✅ Pattern is valid regex

### Runtime State (SwiftHighlight.swift - processWordWithContains)
```
DEBUG processWordWithContains CALLED: word=other, text.prefix=, other: each
DEBUG   effectiveContains.count=51
DEBUG   child[0] terminatorEnd=$, isMatchOnly=false, scope=comment
DEBUG   child[1] terminatorEnd=\*/, isMatchOnly=false, scope=comment
DEBUG   child[2] terminatorEnd=\B|\b, isMatchOnly=true, scope=keyword
...
DEBUG   child[50] terminatorEnd=\), isMatchOnly=false, scope=no-scope
```

❌ Source has 23 modes, runtime has 51 modes
❌ **NONE of the 51 modes have scope="params"**
❌ Parameter name modes are completely missing

## Root Cause Analysis

### Hypothesis 1: ModeCompiler.compileMode() Filtering
The `compileMode()` function in ModeCompiler.swift may be:
- Filtering out modes based on certain criteria
- Failing to compile the pattern and returning an empty/null mode
- Not recursively compiling all modes in the contains array

**Evidence:**
- ModeCompiler.swift:96 uses `try?` which silently swallows regex compilation errors
- Source contains has 23 modes but compiled contains has 51 modes (expansion happening)
- Some modes are being expanded (e.g., variants) while others are dropped

### Hypothesis 2: Keywords + Contains Interaction
When a mode has both `keywords` and `contains`, the compilation process may:
- Prioritize keyword processing over contains modes
- Filter out contains modes that overlap with keyword patterns
- Merge or deduplicate modes incorrectly

**Evidence:**
- `functionParameters` has `keywords: keywords` set
- The keywords + contains fix (previous issue) only handles match-only modes
- Parameter name modes may be classified differently during compilation

### Hypothesis 3: Match-Only Mode Classification
The mode may not be recognized as a "match-only" mode during compilation:

**From processWordWithContains:**
```swift
let isMatchOnlyMode = child.terminatorEnd.isEmpty ||
    child.terminatorEnd == #"\B|\b"# ||
    child.terminatorEnd == #"(?:\B|\b)"#
```

If the compiled mode has a different `terminatorEnd` value, it won't be checked.

## Critical Code Locations

### ModeCompiler.swift
```swift
Line 88-97:  langRe() - Uses try? which silently fails
Line 103:    compileMode() - Main compilation entry point
Line 134-145: effectiveBegin computation - Handles match -> begin conversion
Line 153-167: terminatorEnd setting - May set unexpected values
Line 207-240: Variant expansion - Could explain 23 -> 51 mode expansion
```

### SwiftHighlight.swift
```swift
Line 425-511: processKeywords() - Handles keywords + contains interaction
Line 513-598: processWordWithContains() - Tries to match contains modes
Line 528-534: effectiveContains logic - Determines which contains to use
```

## Debugging Steps Performed

1. ✅ Verified NSRegularExpression can compile all patterns
2. ✅ Added debug output to Swift.swift showing modes are defined correctly
3. ✅ Added debug output to SwiftHighlight.swift showing modes are missing at runtime
4. ✅ Checked all 51 compiled modes - none have scope="params"
5. ✅ Verified pattern matching works in isolation
6. ✅ Tried multiple pattern approaches (lookahead, lookbehind, simple)

## Reproduction

```bash
# Run the failing test
swift test --filter testParameterpack

# Expected: Test passes with all parameter names highlighted
# Actual: Test fails - 'other' and 'another' not highlighted
```

## Impact

This bug affects:
- ✅ Function parameter name highlighting (current issue)
- ⚠️ Potentially other modes that use similar patterns
- ⚠️ Any mode added to a keywords + contains parent mode
- ⚠️ Modes with indexed beginScope

## Workaround Attempts

None successful. The fundamental issue is that modes defined in source don't make it through compilation, regardless of:
- Pattern complexity
- Scope definition method (scope vs beginScope)
- Pattern type (lookahead, lookbehind, simple)

## Next Steps

### Investigation Needed

1. **Add debug logging to ModeCompiler.compileMode()**
   - Log every mode as it's compiled
   - Log when modes are filtered out or skipped
   - Log the final compiled contains count

2. **Trace the compilation path**
   - Start with functionParameters mode
   - Follow how its 23 contains modes are compiled
   - Identify where the parameter name modes disappear
   - Understand why 23 becomes 51

3. **Check variant expansion logic**
   - Lines 207-240 in ModeCompiler.swift
   - Could be expanding some modes while dropping others
   - May explain the count increase

4. **Review keywords + contains interaction**
   - Previous fix in ARCHITECTURE_ISSUES.md only handled match-only modes
   - May need to extend the fix to handle begin/end modes
   - Parameter name modes might need different treatment

### Potential Fixes

**Option A: Fix ModeCompiler**
- Identify why modes are being filtered
- Ensure all source modes are compiled
- Add error logging for failed compilations

**Option B: Avoid Keywords + Contains**
- Remove `keywords` from `functionParameters` mode
- Handle keyword highlighting differently
- May break type/keyword highlighting inside parameters

**Option C: Direct Parsing**
- Don't rely on contains modes for parameter names
- Add special handling in the main parsing loop
- More invasive but guaranteed to work

## Related Files

- PLAN_03_PARAMETER_NAMES.md - Original implementation plan
- ARCHITECTURE_ISSUES.md - Documents keywords + contains problem
- Sources/SwiftHighlight/Languages/Swift.swift:547-613 - Parameter mode definitions
- Sources/SwiftHighlight/SwiftHighlight.swift:513-598 - processWordWithContains
- Sources/SwiftHighlight/Core/ModeCompiler.swift - Mode compilation logic

## Current Debug Output

The codebase currently has extensive debug output enabled:
- Swift.swift: Lines 556, 605-613
- SwiftHighlight.swift: Lines 524-526, 538-566, 579-592

**These should be removed** once the issue is resolved or investigation is complete.

## Questions to Answer

1. Why does source contains have 23 modes but compiled contains has 51?
2. Where exactly do the parameter name modes get filtered out?
3. What criteria determine if a mode survives compilation?
4. Is the issue specific to modes with `scope="params"` or all custom scopes?
5. Does the issue affect other languages or just Swift?
6. Is this related to the recent keywords + contains fix?

## Test Cases to Add

Once fixed, add tests to prevent regression:

```swift
// Test parameter name highlighting
func testParameterNamesSimple() {
    let input = "func f(a: Int, b: String)"
    // Both 'a' and 'b' should have hljs-params
}

func testParameterNamesAfterKeywords() {
    let input = "func f(value: each T, other: each U)"
    // Both 'value' and 'other' should have hljs-params
}

func testParameterNamesExternalInternal() {
    let input = "func f(external internal: Int)"
    // Both 'external' and 'internal' should have hljs-params
}
```

## Priority

**High** - This blocks the parameter name highlighting fix and potentially affects other mode definitions across all languages.

---

**Created:** 2026-01-10
**Last Updated:** 2026-01-10
**Assignee:** TBD
**Labels:** bug, mode-compiler, parameter-highlighting, investigation-needed
