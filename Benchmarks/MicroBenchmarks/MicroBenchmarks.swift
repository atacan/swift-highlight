import Benchmark
import SwiftHighlight
import Foundation

// MARK: - Test Data

let simpleCode = "x = 42"

let mediumCode = """
def hello():
    print('Hello, World!')

if __name__ == '__main__':
    hello()
"""

let complexCode = """
import os
from typing import List, Optional

@decorator
class MyClass:
    '''A sample class with various Python features.'''

    def __init__(self, value: int = 0):
        self.value = value
        self._private = None

    def process(self, items: List[str]) -> Optional[str]:
        # Process items and return result
        result = []
        for i, item in enumerate(items):
            if item.startswith('_'):
                continue
            result.append(f'{i}: {item}')
        return '\\n'.join(result) if result else None

    @property
    def computed(self) -> int:
        return self.value * 2

def main():
    obj = MyClass(42)
    data = ['alpha', '_beta', 'gamma', 'delta']
    output = obj.process(data)
    print(output)

if __name__ == '__main__':
    main()
"""

// Large code for stress testing
let largeCode = String(repeating: complexCode + "\n\n", count: 10)

// HTML sample for escaping benchmarks
let htmlTestString = """
<div class="container">
    <p>Hello & goodbye</p>
    <span data-value="test's \"quoted\"">Content here</span>
</div>
"""

let htmlTestStringLarge = String(repeating: htmlTestString, count: 100)

// MARK: - Metrics

let defaultMetrics: [BenchmarkMetric] = [
    .wallClock,
    .mallocCountTotal,
]

