import Foundation

/// JSON language definition - port from highlight.js
/// Supports JSON, JSON5, and JSONC (with comments)
public func jsonLanguage(_ hljs: Highlight) -> Language {
    let literals = ["true", "false", "null"]

    // MARK: - Attribute (object keys)
    // Keys are strings followed by colon: "key": value or 'key': value (JSON5)
    let attribute = Mode(scope: "attr")
    attribute.begin = .string(#"(("(\\.|[^\\"\r\n])*")|('(\\.|[^\\'\r\n])*'))(?=\s*:)"#)
    attribute.relevance = 1

    // MARK: - Punctuation
    let punctuation = Mode(scope: "punctuation")
    punctuation.match = .string(#"[{}\[\],:]"#)
    punctuation.relevance = 0

    // MARK: - Literals mode
    // Using beginKeywords allows tight `illegal: \S` rule to flag invalid characters
    // The mode has scope "literal" and keywords with scope "keyword" to create nested spans
    let literalsMode = Mode(scope: "literal")
    literalsMode.beginKeywords = literals.joined(separator: " ")
    // Keywords inside the mode with "keyword" scope creates nested span structure
    literalsMode.keywords = Keywords(keyword: literals)

    // MARK: - Extended number mode (ECMAScript style)
    // Supports: hex (0x...), decimal, float, exponent, NaN, Infinity
    let extendedNumber = Mode(scope: "number")
    extendedNumber.match = .string(#"([-+]?)(\b0[xX][a-fA-F0-9]+|(\b\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?)|NaN|[-+]?Infinity"#)
    extendedNumber.relevance = 0

    // MARK: - Language definition
    let lang = Language(name: "JSON")
    lang.aliases = ["jsonc", "json5"]
    lang.keywords = Keywords(literal: literals)
    lang.illegal = .string(#"\S"#)
    lang.contains = [
        .mode(attribute),
        .mode(punctuation),
        .mode(Highlight.aposStringMode),
        .mode(Highlight.quoteStringMode),
        .mode(literalsMode),
        .mode(extendedNumber),
        .mode(Highlight.cLineCommentMode),
        .mode(Highlight.cBlockCommentMode)
    ]

    return lang
}

/// Registers JSON with the highlighter
public extension Highlight {
    /// Registers the JSON language
    func registerJSON() {
        registerLanguage("json", definition: jsonLanguage)
    }
}
