import SwiftUI
import SwiftHighlight

/// SwiftUI view that displays syntax-highlighted code
public struct CodeView: View {
    let code: String
    let language: String

    @State private var attributedString: AttributedString?
    @State private var isLoading = true

    public init(code: String, language: String) {
        self.code = code
        self.language = language
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let attributedString {
                Text(attributedString)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            } else if isLoading {
                ProgressView("Highlighting code...")
                    .padding()
            } else {
                Text("Failed to highlight code")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .task {
            await highlightCode()
        }
    }

    private func highlightCode() async {
        let hljs = Highlight()

        // Register the language
        switch language.lowercased() {
        case "python":
            await hljs.registerPython()
        default:
            break
        }

        // Highlight using AttributedStringRenderer
        let renderer = AttributedStringRenderer()

        let result = await hljs.highlight(code, language: language, renderer: renderer)

        withAnimation {
            attributedString = result.value
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Python Code") {
    CodeView(
        code: """
        def fibonacci(n):
            \"\"\"Calculate the nth Fibonacci number.\"\"\"
            if n <= 1:
                return n
            return fibonacci(n - 1) + fibonacci(n - 2)

        # Print first 10 Fibonacci numbers
        for i in range(10):
            print(f"fib({i}) = {fibonacci(i)}")
        """,
        language: "python"
    )
    .frame(minWidth: 400, minHeight: 300)
}

#Preview("Python Code - Dark Mode") {
    CodeView(
        code: """
        class DataProcessor:
            def __init__(self, data):
                self.data = data
                self.results = []

            def process(self):
                \"\"\"Process the data and store results.\"\"\"
                for item in self.data:
                    if isinstance(item, dict):
                        self.results.append(item.get('value', 0))
                return self.results

        # Usage
        processor = DataProcessor([{'value': 42}, {'value': 100}])
        print(processor.process())
        """,
        language: "python"
    )
    .preferredColorScheme(.dark)
    .frame(minWidth: 500, minHeight: 400)
}

// MARK: - Advanced Example with Multiple Languages

public struct MultiLanguageCodeView: View {
    @State private var selectedLanguage = "python"

    let codeSnippets: [String: String] = [
        "python": """
        def quicksort(arr):
            if len(arr) <= 1:
                return arr
            pivot = arr[len(arr) // 2]
            left = [x for x in arr if x < pivot]
            middle = [x for x in arr if x == pivot]
            right = [x for x in arr if x > pivot]
            return quicksort(left) + middle + quicksort(right)

        print(quicksort([3, 6, 8, 10, 1, 2, 1]))
        """
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Syntax Highlighter Demo")
                    .font(.headline)
                Spacer()
                Picker("Language", selection: $selectedLanguage) {
                    Text("Python").tag("python")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif

            Divider()

            // Code view
            if let code = codeSnippets[selectedLanguage] {
                CodeView(code: code, language: selectedLanguage)
            }
        }
    }
}

#Preview("Multi-Language Demo") {
    MultiLanguageCodeView()
        .frame(width: 600, height: 500)
}
