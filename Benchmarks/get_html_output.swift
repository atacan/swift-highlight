import SwiftHighlight

let mediumCode = """
def hello():
    print('Hello, World!')

if __name__ == '__main__':
    hello()
"""

@main
struct GetHTML {
    static func main() async {
        let hljs = Highlight()
        await hljs.registerPython()
        let result = await hljs.highlight(mediumCode, language: "python")
        print(result.value)
    }
}
