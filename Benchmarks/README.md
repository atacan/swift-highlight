# SwiftHighlight Benchmarks

Performance benchmarks comparing SwiftHighlight against alternative syntax highlighting libraries.

## Results Summary

### Highlight Libraries (p50 median, Python code)

Note: HighlightSwift is based on JavascriptCore.

#### HTML Output
| Library | Simple | Medium | Complex | Cached |
|---------|-------:|-------:|--------:|-------:|
| **highlight.js (Node.js)** | 3 μs | 10 μs | 66 μs | - |
| **SwiftHighlight** | 2,564 μs | 2,722 μs | 5,353 μs | 210 μs |
| **HighlightSwift** | - | - | - | - |

#### AttributedString Output
| Library | Simple | Medium | Complex | Cached |
|---------|-------:|-------:|--------:|-------:|
| **SwiftHighlight** | 3,858 μs | 4,518 μs | 10,000 μs | 2,013 μs |
| **HighlightSwift** | 16,000 μs | 16,000 μs | 22,000 μs | 2,441 μs |

### Relative Performance

**For AttributedString output:**
| Comparison | Cold Start | Cached |
|------------|-----------|--------|
| SwiftHighlight vs HighlightSwift | **2.2-4.1x faster** | **1.2x faster (17%)** |
| SwiftHighlight vs highlight.js (Node.js) | **~400-1000x slower** | - |

**For HTML output:**
| Comparison | Cold Start | Cached |
|------------|-----------|--------|
| SwiftHighlight vs HighlightSwift | **Not comparable*** | **Not comparable*** |
| SwiftHighlight vs highlight.js (Node.js) | **250-300x slower** | **20-70x slower** |

\* *HighlightSwift doesn't expose HTML-only output (it always converts to AttributedString)*

**Key Insight**: If you need AttributedString, SwiftHighlight is significantly faster than HighlightSwift! For HTML-only use cases, SwiftHighlight avoids the expensive HTML→AttributedString conversion entirely.

### Memory Allocations

| Library | Simple | Medium | Complex | Cached |
|---------|-------:|-------:|--------:|-------:|
| SwiftHighlight | 16,000 | 17,000 | 21,000 | 581 |
| HighlightSwift | 538 | 841 | 2,036 | 795 |
| HTML→AttributedString | - | 623 | - | - |

## Why the Performance Differences?

- **highlight.js (Node.js)**: V8's JIT-compiled regex engine is extremely optimized
- **SwiftHighlight**: Pure Swift using NSRegularExpression (14x slower than V8 regex)
- **HighlightSwift**: Uses JavaScriptCore + HTML→AttributedString conversion

### HighlightSwift Overhead Breakdown

HighlightSwift's `request()` method does two expensive operations:

| Step | Time (p50) | % of Total |
|------|-----------|------------|
| JavaScriptCore execution | ~832 μs | 34% |
| HTML→NSAttributedString | ~1,609 μs | 66% |
| **Total** | ~2,441 μs | 100% |

The HTML→AttributedString conversion (using `NSAttributedString(data:options:.html)`) is notoriously slow and accounts for **66% of HighlightSwift's time**. Unfortunately, HighlightSwift doesn't expose a way to get raw HTML without this conversion.

**Implication**: If you only need HTML output (not AttributedString), SwiftHighlight is actually competitive with HighlightSwift! SwiftHighlight generates HTML in ~2,722 μs vs HighlightSwift's total time of ~2,441 μs (which includes the expensive HTML→AttributedString conversion). For HTML-only use cases, SwiftHighlight is just 13% slower than HighlightSwift's cached performance.

### Regex Engine Comparison

| Engine | Performance |
|--------|-------------|
| Node.js (V8) | 6 μs |
| NSRegularExpression | 89 μs (14x slower) |
| Swift Regex | 918 μs (148x slower) |

## Running Benchmarks

### Swift Benchmarks

```bash
# Run all Swift benchmarks
cd Benchmarks
swift package --allow-writing-to-package-directory benchmark

# Run specific target
swift package --allow-writing-to-package-directory benchmark --target HighlightBenchmarks

# Run regex-only benchmarks
swift package --allow-writing-to-package-directory benchmark --target RegexBenchmarks

# Save results to history
swift package --allow-writing-to-package-directory benchmark --no-progress > "../history/benchmark_$(date +%Y-%m-%d_%H-%M-%S).txt" 2>&1
```

### Node.js Benchmarks

```bash
cd nodejs
npm install
node benchmark.js      # highlight.js benchmark
node regex-benchmark.js # regex-only benchmark
```

## Benchmark Targets

### HighlightBenchmarks
Compares full syntax highlighting:
- **SwiftHighlight**: This library
- **HighlightSwift**: JavaScriptCore-based alternative

Tests three Python code samples (simple, medium, complex) plus cached language performance.

### RegexBenchmarks
Compares regex engine performance:
- **NSRegularExpression**: Apple's ICU-based regex
- **Swift Regex**: Swift 5.7+ native regex

Tests common syntax highlighting patterns (keywords, strings, numbers, comments, identifiers, function calls).

### nodejs/
Compares JavaScript runtime performance:
- **Node.js**: V8 engine
- **Bun**: JavaScriptCore engine

## Key Findings

1. **SwiftHighlight is 2-4x faster than HighlightSwift for AttributedString output** - On cold starts: 2.2-4.1x faster. When cached: 1.2x faster (17% improvement)
2. **SwiftHighlight is the fastest pure Swift option** - Whether you need HTML or AttributedString, SwiftHighlight outperforms HighlightSwift
3. **HTML→AttributedString conversion is expensive** - Takes ~1,609 μs, accounting for 66% of HighlightSwift's total time. SwiftHighlight does this conversion in the same time but with faster highlighting.
4. **NSRegularExpression is the best Swift regex choice** - Swift Regex is 10x slower
5. **V8 regex is unbeatable** - SwiftHighlight is 250-300x slower than Node.js highlight.js due to regex engine differences
6. **Caching matters significantly** - Reusing a configured Highlight instance is 12-22x faster than cold start depending on use case

## Baseline and Compare

```bash
cd Benchmarks
# f566172 is the commit hash for example
# Create the benchmark
swift package --allow-writing-to-package-directory benchmark --target HighlightBenchmarks baseline update HighlightBenchmarks_f566172
# Compare against that benchmark
cd Benchmarks
swift package benchmark --target HighlightBenchmarks baseline compare HighlightBenchmarks_f566172
swift package benchmark --target MicroBenchmarks baseline compare MicroBenchmarks_f566172
```