import Foundation

/// Theme for HTML output - controls CSS class naming.
/// HTML rendering uses CSS classes for styling, not inline styles.
public struct HTMLTheme: HighlightTheme, Sendable {
    /// CSS class prefix (default: "hljs-")
    public let classPrefix: String

    public init(classPrefix: String = "hljs-") {
        self.classPrefix = classPrefix
    }

    /// HTML themes don't use inline styles - returns nil.
    /// Override in subclasses if you want to generate inline styles.
    public func style(for scope: String) -> ScopeStyle? {
        nil
    }

    /// Converts a scope name to CSS class name(s).
    public func cssClass(for scope: String) -> String {
        // Sub-language scope: "language:python" -> "language-python"
        if scope.hasPrefix("language:") {
            return scope.replacingOccurrences(of: "language:", with: "language-")
        }

        // Tiered scope: "comment.line" -> "hljs-comment line_"
        if scope.contains(".") {
            let pieces = scope.split(separator: ".")
            var result = ["\(classPrefix)\(pieces[0])"]
            for (i, piece) in pieces.dropFirst().enumerated() {
                result.append("\(piece)\(String(repeating: "_", count: i + 1))")
            }
            return result.joined(separator: " ")
        }

        // Simple scope: "keyword" -> "hljs-keyword"
        return "\(classPrefix)\(scope)"
    }
}

/// Renders token trees to HTML strings with CSS classes for styling.
public struct HTMLRenderer: TokenRenderer {
    public typealias Output = String
    public typealias Theme = HTMLTheme

    public let theme: HTMLTheme

    public init(theme: HTMLTheme = HTMLTheme()) {
        self.theme = theme
    }

    public func render(_ tree: TokenTree) -> String {
        var buffer = ""
        renderNode(.scope(tree.root), to: &buffer, isRoot: true)
        return buffer
    }

    private func renderNode(_ node: TokenNode, to buffer: inout String, isRoot: Bool = false) {
        switch node {
        case .text(let text):
            buffer += escapeHTML(text)

        case .scope(let scopeNode):
            if let scope = scopeNode.scope, !isRoot {
                // Skip empty scope nodes (e.g., empty params)
                if scopeNode.children.isEmpty {
                    return
                }

                let className = theme.cssClass(for: scope)
                buffer += "<span class=\"\(className)\">"

                for child in scopeNode.children {
                    renderNode(child, to: &buffer)
                }

                buffer += "</span>"
            } else {
                for child in scopeNode.children {
                    renderNode(child, to: &buffer)
                }
            }
        }
    }

    private func escapeHTML(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#x27;")
        return result
    }
}
