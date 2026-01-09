# Implementation Plan: Generic Brackets vs Operators

## Issue Summary

Generic type brackets `<` and `>` are incorrectly highlighted as operators in certain contexts.

**Affected Tests:** `testFunctions`, `testTypes`

## Failing Examples

### testFunctions (line 8)
```swift
func < <T>() { }
```
- **Expected:** `func < <T>() { }` - the `<T>` should NOT be highlighted
- **Actual:** `func < <T>()` - both `<` and `>` in `<T>` are highlighted as `hljs-operator`

### testTypes (line 23)
```swift
Array<Array<Int?>>
```
- **Expected:** `Array<Array<Int?>>` - closing `>` should NOT be highlighted
- **Actual:** `Array<Array<Int?>>` - final `>` IS highlighted as `hljs-operator`

## Root Cause Analysis

The operator pattern in `Swift.swift` (lines 250-258) matches `<` and `>` too eagerly:

```swift
let operatorHead = #"[/=\-+!*%<>&|^~?]"#
let operatorChar = #"[/=\-+!*%<>&|^~?]"#
let operatorPattern = operatorHead + operatorChar + "*"

let operatorMode = Mode(
    scope: "operator",
    variants: [
        ModeBox(Mode(match: .string(operatorPattern))),
        ModeBox(Mode(match: .string(#"\.(\.|"# + operatorChar + #")+"#)))
    ],
    relevance: 0
)
```

The `genericArguments` mode (lines 461-486) handles `<...>` for generic types, but:
1. It's a begin/end mode that consumes the `<` and `>` tokens
2. When generic brackets appear after function names or in nested contexts, the operator pattern can match first
3. The `>>` at the end of `Array<Array<Int?>>` appears as a single token that the operator pattern matches

## Proposed Solutions

### Option A: Negative Lookahead in Operator Pattern (Recommended)

Add negative lookahead to prevent operator matching when followed by type-like patterns:

```swift
// Don't match < when followed by uppercase letter (type), 'each', 'repeat', 'some', 'any'
let operatorPattern = #"(?![<>]\s*[A-Z]|[<>]\s*(each|repeat|some|any)\b)"# + operatorHead + operatorChar + "*"
```

**Pros:**
- Minimal change
- Doesn't affect mode ordering

**Cons:**
- Complex regex, may have edge cases
- Doesn't handle all nested generic scenarios

### Option B: Operator Guard for Generic Contexts

Add a guard mode specifically for generic brackets, similar to `operatorGuard` for `->`:

```swift
// Guard against < and > in generic contexts
let genericBracketGuard = Mode(
    match: .string(#"<(?=\s*[A-Z])|<(?=\s*(each|repeat|some|any)\b)|>(?=\s*[,)>\]])|>>(?=\s*[,)>\]])"#),
    relevance: 0
)
```

Place this BEFORE `operatorMode` in the language's `contains` array.

**Pros:**
- Explicit handling of generic contexts
- Easy to understand and maintain

**Cons:**
- May not catch all edge cases
- Requires careful pattern design

### Option C: Fix genericArguments Mode Ordering

Ensure `genericArguments` mode is processed before `operatorMode` in all contexts:

1. Review all modes that should support generic types
2. Ensure `genericArguments` or `typeMode` appears before `operatorMode` in their `contains` arrays
3. The `typeMode` (lines 489-500) already includes `genericArguments`, but may not be in all necessary contexts

**Investigation needed:**
- Check `functionOrMacro` mode - does it properly handle `func < <T>`?
- Check how `>>` is tokenized at end of nested generics

## Implementation Steps

1. **Reproduce the issue locally**
   ```bash
   swift test --filter testFunctions
   swift test --filter testTypes
   ```

2. **Add debug logging** to understand token flow
   - Add print statements in `SwiftHighlight.swift` `_highlight()` to see what patterns match

3. **Implement Option B** (recommended starting point)
   - Create `genericBracketGuard` mode in `Swift.swift`
   - Add it before `operatorMode` in the language's `contains` array
   - Run tests

4. **Handle the `func < <T>` case specifically**
   - The function name IS `<` (a valid operator function name)
   - The `<T>` after it is generic parameters
   - May need special handling in `functionOrMacro` mode

5. **Handle nested generics `>>`**
   - When `Array<Array<Int?>>` is parsed:
     - First `>` closes inner `Array<Int?>`
     - Second `>` closes outer `Array<...>`
   - The issue is likely that `>>` is being matched as a single operator token
   - Solution: Add pattern that prevents `>` from matching when it's closing a generic

6. **Run full test suite**
   ```bash
   swift test
   ```

## Files to Modify

- `Sources/SwiftHighlight/Languages/Swift.swift`
  - Add guard mode(s) for generic brackets
  - Possibly modify `operatorMode` pattern
  - Review mode ordering in `contains` arrays

## Test Cases to Verify

After implementation, verify these cases work correctly:

```swift
// Should NOT highlight < > as operators
func foo<T>() { }
Array<Int>
Array<Array<Int>>
Dictionary<String, Array<Int>>

// SHOULD highlight these as operators
a < b
a > b
a << b
a >> b  // when used as actual shift operator
func < (lhs: T, rhs: T) -> Bool  // the < IS the function name

// Edge cases
func < <T>() { }  // first < is function name, second < and > are generic brackets
a<b>c  // could be comparison or generic depending on context
```

## Complexity Estimate

Medium - requires careful regex work and understanding of mode precedence.

## References

- `Swift.swift` lines 250-258 (operatorMode)
- `Swift.swift` lines 461-486 (genericArguments)
- `Swift.swift` lines 489-500 (typeMode)
- `Swift.swift` lines 604-612 (functionOrMacro)
