import Foundation

/// Result of highlighting code with a specific language.
public struct HighlightResult: Sendable {
    /// The language that was used for highlighting
    public let language: String

    /// The highlighted HTML string
    public let value: String

    /// Relevance score (used for auto-detection ranking)
    public let relevance: Int

    /// Whether illegal syntax was encountered
    public let illegal: Bool

    /// The original source code
    public let code: String

    /// Error that was raised during highlighting (if any, in safe mode)
    public let errorRaised: Error?

    public init(
        language: String,
        value: String,
        relevance: Int,
        illegal: Bool,
        code: String,
        errorRaised: Error? = nil
    ) {
        self.language = language
        self.value = value
        self.relevance = relevance
        self.illegal = illegal
        self.code = code
        self.errorRaised = errorRaised
    }
}

/// Result of auto-detection highlighting.
public struct AutoHighlightResult: Sendable {
    /// The best match result
    public let result: HighlightResult

    /// The second-best match (if available)
    public let secondBest: HighlightResult?

    /// Convenience: the detected language
    public var language: String { result.language }

    /// Convenience: the highlighted HTML
    public var value: String { result.value }

    /// Convenience: the relevance score
    public var relevance: Int { result.relevance }

    public init(result: HighlightResult, secondBest: HighlightResult? = nil) {
        self.result = result
        self.secondBest = secondBest
    }
}
