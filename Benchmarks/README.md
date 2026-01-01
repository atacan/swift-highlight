# SwiftHighlight Benchmarks

Performance benchmarks comparing SwiftHighlight against alternative syntax highlighting libraries.

## Results Summary

### Highlight Libraries (p50 median, Python code)

| Library | Simple | Medium | Complex | Cached |
|---------|-------:|-------:|--------:|-------:|
| **highlight.js (Node.js)** | 3 μs | 10 μs | 66 μs | - |
| **SwiftHighlight** | 547 μs | 571 μs | 818 μs | 69 μs |
| **HighlightSwift** | 15,000 μs | 16,000 μs | 20,000 μs | 2,208 μs |

### Relative Performance

| Comparison | Result |
|------------|--------|
| SwiftHighlight vs HighlightSwift | **24-32x faster** |
| SwiftHighlight vs highlight.js (Node.js) | 8-12x slower |

### Memory Allocations

| Library | Simple | Medium | Complex | Cached |
|---------|-------:|-------:|--------:|-------:|
| SwiftHighlight | 4,863 | 5,147 | 7,139 | 339 |
| HighlightSwift | 538 | 841 | 2,036 | 795 |

## Why the Performance Differences?

- **highlight.js (Node.js)**: V8's JIT-compiled regex engine is extremely optimized
- **SwiftHighlight**: Pure Swift using NSRegularExpression (14x slower than V8 regex)
- **HighlightSwift**: Uses JavaScriptCore to run highlight.js, adding significant bridge overhead

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

1. **SwiftHighlight is the fastest pure Swift option** - 24-32x faster than HighlightSwift
2. **NSRegularExpression is the best regex choice** - Swift Regex is 10x slower
3. **V8 regex is unbeatable** - No Swift regex engine comes close to V8's performance
4. **Caching matters** - Reusing a configured Highlight instance is 8x faster than cold start
