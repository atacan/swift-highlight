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
