import Benchmark
import SwiftHighlight
import HighlightSwift

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

    Benchmark(
        "SwiftHighlight: Simple Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(hljs.highlight(simpleCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Medium Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(hljs.highlight(mediumCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Complex Code",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        hljs.registerPython()

        for _ in benchmark.scaledIterations {
            blackHole(hljs.highlight(complexCode, language: "python"))
        }
    }

    Benchmark(
        "SwiftHighlight: Cached Language",
        configuration: .init(metrics: metrics)
    ) { benchmark in
        let hljs = SwiftHighlight.Highlight()
        hljs.registerPython()
        // Warm up the language cache
        _ = hljs.highlight(simpleCode, language: "python")

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(hljs.highlight(mediumCode, language: "python"))
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
}
