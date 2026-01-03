# Performance Optimization Hypotheses

## Current State

Based on benchmark results (2026-01-01):

| Test | SwiftHighlight | HighlightSwift (JSCore) | Node.js highlight.js |
|------|----------------|-------------------------|----------------------|
| Simple Code | ~2.6ms | ~15ms | ~17μs |
| Medium Code | ~2.8ms | ~15ms | ~26μs |
| Complex Code | ~5.4ms | ~20ms | ~42μs |
| Cached Language | ~208μs | ~2ms | N/A |

**Observation**: SwiftHighlight is ~6x faster than JavaScriptCore-based HighlightSwift, but ~100-150x slower than Node.js running the original highlight.js. This is significant because:
1. V8 (Node.js) has highly optimized JIT compilation for regex
2. NSRegularExpression is ICU-based and not as optimized for repeated matching
3. Swift String operations with UTF-16 conversions add overhead

---

## High-Priority Hypotheses

### H1: NSRegularExpression Overhead (HIGH IMPACT)

**Problem**: NSRegularExpression is significantly slower than JavaScript regex engines due to:
- No JIT compilation
- ICU-based implementation with Unicode overhead
- Object allocation for each match result (NSTextCheckingResult)

**Evidence**: The parsing loop at `SwiftHighlight.swift:285-374` calls `top.matcher?.exec(code)` repeatedly. Each call:
1. Creates an NSTextCheckingResult object
2. Performs UTF-16 based matching
3. Allocates Range objects

**Potential Solutions**:
1. ~~**Swift Regex (iOS 16+/macOS 13+)**~~: **REJECTED** - Benchmarks show Swift Regex is 5-24x SLOWER than NSRegularExpression (see benchmark section below)
2. **Custom finite automaton**: For simple patterns (keywords, identifiers), build a custom DFA that doesn't use regex
3. **PCRE2 or RE2**: Consider linking against faster C regex libraries
4. **Pattern caching with pre-computed offsets**: Cache more information about patterns to reduce per-match overhead
5. **Reduce ObjC bridging**: The 27% ObjC/bridging overhead exceeds the 18% regex engine time

**Estimated Impact**: 20-30% improvement (primarily from reducing bridging, not changing regex engine)

---

### H2: String Index Conversions (LOW IMPACT - per Instruments)

**Problem**: The code extensively converts between Swift String indices and UTF-16 offsets because NSRegularExpression uses UTF-16.

**Locations**:
- `SwiftHighlight.swift:300-316` - Main parsing loop
- `SwiftHighlight.swift:610` - doEndMatch
- `SwiftHighlight.swift:745-768` - emitMultiClass (O(n²) index calculations)

**Code Pattern**:
```swift
let startIndex = String.Index(utf16Offset: utf16Index, in: code)
let endIndex = String.Index(utf16Offset: match.index, in: code)
let beforeMatch = String(code[startIndex..<endIndex])  // Substring allocation
```

**Potential Solutions**:
1. **Work entirely in UTF-16**: Store code as `[UInt16]` array and only convert to String when needed for output
2. **Pre-compute index map**: Build a UTF-16 offset → String.Index map once at start
3. **Use Substring instead of String**: `String(code[...])` allocates; keep as Substring until output
4. **Batch index calculations**: In emitMultiClass, iterate linearly instead of calling `index(offsetBy:)` repeatedly

**Estimated Impact**: ~~15-30%~~ **0.5-1%** (Instruments shows String Indexing is only 2.0% of total time)

---

### H3: HTML Escaping Multiple Passes (MEDIUM IMPACT)

**Problem**: `HTMLRenderer.escapeHTML()` and `Utils.escapeHTML()` make 5 sequential `replacingOccurrences()` calls:

```swift
result = result.replacingOccurrences(of: "&", with: "&amp;")
result = result.replacingOccurrences(of: "<", with: "&lt;")
// ... 3 more passes
```

**Potential Solutions**:
1. **Single-pass escaping**: Iterate characters once, building output string
2. **Character lookup table**: Use ASCII table for O(1) lookup
3. **Vectorized escaping**: Use SIMD to scan for special characters

