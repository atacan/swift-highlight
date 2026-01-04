import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Theme for AttributedString output with scope-to-style mappings.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AttributedStringTheme: HighlightTheme, Sendable {
    private let styles: [String: ScopeStyle]

    public init(styles: [String: ScopeStyle] = [:]) {
        self.styles = styles
    }

    public func style(for scope: String) -> ScopeStyle? {
        styleWithFallback(for: scope) { styles[$0] }
    }

    /// Built-in dark theme (Dracula-inspired)
    public static let dark = AttributedStringTheme(styles: [
        "keyword": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.475, blue: 0.776), textStyle: .bold),
        "built_in": ScopeStyle(foregroundColor: ThemeColor(red: 0.545, green: 0.914, blue: 0.992)),
        "type": ScopeStyle(foregroundColor: ThemeColor(red: 0.545, green: 0.914, blue: 0.992)),
        "literal": ScopeStyle(foregroundColor: ThemeColor(red: 0.741, green: 0.576, blue: 0.976)),
        "number": ScopeStyle(foregroundColor: ThemeColor(red: 0.741, green: 0.576, blue: 0.976)),
        "string": ScopeStyle(foregroundColor: ThemeColor(red: 0.945, green: 0.980, blue: 0.549)),
        "comment": ScopeStyle(foregroundColor: ThemeColor(red: 0.384, green: 0.447, blue: 0.643), textStyle: .italic),
        "doctag": ScopeStyle(foregroundColor: ThemeColor(red: 0.545, green: 0.914, blue: 0.992)),
        "function": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
        "title": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
        "class": ScopeStyle(foregroundColor: ThemeColor(red: 0.545, green: 0.914, blue: 0.992)),
        "variable": ScopeStyle(foregroundColor: ThemeColor(red: 0.973, green: 0.973, blue: 0.949)),
        "operator": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.475, blue: 0.776)),
        "punctuation": ScopeStyle(foregroundColor: ThemeColor(red: 0.973, green: 0.973, blue: 0.949)),
        "meta": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.475, blue: 0.776)),
        "attr": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
        "attribute": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
        "params": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.722, blue: 0.424)),
        "regexp": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.333, blue: 0.333)),
        "selector-tag": ScopeStyle(foregroundColor: ThemeColor(red: 1.0, green: 0.475, blue: 0.776)),
        "selector-id": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
        "selector-class": ScopeStyle(foregroundColor: ThemeColor(red: 0.314, green: 0.980, blue: 0.482)),
    ])
}

/// Renders token trees to AttributedString (SwiftUI).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AttributedStringRenderer: TokenRenderer {
    public typealias Output = AttributedString
    public typealias Theme = AttributedStringTheme

    public let theme: AttributedStringTheme

    public init(theme: AttributedStringTheme = .dark) {
        self.theme = theme
    }

    public func render(_ tree: TokenTree) -> AttributedString {
        var result = AttributedString()
        renderNode(.scope(tree.root), to: &result, scopeStack: [])
        return result
    }

    private func renderNode(_ node: TokenNode, to result: inout AttributedString, scopeStack: [String]) {
        switch node {
        case .text(let text):
            var attributed = AttributedString(text)

            // Apply styles from scope stack (innermost scope takes precedence)
            for scope in scopeStack.reversed() {
                if let style = theme.style(for: scope) {
                    applyStyle(style, to: &attributed)
                    break // Use first matching style
                }
            }

            result.append(attributed)

        case .scope(let scopeNode):
            var newStack = scopeStack
            if let scope = scopeNode.scope {
                newStack.append(scope)
            }

            for child in scopeNode.children {
                renderNode(child, to: &result, scopeStack: newStack)
            }
        }
    }

    private func applyStyle(_ style: ScopeStyle, to attributed: inout AttributedString) {
        if let color = style.foregroundColor {
            attributed.foregroundColor = Color(
                red: color.red,
                green: color.green,
                blue: color.blue,
                opacity: color.alpha
            )
        }

        if let bgColor = style.backgroundColor {
            attributed.backgroundColor = Color(
                red: bgColor.red,
                green: bgColor.green,
                blue: bgColor.blue,
                opacity: bgColor.alpha
            )
        }

        // Note: Bold/italic require font attributes which are more complex in SwiftUI AttributedString
        // Users needing these should use NSAttributedStringRenderer
    }
}

#endif
