import Benchmark
import SwiftHighlight
import HighlightSwift
import Foundation

let benchmarks = {
    // Simple Python code for quick benchmarks
    let simpleCode = "x = 42"

    // Medium complexity code
    let mediumCode = """
    def hello():
        print('Hello, World!')

    if __name__ == '__main__':
        hello()
    """

    // Complex code with various syntax elements
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

    // Metrics to measure: wall clock time and malloc
    let metrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountTotal,
    ]

    // MARK: - SwiftHighlight Benchmarks

    // Parse-only benchmarks (no HTML rendering)
    Benchmark(
        "SwiftHighlight: Parse Only - Simple",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()
        _ = await hljs.parse(simpleCode, language: "python")  // Warm up

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.parse(simpleCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Parse Only - Medium",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()
        _ = await hljs.parse(simpleCode, language: "python")  // Warm up

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.parse(mediumCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Parse Only - Complex",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()
        _ = await hljs.parse(simpleCode, language: "python")  // Warm up

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.parse(complexCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Simple Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(simpleCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Medium Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(mediumCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Complex Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(complexCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Cached Language",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()
        // Warm up the language cache
        _ = await hljs.highlight(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(await hljs.highlight(mediumCode, language: "python"))
        }
    }

    // MARK: - HighlightSwift Benchmarks

    Benchmark(
        "HighlightSwift: Simple Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let highlight = HighlightSwift.Highlight()

        for _ in benchmark.scaledIterations {
            let result = try! await highlight.request(simpleCode, mode: .language(.python))
            blackHole(result)
        }
    }

    Benchmark(
        "HighlightSwift: Medium Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let highlight = HighlightSwift.Highlight()

        for _ in benchmark.scaledIterations {
            let result = try! await highlight.request(mediumCode, mode: .language(.python))
            blackHole(result)
        }
    }

    Benchmark(
        "HighlightSwift: Complex Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let highlight = HighlightSwift.Highlight()

        for _ in benchmark.scaledIterations {
            let result = try! await highlight.request(complexCode, mode: .language(.python))
            blackHole(result)
        }
    }

    Benchmark(
        "HighlightSwift: Cached (reused instance)",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let highlight = HighlightSwift.Highlight()
        // Warm up
        _ = try! await highlight.request(simpleCode, mode: .language(.python))

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = try! await highlight.request(mediumCode, mode: .language(.python))
            blackHole(result)
        }
    }

    // MARK: - HTML to AttributedString Conversion Benchmark
    // This measures the overhead of NSAttributedString HTML parsing
    // which HighlightSwift does after getting HTML from JavaScriptCore

    // Actual HTML output from SwiftHighlight for the medium code (run once to capture)
    let swiftHighlightHTML = """
<span class="hljs-keyword">def</span> <span class="hljs-title function_">hello</span>():
    <span class="hljs-built_in">print</span>(<span class="hljs-string">&#x27;Hello, World!&#x27;</span>)

<span class="hljs-keyword">if</span> __name__ == <span class="hljs-string">&#x27;__main__&#x27;</span>:
    hello()
"""

    // Wrap with CSS like HighlightSwift does
    let wrappedHTML = """
<style>
.hljs-keyword { color: #cc7832; }
.hljs-string { color: #6a8759; }
.hljs-number { color: #6897bb; }
.hljs-comment { color: #808080; }
.hljs-built_in { color: #8888c6; }
.hljs-title { color: #ffc66d; }
</style>
<pre><code class="hljs">\(swiftHighlightHTML)</code></pre>
"""

    Benchmark(
        "HTML→AttributedString (SwiftHighlight HTML)",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let htmlData = wrappedHTML.data(using: .utf8)!

        for _ in benchmark.scaledIterations {
            let attributed = try! NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            blackHole(attributed)
        }
    }

    // Also add benchmark for just the SwiftHighlight HTML generation
    Benchmark(
        "SwiftHighlight: HTML only (no conversion)",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            let result = await hljs.highlight(mediumCode, language: "python")
            blackHole(result.value)
        }
    }

    // MARK: - AttributedString Comparison
    // Compare both libraries when outputting AttributedString

    Benchmark(
        "SwiftHighlight→AttributedString: Simple",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            let result = await hljs.highlight(simpleCode, language: "python")
            let wrappedHTML = """
            <style>
            .hljs-keyword { color: #cc7832; }
            .hljs-string { color: #6a8759; }
            .hljs-number { color: #6897bb; }
            .hljs-comment { color: #808080; }
            .hljs-built_in { color: #8888c6; }
            .hljs-title { color: #ffc66d; }
            </style>
            <pre><code class="hljs">\(result.value)</code></pre>
            """
            let htmlData = wrappedHTML.data(using: .utf8)!
            let attributed = try! NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            blackHole(attributed)
        }
    }

    Benchmark(
        "SwiftHighlight→AttributedString: Medium",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            let result = await hljs.highlight(mediumCode, language: "python")
            let wrappedHTML = """
            <style>
            .hljs-keyword { color: #cc7832; }
            .hljs-string { color: #6a8759; }
            .hljs-number { color: #6897bb; }
            .hljs-comment { color: #808080; }
            .hljs-built_in { color: #8888c6; }
            .hljs-title { color: #ffc66d; }
            </style>
            <pre><code class="hljs">\(result.value)</code></pre>
            """
            let htmlData = wrappedHTML.data(using: .utf8)!
            let attributed = try! NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            blackHole(attributed)
        }
    }

    Benchmark(
        "SwiftHighlight→AttributedString: Complex",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()

        for _ in benchmark.scaledIterations {
            let result = await hljs.highlight(complexCode, language: "python")
            let wrappedHTML = """
            <style>
            .hljs-keyword { color: #cc7832; }
            .hljs-string { color: #6a8759; }
            .hljs-number { color: #6897bb; }
            .hljs-comment { color: #808080; }
            .hljs-built_in { color: #8888c6; }
            .hljs-title { color: #ffc66d; }
            </style>
            <pre><code class="hljs">\(result.value)</code></pre>
            """
            let htmlData = wrappedHTML.data(using: .utf8)!
            let attributed = try! NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            blackHole(attributed)
        }
    }

    Benchmark(
        "SwiftHighlight→AttributedString: Cached",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        await hljs.registerPython()
        // Warm up the language cache
        _ = await hljs.highlight(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = await hljs.highlight(mediumCode, language: "python")
            let wrappedHTML = """
            <style>
            .hljs-keyword { color: #cc7832; }
            .hljs-string { color: #6a8759; }
            .hljs-number { color: #6897bb; }
            .hljs-comment { color: #808080; }
            .hljs-built_in { color: #8888c6; }
            .hljs-title { color: #ffc66d; }
            </style>
            <pre><code class="hljs">\(result.value)</code></pre>
            """
            let htmlData = wrappedHTML.data(using: .utf8)!
            let attributed = try! NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            blackHole(attributed)
        }
    }
}