**Implementation**:
```swift
static func escapeHTMLFast(_ value: String) -> String {
    var result = ""
    result.reserveCapacity(value.count + value.count / 10)  // Estimate extra capacity
    for char in value {
        switch char {
        case "&": result += "&amp;"
        case "<": result += "&lt;"
        case ">": result += "&gt;"
        case "\"": result += "&quot;"
        case "'": result += "&#x27;"
        default: result.append(char)
        }
    }
    return result
}
```

**Estimated Impact**: ~~10-20%~~ **2-3% overall** (HTML Rendering is 6% of time; 41% improvement × 6% = 2.5% total)

---

### H4: String Accumulation Pattern (LOW IMPACT - per Instruments)

**Problem**: Mode buffer uses `+=` for string concatenation:

```swift
var modeBuffer = ""
// ...
modeBuffer += remaining    // Line 303
modeBuffer += beforeMatch  // Line 315
modeBuffer += lexeme       // Line 354
```

Each `+=` potentially reallocates the underlying storage.

**Potential Solutions**:
1. **Pre-sized buffer**: `modeBuffer.reserveCapacity(code.count)` at start
2. **Array of substrings**: Collect `[Substring]` and join once at end
3. **ContiguousArray<UInt8>**: Work with bytes directly

**Estimated Impact**: ~~10-15%~~ **<0.5% time** (String Building is 2.6% of time; main benefit is **71% malloc reduction**)

---

### H5: Case-Insensitivity Check in Hot Path (QUICK WIN)

**Problem**: In `processKeywords()` at line 432:
```swift
let useCaseInsensitive = languages.values.contains { $0.caseInsensitive }
```

This iterates ALL registered languages on EVERY `processKeywords` call (potentially hundreds of times per file).

**Potential Solutions**:
1. **Cache at compile time**: Store `caseInsensitive` flag in `CompiledMode`
2. **Store in language compilation**: Pass flag through from `ModeCompiler`
3. **Check only current language**: `language.caseInsensitive` instead of scanning all

**Estimated Impact**: **56x faster** per call (benchmark: 7μs → 0.125μs). Trivial fix with no risk.

---

## Medium-Priority Hypotheses

### H6: Keyword Pattern Matching (MEDIUM IMPACT)

**Problem**: Keywords are matched using NSRegularExpression:
```swift
let matches = patternRe.matches(in: text, options: [], range: range)  // Line 429
```

This collects ALL matches into an array upfront.

**Potential Solutions**:
1. **Lazy iteration**: Use `enumerateMatches` instead of `matches`
2. **Trie-based lookup**: Build a trie for keyword matching instead of regex
3. **Boyer-Moore for keywords**: For exact keyword matching, use string search algorithms

**Estimated Impact**: 10-20% for keyword-heavy code

---

### H7: Token Tree Allocation (LOW TIME IMPACT, HIGH MALLOC IMPACT)

**Problem**: Every scope/text node creates object allocations:
- `MutableScopeNode` class instances
- `MutableTokenNode` enum cases
- Final `freeze()` creates immutable copies

**Potential Solutions**:
1. **Arena allocation**: Use a memory pool for nodes
2. **Flat array representation**: Store tree as `[(type, start, end, scope)]` array
3. **Streaming output**: For HTML, emit directly without building intermediate tree

**Estimated Impact**: ~~10-15%~~ **<0.3% time** (Token Tree is only 0.4% of runtime), but **210x malloc reduction** which helps cache efficiency

---

### H8: ResumableMultiRegex Compilation (LOW-MEDIUM IMPACT)

**Problem**: `getMatcher()` creates new `MultiRegex` instances on demand:
```swift
private func getMatcher(_ index: Int) -> MultiRegex {
    if let existing = multiRegexes[index] { return existing }
    let matcher = MultiRegex(...)
    // ... recompiles patterns
}
```

**Potential Solutions**:
1. **Pre-compile all matchers**: During mode compilation, create all possible matchers
2. **Limit resumable indices**: Most resumes happen at index 0; optimize for that case
3. **Share compiled regex**: Multiple matchers could share underlying NSRegularExpression

**Estimated Impact**: 5-10% improvement

---

### H9: Backreference Rewriting (LOW IMPACT)

**Problem**: `Regex.rewriteBackreferences()` in `RegexUtils.swift:84-144` does complex string manipulation to combine patterns.

