import Foundation

/// ANSI escape codes for terminal colors.
public enum ANSIColor: String, Sendable, CaseIterable {
    // Standard colors
    case black = "30"
    case red = "31"
    case green = "32"
    case yellow = "33"
    case blue = "34"
    case magenta = "35"
    case cyan = "36"
    case white = "37"
    case `default` = "39"

    // Bright variants
    case brightBlack = "90"
    case brightRed = "91"
    case brightGreen = "92"
    case brightYellow = "93"
    case brightBlue = "94"
    case brightMagenta = "95"
    case brightCyan = "96"
    case brightWhite = "97"

    /// Create from ThemeColor (approximate to nearest ANSI color)
    public static func from(_ color: ThemeColor) -> ANSIColor {
        let brightness = (color.red + color.green + color.blue) / 3.0
        let isBright = brightness > 0.5

        // Simple heuristic for color mapping
        if color.red > 0.6 && color.green < 0.4 && color.blue < 0.4 {
            return isBright ? .brightRed : .red
        } else if color.green > 0.6 && color.red < 0.4 && color.blue < 0.4 {
            return isBright ? .brightGreen : .green
        } else if color.blue > 0.6 && color.red < 0.4 && color.green < 0.4 {
            return isBright ? .brightBlue : .blue
        } else if color.red > 0.5 && color.green > 0.5 && color.blue < 0.4 {
            return isBright ? .brightYellow : .yellow
        } else if color.red > 0.5 && color.blue > 0.5 && color.green < 0.4 {
            return isBright ? .brightMagenta : .magenta
        } else if color.green > 0.5 && color.blue > 0.5 && color.red < 0.4 {
            return isBright ? .brightCyan : .cyan
        } else if brightness > 0.8 {
            return .brightWhite
        } else if brightness < 0.2 {
            return .black
        } else {
            return .white
        }
    }
}

/// Style for ANSI terminal output.
public struct ANSIStyle: Sendable {
    public var color: ANSIColor?
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool

    public init(
        color: ANSIColor? = nil,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false
    ) {
        self.color = color
        self.bold = bold
        self.italic = italic
        self.underline = underline
    }

    /// Generate ANSI escape sequence
    public var escapeSequence: String {
        var codes: [String] = []
        if bold { codes.append("1") }
        if italic { codes.append("3") }
        if underline { codes.append("4") }
        if let color = color { codes.append(color.rawValue) }

        guard !codes.isEmpty else { return "" }
        return "\u{1B}[\(codes.joined(separator: ";"))m"
    }

    /// Reset sequence
    public static let reset = "\u{1B}[0m"
}

/// Theme for ANSI terminal output.
public struct ANSITheme: HighlightTheme, Sendable {
    private let styles: [String: ANSIStyle]

    public init(styles: [String: ANSIStyle] = [:]) {
        self.styles = styles
    }

    /// Returns ScopeStyle for protocol conformance (converts from ANSIStyle)
    public func style(for scope: String) -> ScopeStyle? {
        guard let ansiStyle = ansiStyle(for: scope) else { return nil }

        return ScopeStyle(
            foregroundColor: nil, // ANSI uses named colors
            textStyle: TextStyle(
                bold: ansiStyle.bold,
                italic: ansiStyle.italic,
                underline: ansiStyle.underline
            )
        )
    }

    /// Get ANSI-specific style for a scope
    public func ansiStyle(for scope: String) -> ANSIStyle? {
        // Try exact match first
        if let style = styles[scope] {
            return style
        }

        // Try fallback chain
        var parts = scope.split(separator: ".")
        while parts.count > 1 {
            parts.removeLast()
            let fallback = parts.joined(separator: ".")
            if let style = styles[fallback] {
                return style
            }
        }

        return nil
    }

    /// Built-in dark theme
    public static let dark = ANSITheme(styles: [
        "keyword": ANSIStyle(color: .magenta, bold: true),
        "built_in": ANSIStyle(color: .cyan),
        "type": ANSIStyle(color: .cyan),
        "literal": ANSIStyle(color: .cyan, bold: true),
        "number": ANSIStyle(color: .brightMagenta),
        "string": ANSIStyle(color: .yellow),
        "comment": ANSIStyle(color: .brightBlack, italic: true),
        "doctag": ANSIStyle(color: .cyan),
        "function": ANSIStyle(color: .green),
        "title": ANSIStyle(color: .green, bold: true),
        "class": ANSIStyle(color: .cyan),
        "variable": ANSIStyle(color: .white),
        "operator": ANSIStyle(color: .magenta),
        "punctuation": ANSIStyle(color: .white),
        "meta": ANSIStyle(color: .magenta),
        "attr": ANSIStyle(color: .green),
        "attribute": ANSIStyle(color: .green),
        "params": ANSIStyle(color: .brightYellow),
        "regexp": ANSIStyle(color: .red),
        "selector-tag": ANSIStyle(color: .magenta),
        "selector-id": ANSIStyle(color: .green),
        "selector-class": ANSIStyle(color: .green),
    ])
}

/// Renders token trees to ANSI-colored terminal strings.
public struct ANSIRenderer: TokenRenderer {
    public typealias Output = String
    public typealias Theme = ANSITheme

    public let theme: ANSITheme

    public init(theme: ANSITheme = .dark) {
        self.theme = theme
    }

    public func render(_ tree: TokenTree) -> String {
        var buffer = ""
        renderNode(.scope(tree.root), to: &buffer, scopeStack: [])
        return buffer
    }

    private func renderNode(_ node: TokenNode, to buffer: inout String, scopeStack: [String]) {
        switch node {
        case .text(let text):
            // Find applicable style from scope stack
            var appliedStyle: ANSIStyle? = nil
            for scope in scopeStack.reversed() {
                if let style = theme.ansiStyle(for: scope) {
                    appliedStyle = style
                    break
                }
            }

            if let style = appliedStyle {
                buffer += style.escapeSequence
                buffer += text
                buffer += ANSIStyle.reset
            } else {
                buffer += text
            }

        case .scope(let scopeNode):
            var newStack = scopeStack
            if let scope = scopeNode.scope {
                newStack.append(scope)
            }

            for child in scopeNode.children {
                renderNode(child, to: &buffer, scopeStack: newStack)
            }
        }
    }
}
