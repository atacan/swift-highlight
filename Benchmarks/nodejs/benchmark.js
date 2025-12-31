#!/usr/bin/env node

const hljs = require('highlight.js/lib/core');
const python = require('highlight.js/lib/languages/python');
const { performance } = require('perf_hooks');

// Register Python language
hljs.registerLanguage('python', python);

// Same test code as Swift benchmarks
const simpleCode = "x = 42";

const mediumCode = `def hello():
    print('Hello, World!')

if __name__ == '__main__':
    hello()`;

const complexCode = `import os
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

// Benchmark configuration
const ITERATIONS = 1000;
const WARMUP_ITERATIONS = 100;

function runBenchmark(name, code, iterations) {
    const times = [];
    
    // Warmup
    for (let i = 0; i < WARMUP_ITERATIONS; i++) {
        hljs.highlight(code, { language: 'python' });
    }
    
    // Actual benchmark
    for (let i = 0; i < iterations; i++) {
        const start = performance.now();
        hljs.highlight(code, { language: 'python' });
        const end = performance.now();
        times.push((end - start) * 1000); // Convert to microseconds
    }
    
    // Calculate statistics
    times.sort((a, b) => a - b);
    const p0 = times[0];
    const p25 = times[Math.floor(times.length * 0.25)];
    const p50 = times[Math.floor(times.length * 0.50)];
    const p75 = times[Math.floor(times.length * 0.75)];
    const p90 = times[Math.floor(times.length * 0.90)];
    const p99 = times[Math.floor(times.length * 0.99)];
    const p100 = times[times.length - 1];
    
    return { name, p0, p25, p50, p75, p90, p99, p100, samples: iterations };
}

function formatTable(results) {
    console.log('\n' + '='.repeat(100));
    console.log('highlight.js (Node.js) Benchmarks');
    console.log('='.repeat(100));
    console.log();
    
    for (const r of results) {
        console.log(r.name);
        console.log('╒══════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕');
        console.log('│ Metric                   │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │');
        console.log('╞══════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡');
        console.log(`│ Time (wall clock) (μs) * │ ${r.p0.toFixed(0).padStart(9)} │ ${r.p25.toFixed(0).padStart(9)} │ ${r.p50.toFixed(0).padStart(9)} │ ${r.p75.toFixed(0).padStart(9)} │ ${r.p90.toFixed(0).padStart(9)} │ ${r.p99.toFixed(0).padStart(9)} │ ${r.p100.toFixed(0).padStart(9)} │ ${r.samples.toString().padStart(9)} │`);
        console.log('╘══════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛');
        console.log();
    }
}

function main() {
    console.log(`Running highlight.js benchmarks (${ITERATIONS} iterations each, ${WARMUP_ITERATIONS} warmup)...`);
    console.log(`Node.js ${process.version}`);
    console.log(`highlight.js ${require('highlight.js/package.json').version}`);
    
    const results = [
        runBenchmark('highlight.js: Simple Code', simpleCode, ITERATIONS),
        runBenchmark('highlight.js: Medium Code', mediumCode, ITERATIONS),
        runBenchmark('highlight.js: Complex Code', complexCode, ITERATIONS),
    ];
    
    formatTable(results);
    
    // Also output summary for easy comparison
    console.log('Summary (p50 median in μs):');
    console.log('---------------------------');
    for (const r of results) {
        console.log(`  ${r.name}: ${r.p50.toFixed(1)} μs`);
    }
}

main();