**Potential Solutions**:
1. **Cache rewritten patterns**: Store results of pattern combination
2. **Avoid backreferences in language definitions**: Simpler patterns = faster compilation
3. **Pre-compute at mode definition time**: Do rewriting once when language is registered

**Estimated Impact**: 2-5% improvement (compile time only)

---

## Low-Priority Hypotheses

### H10: Actor Isolation Overhead

**Problem**: `Highlight` is an actor, requiring async/await for all API calls.

**Potential Solutions**:
1. **Provide synchronous API**: Separate non-isolated methods for single-threaded use
2. **MainActor version**: For UI use cases
3. **Sendable state sharing**: Allow compiled languages to be shared without actor

**Estimated Impact**: 2-5% improvement (mostly API ergonomics)

---

### H11: Mode Parent Chain Traversal

**Problem**: `doEndMatch()` traverses parent chain:
```swift
var current: CompiledMode? = top
while current !== endMode.parent {
    if current?.scope != nil { emitter.closeNode() }
    current = current?.parent
}
```

**Potential Solutions**:
1. **Cache chain depth**: Know how many levels to pop without traversing
2. **Indexed stack**: Use array indices instead of parent pointers

**Estimated Impact**: 1-3% improvement

---

## Experimental/Radical Hypotheses

### ~~H12: Port to Swift Regex Completely~~ **REJECTED**

~~Replace NSRegularExpression entirely with Swift's `Regex` type (requires iOS 16+/macOS 13+)~~

**Status**: **REJECTED** - Benchmarks prove Swift Regex is **5-24x SLOWER** than NSRegularExpression. See "Swift Regex vs NSRegularExpression Benchmark" section below.

---

### H13: WebAssembly/V8 Hybrid

For maximum compatibility with highlight.js, run the actual JavaScript through:
- JavaScriptCore (current HighlightSwift approach, slow)
- Embedded V8 (complex but fast)
- WebAssembly compilation of highlight.js

**Estimated Impact**: Could match Node.js performance
**Tradeoff**: Adds large dependency, complexity

---

### H14: Custom Lexer Generator

Instead of runtime regex interpretation, generate Swift code for each language:

```swift
// Generated for Python
func tokenizePython(_ code: String) -> [Token] {
    // Hard-coded state machine
    // No regex overhead
}
```

**Estimated Impact**: 50-80% improvement
**Tradeoff**: Requires build-time code generation, larger binary size

---

## Benchmark Results (2026-01-03 Baseline)

### Core Performance
| Benchmark | Time (p50) | Mallocs |
|-----------|-----------|---------|
| Parse Only (complex) | 2.6ms | 2,879 |
| Parse + HTML Render | 2.8ms | 4,852 |
| Large File (10x) | 32ms | 48K |

**Key insight**: Rendering adds only ~7% overhead. Parsing is the bottleneck.

### H2: String Index Operations
| Operation | Time (p50) |
|-----------|-----------|
| utf16Offset x1000 | 13μs |
| Random offsetBy | 30μs |
| Sequential index(after:) | 0.9μs |
| Substring creation | 44μs |

**Finding**: String index operations are fast. Not the major bottleneck.

### H3: HTML Escaping
| Approach | Time (p50) | Mallocs |
|----------|-----------|---------|
| Current (5 passes) | 312μs | 53 |
| Single pass (chars) | 272μs | 2 |
| Scalars | **183μs** | **2** |

**Finding**: Scalars approach is **41% faster** with **96% fewer allocations**. Easy win!

### H4: String Accumulation
| Approach | Time (p50) | Mallocs |
|----------|-----------|---------|
| String += | 4.8μs | 7 |
| += with reserveCapacity | 4.5μs | **2** |
| Array.joined() | 4.9μs | 6 |

**Finding**: reserveCapacity reduces mallocs by 71% with minimal time impact.

### H5: Case-Insensitive Check
| Approach | Time (p50) |
|----------|-----------|
| Dictionary.values.contains | 7μs |
| Cached boolean | **0.125μs** |

**Finding**: Caching is **56x faster**. Very easy win!

### H6: Keyword Matching
| Approach | Time (p50) | Mallocs |
|----------|-----------|---------|
| matches() | 18μs | 111 |
| enumerateMatches() | **16μs** | **101** |

**Finding**: enumerateMatches() is ~10% faster with fewer mallocs.

