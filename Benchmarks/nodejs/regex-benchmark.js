#!/usr/bin/env node

const { performance } = require('perf_hooks');

// Common regex patterns used in syntax highlighting
const patterns = {
    // Keyword pattern (word boundary match)
    keyword: /\b(if|else|for|while|def|class|return|import|from|try|except|finally|with|as|lambda|yield|raise|pass|break|continue|global|nonlocal|assert|del|in|not|and|or|is|None|True|False)\b/g,
    
    // String pattern (single and double quotes)
    string: /(["'])(?:(?!\1|\\).|\\.)*\1/g,
    
    // Number pattern
    number: /\b\d+\.?\d*(?:[eE][+-]?\d+)?\b/g,
    
    // Comment pattern
    comment: /#.*/g,
    
    // Function/method call
    functionCall: /\b([a-zA-Z_]\w*)\s*\(/g,
    
    // Identifier
    identifier: /\b[a-zA-Z_]\w*\b/g,
};

const testCode = `import os
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
    main()`;

const ITERATIONS = 10000;
const WARMUP = 1000;

function benchmarkRegex(name, regex, text, iterations) {
    const times = [];
    
    // Warmup
    for (let i = 0; i < WARMUP; i++) {
        regex.lastIndex = 0;
        while (regex.exec(text) !== null) {}
    }
    
    // Benchmark
    for (let i = 0; i < iterations; i++) {
        const start = performance.now();
        regex.lastIndex = 0;
        while (regex.exec(text) !== null) {}
        const end = performance.now();
        times.push((end - start) * 1000); // Convert to microseconds
    }
    
    times.sort((a, b) => a - b);
    return {
        name,
        p0: times[0],
        p50: times[Math.floor(times.length * 0.50)],
        p99: times[Math.floor(times.length * 0.99)],
        p100: times[times.length - 1],
        samples: iterations
    };
}

function benchmarkCombined(text, iterations) {
    const times = [];
    const regexes = Object.values(patterns);
    
    // Warmup
    for (let i = 0; i < WARMUP; i++) {
        for (const regex of regexes) {
            regex.lastIndex = 0;
            while (regex.exec(text) !== null) {}
        }
    }
    
    // Benchmark
    for (let i = 0; i < iterations; i++) {
        const start = performance.now();
        for (const regex of regexes) {
            regex.lastIndex = 0;
            while (regex.exec(text) !== null) {}
        }
        const end = performance.now();
        times.push((end - start) * 1000);
    }
    
    times.sort((a, b) => a - b);
    return {
        name: 'All patterns combined',
        p0: times[0],
        p50: times[Math.floor(times.length * 0.50)],
        p99: times[Math.floor(times.length * 0.99)],
        p100: times[times.length - 1],
        samples: iterations
    };
}

function main() {
    console.log(`\nRegex Performance Benchmark`);
    console.log(`Runtime: ${typeof Bun !== 'undefined' ? 'Bun' : 'Node.js'} ${process.version}`);
    console.log(`Iterations: ${ITERATIONS}, Warmup: ${WARMUP}`);
    console.log(`Text length: ${testCode.length} characters\n`);
    
    console.log('Individual Pattern Results (p50 in μs):');
    console.log('─'.repeat(50));
    
    const results = [];
    for (const [name, regex] of Object.entries(patterns)) {
        const result = benchmarkRegex(name, regex, testCode, ITERATIONS);
        results.push(result);
        console.log(`  ${name.padEnd(20)} ${result.p50.toFixed(2).padStart(8)} μs`);
    }
    
    console.log('─'.repeat(50));
    const combined = benchmarkCombined(testCode, ITERATIONS);
    console.log(`  ${'TOTAL (all patterns)'.padEnd(20)} ${combined.p50.toFixed(2).padStart(8)} μs`);
    console.log();
}

main();
