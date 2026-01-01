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
        "keyword": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF79C6")!, textStyle: .bold),
        "built_in": ScopeStyle(foregroundColor: ThemeColor(hex: "#8BE9FD")!),
        "type": ScopeStyle(foregroundColor: ThemeColor(hex: "#8BE9FD")!),
        "literal": ScopeStyle(foregroundColor: ThemeColor(hex: "#BD93F9")!),
        "number": ScopeStyle(foregroundColor: ThemeColor(hex: "#BD93F9")!),
        "string": ScopeStyle(foregroundColor: ThemeColor(hex: "#F1FA8C")!),
        "comment": ScopeStyle(foregroundColor: ThemeColor(hex: "#6272A4")!, textStyle: .italic),
        "doctag": ScopeStyle(foregroundColor: ThemeColor(hex: "#8BE9FD")!),
        "function": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
        "title": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
        "class": ScopeStyle(foregroundColor: ThemeColor(hex: "#8BE9FD")!),
        "variable": ScopeStyle(foregroundColor: ThemeColor(hex: "#F8F8F2")!),
        "operator": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF79C6")!),
        "punctuation": ScopeStyle(foregroundColor: ThemeColor(hex: "#F8F8F2")!),
        "meta": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF79C6")!),
        "attr": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
        "attribute": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
        "params": ScopeStyle(foregroundColor: ThemeColor(hex: "#FFB86C")!),
        "regexp": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF5555")!),
        "selector-tag": ScopeStyle(foregroundColor: ThemeColor(hex: "#FF79C6")!),
        "selector-id": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
        "selector-class": ScopeStyle(foregroundColor: ThemeColor(hex: "#50FA7B")!),
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