let benchmarks = {

    // =========================================================================
    // MARK: - Core Pipeline Benchmarks
    // These measure the full pipeline to track overall progress
    // =========================================================================

    Benchmark(
        "Core: Parse Only (no render)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let hljs = Highlight()
        await hljs.registerPython()
        // Warm up cache
        _ = await hljs.parse(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.parse(complexCode, language: "python"))
        }
    }

    Benchmark(
        "Core: Parse + HTML Render",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let hljs = Highlight()
        await hljs.registerPython()
        // Warm up cache
        _ = await hljs.highlight(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(complexCode, language: "python"))
        }
    }

    Benchmark(
        "Core: Large File (10x complex)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let hljs = Highlight()
        await hljs.registerPython()
        // Warm up cache
        _ = await hljs.highlight(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(largeCode, language: "python"))
        }
    }

    // =========================================================================
    // MARK: - H2: String Index Conversion Benchmarks
    // Measure cost of UTF-16 <-> String.Index conversions
    // =========================================================================

    Benchmark(
        "H2: String.Index(utf16Offset:) x1000",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let code = complexCode
        let utf16Count = code.utf16.count

        for _ in benchmark.scaledIterations {
            for i in stride(from: 0, to: utf16Count, by: max(1, utf16Count / 1000)) {
                let idx = String.Index(utf16Offset: i, in: code)
                blackHole(idx)
            }
        }
    }

    Benchmark(
        "H2: index(offsetBy:) sequential",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let code = complexCode
        let count = code.count

        for _ in benchmark.scaledIterations {
            var idx = code.startIndex
            for _ in 0..<min(count, 100) {
                idx = code.index(after: idx)
                blackHole(idx)
            }
        }
    }

    Benchmark(
        "H2: index(offsetBy:) random access",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let code = complexCode
        let count = code.count

        for _ in benchmark.scaledIterations {
            // Simulates the O(n²) pattern in emitMultiClass
            for offset in stride(from: 0, to: count, by: max(1, count / 50)) {
                let idx = code.index(code.startIndex, offsetBy: offset)
                blackHole(idx)
            }
        }
    }

    Benchmark(
        "H2: Substring creation",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let code = complexCode
        let count = code.count

        for _ in benchmark.scaledIterations {
            var pos = 0
            while pos < count - 10 {
                let start = code.index(code.startIndex, offsetBy: pos)
                let end = code.index(start, offsetBy: 10)
                let sub = String(code[start..<end])
                blackHole(sub)
                pos += 10
            }
        }
    }

    // =========================================================================
    // MARK: - H3: HTML Escaping Benchmarks
    // Measure different HTML escaping strategies
    // =========================================================================

    // Current implementation: 5 sequential replacingOccurrences calls
    Benchmark(
        "H3: escapeHTML (current - 5 passes)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var result = htmlTestStringLarge
            result = result.replacingOccurrences(of: "&", with: "&amp;")
            result = result.replacingOccurrences(of: "<", with: "&lt;")
            result = result.replacingOccurrences(of: ">", with: "&gt;")
            result = result.replacingOccurrences(of: "\"", with: "&quot;")
            result = result.replacingOccurrences(of: "'", with: "&#x27;")
            blackHole(result)
        }
    }

    // Single-pass character iteration
    Benchmark(
        "H3: escapeHTML (single pass)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var result = ""
            result.reserveCapacity(htmlTestStringLarge.count + htmlTestStringLarge.count / 10)
            for char in htmlTestStringLarge {
                switch char {
                case "&": result += "&amp;"
                case "<": result += "&lt;"
                case ">": result += "&gt;"
                case "\"": result += "&quot;"
                case "'": result += "&#x27;"
                default: result.append(char)
                }
            }
            blackHole(result)
        }
    }

    // Single-pass with Unicode scalars
    Benchmark(
        "H3: escapeHTML (scalars)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var result = ""
            result.reserveCapacity(htmlTestStringLarge.count + htmlTestStringLarge.count / 10)
            for scalar in htmlTestStringLarge.unicodeScalars {
                switch scalar {
                case "&": result += "&amp;"
                case "<": result += "&lt;"
                case ">": result += "&gt;"
                case "\"": result += "&quot;"
                case "'": result += "&#x27;"
                default: result.unicodeScalars.append(scalar)
                }
            }
            blackHole(result)
        }
    }

    // =========================================================================
    // MARK: - H4: String Accumulation Benchmarks
    // Measure different string building strategies
    // =========================================================================

    Benchmark(
        "H4: String += (current pattern)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let chunks = (0..<100).map { "chunk\($0) " }

        for _ in benchmark.scaledIterations {
            var buffer = ""
            for chunk in chunks {
                buffer += chunk
            }
            blackHole(buffer)
        }
    }

    Benchmark(
        "H4: String += with reserveCapacity",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let chunks = (0..<100).map { "chunk\($0) " }
        let totalLength = chunks.reduce(0) { $0 + $1.count }

        for _ in benchmark.scaledIterations {
            var buffer = ""
            buffer.reserveCapacity(totalLength)
            for chunk in chunks {
                buffer += chunk
            }
            blackHole(buffer)
        }
    }

    Benchmark(
        "H4: Array<String>.joined()",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let chunks = (0..<100).map { "chunk\($0) " }

        for _ in benchmark.scaledIterations {
            var parts: [String] = []
            parts.reserveCapacity(chunks.count)
            for chunk in chunks {
                parts.append(chunk)
            }
            let result = parts.joined()
            blackHole(result)
        }
    }

    Benchmark(
        "H4: Array<Substring>.joined()",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let source = (0..<100).map { "chunk\($0) " }.joined()
        // Pre-compute ranges
        var ranges: [Range<String.Index>] = []
        var pos = source.startIndex
        while pos < source.endIndex {
            let end = source.index(pos, offsetBy: min(8, source.distance(from: pos, to: source.endIndex)))
            ranges.append(pos..<end)
            pos = end
        }

        for _ in benchmark.scaledIterations {
            var parts: [Substring] = []
            parts.reserveCapacity(ranges.count)
            for range in ranges {
                parts.append(source[range])
            }
            let result = parts.joined()
            blackHole(result)
        }
    }

    // =========================================================================
    // MARK: - H5: Collection Scanning Benchmarks
    // Measure cost of scanning collections in hot paths
    // =========================================================================

    Benchmark(
        "H5: Dictionary.values.contains (current)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        // Simulate language registry with various case sensitivity settings
        struct FakeLanguage {
            let caseInsensitive: Bool
        }
        var languages: [String: FakeLanguage] = [:]
        for i in 0..<50 {
            languages["lang\(i)"] = FakeLanguage(caseInsensitive: i == 25)
        }

        for _ in benchmark.scaledIterations {
            // This is called for every text buffer in processKeywords
            for _ in 0..<100 {
                let result = languages.values.contains { $0.caseInsensitive }
                blackHole(result)
            }
        }
    }

    Benchmark(
        "H5: Cached boolean flag",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        // Pre-computed flag
        let cachedCaseInsensitive = true

        for _ in benchmark.scaledIterations {
            for _ in 0..<100 {
                blackHole(cachedCaseInsensitive)
            }
        }
    }

    // =========================================================================
    // MARK: - H6: Keyword Matching Benchmarks
    // Measure regex vs alternative keyword matching
    // =========================================================================

    let keywordPattern = try! NSRegularExpression(pattern: #"\w+"#)
    let keywords: Set<String> = ["if", "else", "for", "while", "def", "class", "return",
                                  "import", "from", "try", "except", "with", "as", "None",
                                  "True", "False", "and", "or", "not", "in", "is"]

    Benchmark(
        "H6: Keyword regex.matches() (current)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let text = complexCode
        let range = NSRange(text.startIndex..., in: text)

        for _ in benchmark.scaledIterations {
            let matches = keywordPattern.matches(in: text, range: range)
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let word = String(text[matchRange])
                    blackHole(keywords.contains(word))
                }
            }
        }
    }

    Benchmark(
        "H6: Keyword regex.enumerateMatches()",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let text = complexCode
        let range = NSRange(text.startIndex..., in: text)

        for _ in benchmark.scaledIterations {
            keywordPattern.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match = match,
                      let matchRange = Range(match.range, in: text) else { return }
                let word = String(text[matchRange])
                blackHole(keywords.contains(word))
            }
        }
    }

    // =========================================================================
    // MARK: - Regex Matching Strategy Comparison
    // Compare different ways of using NSRegularExpression
    // (Swift Regex comparison is in RegexBenchmarks)
    // =========================================================================

    let nsPattern = try! NSRegularExpression(
        pattern: #"["'].*?["']|//.*|\b\d+\.?\d*\b|\b\w+\b"#
    )

    Benchmark(
        "Regex: NSRegex.matches() - collects all",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let text = complexCode
        let range = NSRange(text.startIndex..., in: text)

        for _ in benchmark.scaledIterations {
            blackHole(nsPattern.matches(in: text, range: range))
        }
    }

    Benchmark(
        "Regex: NSRegex.firstMatch() loop",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let text = complexCode

        for _ in benchmark.scaledIterations {
            var searchStart = 0
            let utf16Count = text.utf16.count
            var matchCount = 0
            while searchStart < utf16Count {
                let range = NSRange(location: searchStart, length: utf16Count - searchStart)
                guard let match = nsPattern.firstMatch(in: text, range: range) else { break }
                matchCount += 1
                searchStart = match.range.upperBound
            }
            blackHole(matchCount)
        }
    }

    Benchmark(
        "Regex: NSRegex.enumerateMatches()",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        let text = complexCode
        let range = NSRange(text.startIndex..., in: text)

        for _ in benchmark.scaledIterations {
            var matchCount = 0
            nsPattern.enumerateMatches(in: text, range: range) { _, _, _ in
                matchCount += 1
            }
            blackHole(matchCount)
        }
    }

    // =========================================================================
    // MARK: - Token Tree Allocation
    // Measure tree building overhead
    // =========================================================================

    Benchmark(
        "TokenTree: Array append (simulated)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        // Simulate building a token tree
        enum Token {
            case text(String)
            case scopeStart(String)
            case scopeEnd
        }

        for _ in benchmark.scaledIterations {
            var tokens: [Token] = []
            tokens.reserveCapacity(500)

            for i in 0..<100 {
                tokens.append(.scopeStart("scope\(i % 10)"))
                tokens.append(.text("content\(i)"))
                tokens.append(.scopeEnd)
            }
            blackHole(tokens)
        }
    }

    Benchmark(
        "TokenTree: Class-based tree (current pattern)",
        configuration: .init(metrics: defaultMetrics)
    ) { benchmark in
        class Node {
            var scope: String?
            var children: [Any] = []
        }

        for _ in benchmark.scaledIterations {
            let root = Node()
            var stack: [Node] = [root]

            for i in 0..<100 {
                let node = Node()
                node.scope = "scope\(i % 10)"
                stack.last?.children.append(node)
                stack.append(node)

                stack.last?.children.append("content\(i)")

                _ = stack.popLast()
            }
            blackHole(root)
        }
    }
}
