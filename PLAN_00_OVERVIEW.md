# Swift Highlighting Issues - Implementation Plans Overview

This document provides an overview of the remaining Swift test failures and links to detailed implementation plans.

## Current Test Status

| Test Suite | Passing | Total |
|------------|---------|-------|
| JSON       | 1       | 1     |
| Python     | 12      | 12    |
| Swift      | 15      | 20    |

## Failing Swift Tests

| Test | Issue | Plan | Priority | Complexity |
|------|-------|------|----------|------------|
| `testFunctions` | Generic brackets `<T>` highlighted as operators | [PLAN_01](./PLAN_01_GENERIC_BRACKETS.md) | High | Medium |
| `testTypes` | Closing `>` in `Array<Array<Int?>>` highlighted as operator | [PLAN_01](./PLAN_01_GENERIC_BRACKETS.md) | High | Medium |
| `testNumbers` | Invalid literals like `0b02` partially matched | [PLAN_02](./PLAN_02_INVALID_NUMBERS.md) | Medium | Low-Medium |
| `testParameterpack` | `other:` and `another:` not highlighted as params | [PLAN_03](./PLAN_03_PARAMETER_NAMES.md) | Medium | Medium |
| `testStrings` | Operators/numbers inside interpolation not highlighted | [PLAN_04](./PLAN_04_STRING_INTERPOLATION.md) | High | Medium-High |

## Issue Categories

### 1. Generic Brackets vs Operators (PLAN_01)
**Tests:** `testFunctions`, `testTypes`

The operator pattern matches `<` and `>` too eagerly, highlighting generic type brackets as operators.

**Example:**
```swift
func < <T>() { }          // <T> should not be operators
Array<Array<Int?>>        // final > should not be operator
```

### 2. Invalid Number Literals (PLAN_02)
**Tests:** `testNumbers`

Number patterns don't have proper boundary checks, causing partial matches of invalid literals.

**Example:**
```swift
0b02    // Should be plain text (2 invalid in binary)
        // Currently: 0b0 (number) + 2 (number)
```

### 3. Keywords + Contains Incompatibility (PLAN_03, PLAN_04)
**Tests:** `testParameterpack`, `testStrings`

Modes with both `keywords` and `contains` properties cannot fully highlight content using their `contains` modes. This is a known architectural issue (see `ARCHITECTURE_ISSUES.md`).

A partial fix was implemented for "match-only" modes, but:
- **PLAN_03:** Parameter names use begin/end modes, not match-only
- **PLAN_04:** Operators between keywords are not processed

## Recommended Fix Order

1. **PLAN_02 (Invalid Numbers)** - Simplest fix, low risk
2. **PLAN_01 (Generic Brackets)** - Important for Swift code, moderate complexity
3. **PLAN_04 (String Interpolation)** - May provide foundation for PLAN_03
4. **PLAN_03 (Parameter Names)** - May be solved by PLAN_04 changes

## Common Files Modified

Most fixes will involve:
- `Sources/SwiftHighlight/Languages/Swift.swift` - Language definition
- `Sources/SwiftHighlight/SwiftHighlight.swift` - Core highlighting logic

## Testing Commands

```bash
# Run specific test
swift test --filter testFunctions
swift test --filter testNumbers
swift test --filter testParameterpack
swift test --filter testStrings
swift test --filter testTypes

# Run all Swift fixture tests
swift test --filter SwiftFixtureTests

# Run full test suite
swift test

# Run with verbose output
swift test 2>&1 | grep -E "passed|failed|error"
```

## Related Documentation

- `ARCHITECTURE_ISSUES.md` - Documents the Keywords + Contains architectural issue
- `notes/spec.md` - Original API design document
- `highlight.js/` - Reference JavaScript implementation (git submodule)
