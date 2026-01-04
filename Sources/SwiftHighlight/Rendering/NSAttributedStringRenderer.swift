import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
#elseif canImport(UIKit)
import UIKit
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
#endif

#if canImport(AppKit) || canImport(UIKit)

/// Theme for NSAttributedString output with scope-to-style mappings.
public struct NSAttributedStringTheme: HighlightTheme, Sendable {
    private let styles: [String: ScopeStyle]

    /// Font name for monospace text (default: "Menlo")
    public let fontName: String

    /// Font size (default: 14)
    public let fontSize: CGFloat

    public init(
        fontName: String = "Menlo",
        fontSize: CGFloat = 14,
        styles: [String: ScopeStyle] = [:]
    ) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.styles = styles
    }

    public func style(for scope: String) -> ScopeStyle? {
        styleWithFallback(for: scope) { styles[$0] }
    }

    /// Built-in dark theme (Dracula-inspired)
    public static let dark = NSAttributedStringTheme(styles: [
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

/// Renders token trees to NSAttributedString (AppKit/UIKit).
public struct NSAttributedStringRenderer: TokenRenderer {
    public typealias Output = NSAttributedString
    public typealias Theme = NSAttributedStringTheme

    public let theme: NSAttributedStringTheme

    public init(theme: NSAttributedStringTheme = .dark) {
        self.theme = theme
    }

    public func render(_ tree: TokenTree) -> NSAttributedString {
        let result = NSMutableAttributedString()
        renderNode(.scope(tree.root), to: result, scopeStack: [])
        return result
    }

    private func renderNode(_ node: TokenNode, to result: NSMutableAttributedString, scopeStack: [String]) {
        switch node {
        case .text(let text):
            var attributes: [NSAttributedString.Key: Any] = [
                .font: baseFont()
            ]

            // Apply styles from scope stack (innermost scope takes precedence)
            for scope in scopeStack.reversed() {
                if let style = theme.style(for: scope) {
                    applyStyle(style, to: &attributes)
                    break // Use first matching style
                }
            }

            let attributed = NSAttributedString(string: text, attributes: attributes)
            result.append(attributed)

        case .scope(let scopeNode):
            var newStack = scopeStack
            if let scope = scopeNode.scope {
                newStack.append(scope)
            }

            for child in scopeNode.children {
                renderNode(child, to: result, scopeStack: newStack)
            }
        }
    }

    private func baseFont() -> PlatformFont {
        PlatformFont(name: theme.fontName, size: theme.fontSize)
            ?? PlatformFont.monospacedSystemFont(ofSize: theme.fontSize, weight: .regular)
    }

    private func applyStyle(_ style: ScopeStyle, to attributes: inout [NSAttributedString.Key: Any]) {
        if let color = style.foregroundColor {
            attributes[.foregroundColor] = PlatformColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: color.alpha
            )
        }

        if let bgColor = style.backgroundColor {
            attributes[.backgroundColor] = PlatformColor(
                red: bgColor.red,
                green: bgColor.green,
                blue: bgColor.blue,
                alpha: bgColor.alpha
            )
        }

        if style.textStyle.bold || style.textStyle.italic {
            let baseFont = attributes[.font] as? PlatformFont ?? self.baseFont()
            attributes[.font] = fontWithTraits(baseFont, bold: style.textStyle.bold, italic: style.textStyle.italic)
        }

        if style.textStyle.underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        if style.textStyle.strikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
    }

    private func fontWithTraits(_ font: PlatformFont, bold: Bool, italic: Bool) -> PlatformFont {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        var traits: NSFontTraitMask = []
        if bold { traits.insert(.boldFontMask) }
        if italic { traits.insert(.italicFontMask) }
        return NSFontManager.shared.convert(font, toHaveTrait: traits)
        #elseif canImport(UIKit)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else {
            return font
        }
        return UIFont(descriptor: descriptor, size: font.pointSize)
        #endif
    }
}

#endif
