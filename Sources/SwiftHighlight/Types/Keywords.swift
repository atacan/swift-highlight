import Foundation

/// Keywords definition for a language or mode.
public struct Keywords: Sendable {
    /// Custom pattern for matching keywords (default: \w+)
    public var pattern: RegexPattern?

    /// Reserved keywords
    public var keyword: [String]?

    /// Built-in functions/values
    public var builtIn: [String]?

    /// Literal values (true, false, null, etc.)
    public var literal: [String]?

    /// Type names
    public var type: [String]?

    /// Custom keyword categories
    /// Key is the scope name, value is the list of keywords
    public var custom: [String: [String]]

    public init(
        pattern: RegexPattern? = nil,
        keyword: [String]? = nil,
        builtIn: [String]? = nil,
        literal: [String]? = nil,
        type: [String]? = nil,
        custom: [String: [String]] = [:]
    ) {
        self.pattern = pattern
        self.keyword = keyword
        self.builtIn = builtIn
        self.literal = literal
        self.type = type
        self.custom = custom
    }

    /// Returns true if no keywords are defined
    public var isEmpty: Bool {
        keyword == nil &&
        builtIn == nil &&
        literal == nil &&
        type == nil &&
        custom.isEmpty
    }
}

/// Compiled keywords ready for matching
internal struct CompiledKeywords {
    /// The pattern for matching potential keywords
    let pattern: NSRegularExpression

    /// Map from keyword to (scope, relevance)
    let keywords: [String: (scope: String, relevance: Int)]

    init(pattern: NSRegularExpression, keywords: [String: (scope: String, relevance: Int)]) {
        self.pattern = pattern
        self.keywords = keywords
    }
}
