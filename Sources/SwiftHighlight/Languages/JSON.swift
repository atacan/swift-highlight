import Foundation

/// JSON language definition - port from highlight.js
/// Supports JSON, JSON5, and JSONC (with comments)
public func jsonLanguage(_ hljs: Highlight) -> Language {
    let literals = ["true", "false", "null"]

    // MARK: - Attribute (object keys)
    let attribute = Mode(
        scope: "attr",
        begin: .string(#"(("(\\.|[^\\"\r\n])*")|('(\\.|[^\\'\r\n])*'))(?=\s*:)"#),
        relevance: 1
    )

    // MARK: - Punctuation
    let punctuation = Mode(
        scope: "punctuation",
        match: .string(#"[{}\[\],:]"#),
        relevance: 0
    )

    // MARK: - Literals mode
    let literalsMode = Mode(
        scope: "literal",
        keywords: Keywords(keyword: literals),
        beginKeywords: literals.joined(separator: " ")
    )

    // MARK: - Extended number mode (ECMAScript style)
    let extendedNumber = Mode(
        scope: "number",
        match: .string(#"([-+]?)(\b0[xX][a-fA-F0-9]+|(\b\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?)|NaN|[-+]?Infinity"#),
        relevance: 0
    )

    // MARK: - Language definition
    return Language(
        name: "JSON",
        aliases: ["jsonc", "json5"],
        keywords: Keywords(literal: literals),
        illegal: .string(#"\S"#),
        contains: [
            .mode(attribute),
            .mode(punctuation),
            .mode(Highlight.aposStringMode),
            .mode(Highlight.quoteStringMode),
            .mode(literalsMode),
            .mode(extendedNumber),
            .mode(Highlight.cLineCommentMode),
            .mode(Highlight.cBlockCommentMode)
        ]
    )
}

/// Registers JSON with the highlighter
public extension Highlight {
    /// Registers the JSON language
    func registerJSON() {
        registerLanguage("json") { hljs in jsonLanguage(hljs) }
    }
}