### Regex Matching Strategy
| Approach | Time (p50) |
|----------|-----------|
| matches() | 17μs |
| enumerateMatches() | **15μs** |
| firstMatch() loop | 25μs |

**Finding**: Current approach (matches()) is reasonable.

### Token Tree Allocation
| Approach | Time (p50) | Mallocs |
|----------|-----------|---------|
| Array append (flat) | 2.7μs | 1 |
| Class-based tree | 13μs | 210 |

**Finding**: Flat array would be **5x faster** with **210x fewer mallocs**. Major potential win but requires architecture change.

---

## Instruments Profiling Results (2026-01-03)

Ran 1000 iterations of `highlight(complexCode, language: "python")` with Time Profiler:

| Category | Samples | % of Total |
|----------|---------|------------|
| **Regex Engine (ICU)** | 151 | **17.8%** |
| **Swift-ObjC Bridging** | 106 | **12.5%** |
| **ObjC Runtime** | 94 | **11.1%** |
| Memory Allocation | 64 | 7.6% |
| HTML Rendering | 51 | 6.0% |
| Swift Runtime | 32 | 3.8% |
| Parser Core | 26 | 3.1% |
| String Building (+=) | 22 | 2.6% |
| String Indexing | 17 | 2.0% |
| NSRegularExpression | 17 | 2.0% |
| Keyword Lookup | 17 | 2.0% |
| Array Allocation | 12 | 1.4% |
| Mode Matching | 9 | 1.1% |
| Token Tree | 3 | 0.4% |
| Other | 225 | 26.6% |

### Critical Insight: ObjC/Bridging Overhead

**Total Regex-related: 20.9%** (ICU + NSRegularExpression + Mode Matching)
**Total ObjC/Bridging overhead: 27.4%** (Bridging + ObjC Runtime + Swift Runtime)

The ObjC bridging overhead is **larger than the regex engine itself**! This is caused by:
1. Converting Swift Strings to NSStrings for NSRegularExpression
2. NSTextCheckingResult allocations and autoreleases
3. Range conversions between Swift and Foundation

### Updated Hypothesis Priority

Based on profiling, the biggest wins come from:
1. **Reducing Foundation/ObjC calls** (27.4% overhead)
2. **Regex engine optimization** (20.9%)
3. **Memory allocation reduction** (7.6%)
4. **HTML rendering optimization** (6.0%)

---

## Additional Optimizations (Identified via Profiling)

### H15: Autorelease Pool Overhead

**Problem**: Every NSRegularExpression match creates autoreleased NSTextCheckingResult objects. In tight loops (1000+ iterations), these pile up until the autorelease pool drains.

**Evidence**: Memory Allocation shows 7.6% of total time. NSTextCheckingResult allocations compound with ObjC runtime overhead.

**Potential Solutions**:
```swift
// Wrap tight loops to release objects eagerly
autoreleasepool {
    for match in pattern.matches(in: text, range: range) {
        // Process match
    }
}
```

**Estimated Impact**: 2-5% time reduction, significant memory pressure reduction

---

### H16: UTF-16 String Caching

**Problem**: `code.utf16.count` and `String.Index(utf16Offset:in:)` both traverse the string. Called repeatedly in hot paths.

**Evidence**: String Indexing is 2.0% of time, but called thousands of times per file.

**Potential Solutions**:
```swift
// Cache at start of _highlight()
let utf16View = code.utf16
let utf16Count = utf16View.count

// Or more aggressively:
let utf16Array = ContiguousArray(code.utf16)  // O(1) index access
```

**Estimated Impact**: 0.5-1% time reduction

---

### H17: NSRange Precomputation

**Problem**: `NSRange(location:length:)` is called for every pattern match. Creating NSRange involves ObjC bridging.

**Evidence**: Part of the 12.5% Swift-ObjC Bridging overhead.

**Potential Solutions**:
```swift
// Precompute the full-text range once
let fullRange = NSRange(code.startIndex..., in: code)

// Or keep track of search ranges in UTF-16 units directly
var searchStart: Int = 0
let searchRange = NSRange(location: searchStart, length: utf16Count - searchStart)
```

**Estimated Impact**: 0.5-1% time reduction

---

### H18: Object Pooling for Hot Paths

**Problem**: Allocating and deallocating objects in tight loops creates GC pressure and cache thrashing.

