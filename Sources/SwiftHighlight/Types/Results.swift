import Foundation

/// Result of highlighting code with a specific language.
/// The Output type parameter determines the format (String for HTML, AttributedString, etc.)
public struct HighlightResult<Output: Sendable>: Sendable {
    /// The language that was used for highlighting
    public let language: String

    /// The rendered output (HTML string, AttributedString, etc.)
    public let value: Output

    /// Relevance score (used for auto-detection ranking)
    public let relevance: Int

    /// Whether illegal syntax was encountered
    public let illegal: Bool

    /// The original source code
    public let code: String

    /// The token tree for custom rendering
    public let tokenTree: TokenTree

    /// Error that was raised during highlighting (if any, in safe mode)
    public let errorRaised: Error?

    public init(
        language: String,
        value: Output,
        relevance: Int,
        illegal: Bool,
        code: String,
        tokenTree: TokenTree,
        errorRaised: Error? = nil
    ) {
        self.language = language
        self.value = value
        self.relevance = relevance
        self.illegal = illegal
        self.code = code
        self.tokenTree = tokenTree
        self.errorRaised = errorRaised
    }
}

/// Result of parsing code (before rendering).
public struct ParseResult: Sendable {
    /// The language that was used for highlighting
    public let language: String

    /// The token tree for rendering
    public let tokenTree: TokenTree

    /// Relevance score
    public let relevance: Int

    /// Whether illegal syntax was encountered
    public let illegal: Bool

    /// The original source code
    public let code: String

    /// Error that was raised during parsing (if any)
    public let errorRaised: Error?

    public init(
        language: String,
        tokenTree: TokenTree,
        relevance: Int,
        illegal: Bool,
        code: String,
        errorRaised: Error? = nil
    ) {
        self.language = language
        self.tokenTree = tokenTree
        self.relevance = relevance
        self.illegal = illegal
        self.code = code
        self.errorRaised = errorRaised
    }
}

/// Result of auto-detection highlighting.
public struct AutoHighlightResult<Output: Sendable>: Sendable {
    /// The best match result
    public let result: HighlightResult<Output>

    /// The second-best match (if available)
    public let secondBest: HighlightResult<Output>?

    /// Convenience: the detected language
    public var language: String { result.language }

    /// Convenience: the rendered output
    public var value: Output { result.value }

    /// Convenience: the relevance score
    public var relevance: Int { result.relevance }

    /// Convenience: the token tree
    public var tokenTree: TokenTree { result.tokenTree }

    public init(result: HighlightResult<Output>, secondBest: HighlightResult<Output>? = nil) {
        self.result = result
        self.secondBest = secondBest
    }
}
