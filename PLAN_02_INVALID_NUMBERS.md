# Implementation Plan: Invalid Number Literal Handling

## Issue Summary

Invalid number literals are being partially matched and highlighted incorrectly. The number patterns are too permissive and match partial sequences.

**Affected Test:** `testNumbers`

## Failing Example

### testNumbers (line 42)
```swift
0b02
```
- **Expected:** `0b02` - should NOT be highlighted (invalid binary - 2 is not a valid binary digit)
- **Actual:** `<span class="hljs-number">0b0</span><span class="hljs-number">2</span>` - matches `0b0` as binary, then `2` as decimal

## Root Cause Analysis

The number patterns in `Swift.swift` (lines 103-117) don't prevent matching when followed by invalid digits:

```swift
let number = Mode(
    scope: "number",
    variants: [
        // Binary (must come before decimal to avoid matching just the leading 0)
        ModeBox(Mode(match: .string(#"\b0b([01]_*)+"#))),
        // Octal
        ModeBox(Mode(match: .string(#"\b0o([0-7]_*)+"#))),
        // Hexadecimal floating-point (subsumes hex integer)
        ModeBox(Mode(match: .string(#"\b0x(\#(hexDigits))(\.\#(hexDigits))?([pP][+-]?(\#(decimalDigits)))?"#))),
        // Decimal floating-point (subsumes decimal integer)
        ModeBox(Mode(match: .string(#"\b(?!0[boxBOX])(\#(decimalDigits))(\.\#(decimalDigits))?([eE][+-]?(\#(decimalDigits)))?"#)))
    ],
    relevance: 0
)
```

The binary pattern `\b0b([01]_*)+` matches `0b0` in `0b02` because:
1. It finds word boundary + `0b`
2. It matches `0` (valid binary digit)
3. It stops at `2` (not a valid binary digit)
4. The remaining `2` is then matched by the decimal pattern

## Invalid Cases from Fixture

The test fixture includes these invalid literals that should NOT be highlighted:

```swift
// Invalid prefixes (wrong case)
0B0   // should be 0b (lowercase)
0O7   // should be 0o (lowercase)
0X0   // should be 0x (lowercase)

// Invalid digits for base
0b02  // 2 is not valid in binary
0o08  // 8 is not valid in octal

// Invalid formatting
0b_0  // underscore immediately after prefix
0o_0  // underscore immediately after prefix
0x_0  // underscore immediately after prefix
_0    // leading underscore (not a number, it's an identifier)

// Invalid exponent
1e_1  // underscore in exponent before digits

// Invalid hex
0x0G  // G is not a hex digit

// Missing required parts
0x.1p1  // hex float needs integer part before decimal
0x0pA   // exponent must be decimal, not hex
```

## Proposed Solution

Add **negative lookahead** to ensure the number patterns don't match when followed by invalid continuation digits.

### Pattern Changes

```swift
// Binary - must not be followed by digits 2-9
ModeBox(Mode(match: .string(#"\b0b([01]_*)+(?![2-9])"#)))

// Octal - must not be followed by digits 8-9
ModeBox(Mode(match: .string(#"\b0o([0-7]_*)+(?![89])"#)))

// Hexadecimal - must not be followed by G-Z (invalid hex chars)
ModeBox(Mode(match: .string(#"\b0x(\#(hexDigits))(\.\#(hexDigits))?([pP][+-]?(\#(decimalDigits)))?(?![gG-zZ])"#)))
```

### Additional Fixes Needed

1. **Prevent underscore immediately after prefix:**
   ```swift
   // Current: \b0b([01]_*)+
   // Fixed:   \b0b[01]([01_]*[01])?
   // This requires at least one digit, and if underscores, must end with digit
   ```

2. **Handle uppercase prefix rejection:**
   The current patterns use lowercase `0b`, `0o`, `0x`. Uppercase `0B`, `0O`, `0X` are not valid in Swift and shouldn't match. This is already correct - just verify.

3. **Exponent underscore handling:**
   `1e_1` should not match because the exponent part `_1` starts with underscore.
   ```swift
   // Current exponent: [eE][+-]?(\#(decimalDigits))
   // The decimalDigits pattern is: ([0-9]_*)+
   // This should NOT match _1, so it should fail correctly
   // But need to verify it doesn't match just "1e" and leave "_1"
   ```

## Implementation Steps

1. **Reproduce the issue locally**
   ```bash
   swift test --filter testNumbers
   ```

2. **Create test cases for each invalid pattern**
   Write unit tests for:
   - `0b02` - should produce no number highlighting
   - `0o08` - should produce no number highlighting
   - `0x0G` - should produce no number highlighting
   - `0b_0` - should produce no number highlighting
   - `1e_1` - should produce no number highlighting

3. **Update binary pattern with negative lookahead**
   ```swift
   // Before
   ModeBox(Mode(match: .string(#"\b0b([01]_*)+"#)))
   // After
   ModeBox(Mode(match: .string(#"\b0b([01]_*)+(?![0-9])"#)))
   ```
   Note: Using `(?![0-9])` catches any following digit, since valid binary only has 0-1.

4. **Update octal pattern with negative lookahead**
   ```swift
   // Before
   ModeBox(Mode(match: .string(#"\b0o([0-7]_*)+"#)))
   // After
   ModeBox(Mode(match: .string(#"\b0o([0-7]_*)+(?![0-9])"#)))
   ```

5. **Update hex pattern** (if needed)
   Verify `0x0G` doesn't match, and if it does:
   ```swift
   // Add negative lookahead for invalid hex continuation
   #"\b0x(\#(hexDigits))...(?![gG-zZ])"#
   ```

6. **Verify exponent handling**
   Test that `1e_1` doesn't incorrectly match `1e` as a number.

7. **Run full test suite**
   ```bash
   swift test
   ```

## Files to Modify

- `Sources/SwiftHighlight/Languages/Swift.swift`
  - Lines 103-117: Update number pattern variants

## Test Cases to Verify

After implementation, these should NOT be highlighted as numbers:
```swift
0b02    // invalid binary digit
0b_0    // underscore after prefix
0o08    // invalid octal digit
0o_0    // underscore after prefix
0x_0    // underscore after prefix
0x0G    // invalid hex digit
0B0     // uppercase prefix
0O7     // uppercase prefix
0X0     // uppercase prefix
1e_1    // underscore in exponent
_0      // leading underscore (identifier)
```

These SHOULD be highlighted as numbers:
```swift
0b0
0b11
0b0_1_0
0o7
0o77
0o7_7
0x0
0xaF
0xa_F
123
1_000
1e10
1.5e-10
0x1.0p10
```

## Complexity Estimate

Low-Medium - straightforward regex changes, but need to test edge cases carefully.

## References

- `Swift.swift` lines 97-117 (number patterns)
- Swift Language Guide: Integer Literals, Floating-Point Literals
- Test fixture: `Tests/SwiftHighlightTests/Fixtures/swift/numbers.txt`