**Evidence**: Memory Allocation is 7.6%, Array Allocation is 1.4%.

**Potential Solutions**:
1. **Reuse match result arrays**: Pre-allocate and clear instead of creating new arrays
2. **Pool CompiledMode lookups**: Cache frequently accessed modes
3. **Lazy token tree building**: Build output directly instead of intermediate structure

**Estimated Impact**: 3-5% time reduction, significant malloc reduction

---

## Revised Recommended Order (Based on Profiling + Benchmarks)

### Quick Wins (< 1 day each)
| Priority | Hypothesis | Expected Impact | Effort |
|----------|------------|-----------------|--------|
| 1 | **H5**: Cache case-insensitive flag | 56x per-call speedup | 15 min |
| 2 | **H3**: HTML escaping with scalars | 41% faster (2.5% total) | 2 hours |
| 3 | **H4**: reserveCapacity on buffers | 71% malloc reduction | 30 min |
| 4 | **H17**: Precompute NSRange | 0.5-1% bridging reduction | 1 hour |

### Medium Effort (1-3 days)
| Priority | Hypothesis | Expected Impact | Effort |
|----------|------------|-----------------|--------|
| 5 | **H16**: Cache UTF-16 view/count | 0.5-1% | 4 hours |
| 6 | **H15**: Autorelease pools | 2-5% | 4 hours |
| 7 | **H6**: enumerateMatches vs matches | 10% keyword time | 2 hours |
| 8 | **H18**: Object pooling | 3-5% | 1-2 days |

### Major Rework (1+ week)
| Priority | Hypothesis | Expected Impact | Effort |
|----------|------------|-----------------|--------|
| 9 | **H7**: Flat token array | 5x faster, 210x fewer mallocs | 3-5 days |
| 10 | **H1**: Custom DFA for keywords | 15-20% | 1-2 weeks |
| 11 | **H14**: Generated lexers | 50-80% | 2+ weeks |

### Rejected
| Hypothesis | Reason |
|------------|--------|
| **H12**: Swift Regex | 5-24x SLOWER than NSRegularExpression |
| **H13**: WebAssembly/V8 | Too much complexity for uncertain gain |

---

## Swift Regex vs NSRegularExpression Benchmark (2026-01-03)

**CRITICAL FINDING: Swift Regex is 5-24x SLOWER than NSRegularExpression!**

| Pattern | NSRegex (p50) | SwiftRegex (p50) | NSRegex Speedup |
|---------|---------------|------------------|-----------------|
| comment | 3.5μs | 17μs | **4.9x faster** |
| number | 4.1μs | 99μs | **24x faster** |
| string | 8.6μs | 37μs | **4.3x faster** |
| identifier | 16μs | 93μs | **5.8x faster** |
| functionCall | 31μs | 148μs | **4.8x faster** |
| keyword | 34μs | 470μs | **13.8x faster** |
| ALL patterns | 87μs | 879μs | **10x faster** |
| combined alternation | 23μs | 289μs | **12.6x faster** |
| firstMatch loop | 22μs | 127μs | **5.8x faster** |
| combined firstMatch | 22μs | 295μs | **13.4x faster** |

### Implications

1. **Do NOT switch to Swift Regex** - it would make performance worse
2. **Keep NSRegularExpression** - ICU's regex engine is highly optimized
3. **Focus on reducing bridging overhead** - the 27% overhead is from Swift↔ObjC bridging, not from regex itself
4. **Consider caching** - cache UTF-16 views and NSRange conversions

### Why is Swift Regex slower?

Swift Regex is designed for:
- Type safety and compile-time checking
- Generic output types with capture groups
- Integration with Swift's String model (grapheme clusters)

It is NOT optimized for:
- Raw throughput on simple patterns
- Repeated matching in tight loops
- Low-level byte-oriented matching

ICU's regex engine (used by NSRegularExpression) is a mature, highly optimized C++ implementation that operates directly on UTF-16 code units.

---

## Measurement Plan

For each optimization:
1. Run current benchmarks as baseline
2. Implement change in isolation
3. Run benchmarks again
4. Compare p50 times and malloc counts
5. If >5% improvement AND no regressions, keep the change

Use:
```bash
swift package --package-path Benchmarks --allow-writing-to-package-directory benchmark
```
