import Foundation

/// Configuration options for the highlighter.
public struct HighlightOptions: Sendable {
    /// CSS class prefix for highlighted elements (default: "hljs-")
    public var classPrefix: String

    /// Languages to consider for auto-detection.
    /// If nil, all registered languages are considered.
    public var languages: [String]?

    /// Whether to throw on unescaped HTML (for security)
    public var throwUnescapedHTML: Bool

    /// Whether to ignore unescaped HTML warnings
    public var ignoreUnescapedHTML: Bool

    public init(
        classPrefix: String = "hljs-",
        languages: [String]? = nil,
        throwUnescapedHTML: Bool = false,
        ignoreUnescapedHTML: Bool = false
    ) {
        self.classPrefix = classPrefix
        self.languages = languages
        self.throwUnescapedHTML = throwUnescapedHTML
        self.ignoreUnescapedHTML = ignoreUnescapedHTML
    }
}
