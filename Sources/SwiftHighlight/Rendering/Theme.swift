import Foundation

/// Platform-agnostic color representation using RGB values.
public struct ThemeColor: Sendable, Hashable {
    /// Red component (0.0 - 1.0)
    public let red: Double
    /// Green component (0.0 - 1.0)
    public let green: Double
    /// Blue component (0.0 - 1.0)
    public let blue: Double
    /// Alpha component (0.0 - 1.0)
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Create from hex string (e.g., "#FF5500" or "FF5500")
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let hexValue = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        self.red = Double((hexValue & 0xFF0000) >> 16) / 255.0
        self.green = Double((hexValue & 0x00FF00) >> 8) / 255.0
        self.blue = Double(hexValue & 0x0000FF) / 255.0
        self.alpha = 1.0
    }
}

/// Text style attributes (bold, italic, underline, etc.)
public struct TextStyle: Sendable, Hashable {
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool

    public init(
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false
    ) {
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
    }

    public static let regular = TextStyle()
    public static let bold = TextStyle(bold: true)
    public static let italic = TextStyle(italic: true)
    public static let boldItalic = TextStyle(bold: true, italic: true)
}

/// A complete style for a scope (color + text style).
public struct ScopeStyle: Sendable {
    public var foregroundColor: ThemeColor?
    public var backgroundColor: ThemeColor?
    public var textStyle: TextStyle

    public init(
        foregroundColor: ThemeColor? = nil,
        backgroundColor: ThemeColor? = nil,
        textStyle: TextStyle = .regular
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.textStyle = textStyle
    }
}

/// Protocol for themes that provide scope-to-style mappings.
/// Themes map scope names (like "keyword", "string", "comment") to visual styles.
public protocol HighlightTheme: Sendable {
    /// Returns the style for a given scope.
    /// Implementations should handle fallback chains (e.g., "string.quoted" -> "string").
    func style(for scope: String) -> ScopeStyle?
}

/// Extension for scope fallback chain lookup
extension HighlightTheme {
    /// Looks up a style with automatic fallback chain.
    /// For example, "string.quoted.double" tries:
    /// 1. "string.quoted.double"
    /// 2. "string.quoted"
    /// 3. "string"
    public func styleWithFallback(for scope: String, lookup: (String) -> ScopeStyle?) -> ScopeStyle? {
        // Try exact match first
        if let style = lookup(scope) {
            return style
        }

        // Try fallback chain
        var parts = scope.split(separator: ".")
        while parts.count > 1 {
            parts.removeLast()
            let fallback = parts.joined(separator: ".")
            if let style = lookup(fallback) {
                return style
            }
        }

        return nil
    }
}
