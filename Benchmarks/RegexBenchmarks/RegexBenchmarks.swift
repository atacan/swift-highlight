import Benchmark
import Foundation

let testCode = """
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

// Pre-compiled regex patterns
let keywordPatternNS = try! NSRegularExpression(pattern: #"\b(if|else|for|while|def|class|return|import|from|try|except|finally|with|as|lambda|yield|raise|pass|break|continue|global|nonlocal|assert|del|in|not|and|or|is|None|True|False)\b"#)
let stringPatternNS = try! NSRegularExpression(pattern: #"(["'])(?:(?!\1|\\).|\\.)*\1"#)
let numberPatternNS = try! NSRegularExpression(pattern: #"\b\d+\.?\d*(?:[eE][+-]?\d+)?\b"#)
let commentPatternNS = try! NSRegularExpression(pattern: #"#.*"#)
let functionCallPatternNS = try! NSRegularExpression(pattern: #"\b([a-zA-Z_]\w*)\s*\("#)
let identifierPatternNS = try! NSRegularExpression(pattern: #"\b[a-zA-Z_]\w*\b"#)

let keywordPatternSwift = try! Regex(#"\b(if|else|for|while|def|class|return|import|from|try|except|finally|with|as|lambda|yield|raise|pass|break|continue|global|nonlocal|assert|del|in|not|and|or|is|None|True|False)\b"#)
let stringPatternSwift = try! Regex(#"(["'])(?:(?!\1|\\).|\\.)*\1"#)
let numberPatternSwift = try! Regex(#"\b\d+\.?\d*(?:[eE][+-]?\d+)?\b"#)
let commentPatternSwift = try! Regex(#"#.*"#)
let functionCallPatternSwift = try! Regex(#"\b([a-zA-Z_]\w*)\s*\("#)
let identifierPatternSwift = try! Regex(#"\b[a-zA-Z_]\w*\b"#)

let benchmarks = {
    let metrics: [BenchmarkMetric] = [.wallClock, .mallocCountTotal]
    let range = NSRange(testCode.startIndex..., in: testCode)

    // MARK: - NSRegularExpression Benchmarks

    Benchmark("NSRegex: keyword", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(keywordPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: string", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(stringPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: number", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(numberPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: comment", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(commentPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: functionCall", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(functionCallPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: identifier", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(identifierPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("NSRegex: ALL patterns", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(keywordPatternNS.matches(in: testCode, range: range))
            blackHole(stringPatternNS.matches(in: testCode, range: range))
            blackHole(numberPatternNS.matches(in: testCode, range: range))
            blackHole(commentPatternNS.matches(in: testCode, range: range))
            blackHole(functionCallPatternNS.matches(in: testCode, range: range))
            blackHole(identifierPatternNS.matches(in: testCode, range: range))
        }
    }

    // MARK: - Swift Regex Benchmarks

    Benchmark("SwiftRegex: keyword", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: keywordPatternSwift))
        }
    }

    Benchmark("SwiftRegex: string", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: stringPatternSwift))
        }
    }

    Benchmark("SwiftRegex: number", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: numberPatternSwift))
        }
    }

    Benchmark("SwiftRegex: comment", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: commentPatternSwift))
        }
    }

    Benchmark("SwiftRegex: functionCall", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: functionCallPatternSwift))
        }
    }

    Benchmark("SwiftRegex: identifier", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: identifierPatternSwift))
        }
    }

    Benchmark("SwiftRegex: ALL patterns", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: keywordPatternSwift))
            blackHole(testCode.matches(of: stringPatternSwift))
            blackHole(testCode.matches(of: numberPatternSwift))
            blackHole(testCode.matches(of: commentPatternSwift))
            blackHole(testCode.matches(of: functionCallPatternSwift))
            blackHole(testCode.matches(of: identifierPatternSwift))
        }
    }

    // MARK: - firstMatch Loop Comparison (simulates SwiftHighlight usage)
    // SwiftHighlight calls firstMatch repeatedly, advancing through the string

    Benchmark("NSRegex: firstMatch loop (identifier)", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            var searchStart = 0
            let utf16Count = testCode.utf16.count
            var matchCount = 0
            while searchStart < utf16Count {
                let searchRange = NSRange(location: searchStart, length: utf16Count - searchStart)
                guard let match = identifierPatternNS.firstMatch(in: testCode, range: searchRange) else { break }
                matchCount += 1
                searchStart = match.range.upperBound
            }
            blackHole(matchCount)
        }
    }

    Benchmark("SwiftRegex: firstMatch loop (identifier)", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            var searchStart = testCode.startIndex
            var matchCount = 0
            while searchStart < testCode.endIndex {
                guard let match = testCode[searchStart...].firstMatch(of: identifierPatternSwift) else { break }
                matchCount += 1
                searchStart = match.range.upperBound
            }
            blackHole(matchCount)
        }
    }

    // MARK: - Combined pattern (alternation) - closer to MultiRegex behavior

    let combinedPatternNS = try! NSRegularExpression(
        pattern: #"\b(if|else|for|while|def|class|return|import|from)\b|["'].*?["']|\b\d+\b|#.*"#
    )
    let combinedPatternSwift = try! Regex(#"\b(if|else|for|while|def|class|return|import|from)\b|["'].*?["']|\b\d+\b|#.*"#)

    Benchmark("NSRegex: combined alternation", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(combinedPatternNS.matches(in: testCode, range: range))
        }
    }

    Benchmark("SwiftRegex: combined alternation", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(testCode.matches(of: combinedPatternSwift))
        }
    }

    Benchmark("NSRegex: combined firstMatch loop", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            var searchStart = 0
            let utf16Count = testCode.utf16.count
            var matchCount = 0
            while searchStart < utf16Count {
                let searchRange = NSRange(location: searchStart, length: utf16Count - searchStart)
                guard let match = combinedPatternNS.firstMatch(in: testCode, range: searchRange) else { break }
                matchCount += 1
                searchStart = match.range.upperBound
            }
            blackHole(matchCount)
        }
    }

    Benchmark("SwiftRegex: combined firstMatch loop", configuration: .init(metrics: metrics)) { benchmark in
        for _ in benchmark.scaledIterations {
            var searchStart = testCode.startIndex
            var matchCount = 0
            while searchStart < testCode.endIndex {
                guard let match = testCode[searchStart...].firstMatch(of: combinedPatternSwift) else { break }
                matchCount += 1
                searchStart = match.range.upperBound
            }
            blackHole(matchCount)
        }
    }
}
