import SwiftHighlight
import Foundation

// Complex Python code for profiling
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

// Number of iterations for profiling
let iterations = 1000

@main
struct ProfileRunner {
    static func main() async {
        let hljs = Highlight()
        await hljs.registerPython()

        // Warm up - compile language
        _ = await hljs.highlight(complexCode, language: "python")

        print("Starting profiling run: \(iterations) iterations")

        let start = Date()
        for i in 0..<iterations {
            let result = await hljs.highlight(complexCode, language: "python")
            // Prevent optimization from removing the call
            if result.value.isEmpty {
                fatalError("Unexpected empty result")
            }
            if i % 100 == 0 {
                print("Progress: \(i)/\(iterations)")
            }
        }
        let elapsed = Date().timeIntervalSince(start)

        print("Completed \(iterations) iterations in \(String(format: "%.2f", elapsed))s")
        print("Average: \(String(format: "%.2f", elapsed / Double(iterations) * 1000))ms per iteration")
    }
}
