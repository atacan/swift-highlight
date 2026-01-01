import Foundation

// MARK: - Box for Indirection

/// A box type to enable recursive struct definitions
/// Used to wrap Mode references that would otherwise create infinite-size types
/// This is Sendable because it only contains an immutable Mode value.
public final class ModeBox: Sendable, Hashable {
    public let value: Mode

    public init(_ value: Mode) {
        self.value = value
    }

    public static func == (lhs: ModeBox, rhs: ModeBox) -> Bool {
        lhs.value.id == rhs.value.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value.id)
    }
}

/// A highlighting mode that defines how to match and highlight a portion of code.
public struct Mode: Sendable, Hashable {
    /// Unique identifier for cycle detection during compilation
    public let id: UUID

    /// Scope name for CSS class (e.g., "string", "comment", "keyword")
    public let scope: String?

    /// CSS class name (legacy, prefer scope)
    public let className: String?

    /// Pattern to match the beginning of this mode
    public let begin: RegexPattern?

    /// Pattern to match the end of this mode
    public let end: RegexPattern?

    /// Shorthand for a begin-only mode (match)
    public let match: RegexPattern?

    /// Keywords for this mode
    public let keywords: Keywords?

    /// Illegal patterns within this mode
    public let illegal: RegexPattern?

    /// Child modes (boxed to break recursion)
    public let contains: [ModeReference]

    /// Mode variants (boxed to break recursion)
    public let variants: [ModeBox]?

    /// Relevance score for this mode (default: 1)
    public let relevance: Int?

    /// Exclude the begin match from highlighting
    public let excludeBegin: Bool

    /// Exclude the end match from highlighting
    public let excludeEnd: Bool

    /// Return to parent after begin match
    public let returnBegin: Bool

    /// Return to parent after end match
    public let returnEnd: Bool

    /// End when parent ends
    public let endsWithParent: Bool

    /// End parent when this ends
    public let endsParent: Bool

    /// Skip this mode content (used for sub-language buffer building)
    public let skip: Bool

    /// Sub-language to use for content
    public let subLanguage: SubLanguage?

    /// Begin scope for multi-class matching
    public let beginScope: Scope?

    /// End scope for multi-class matching
    public let endScope: Scope?

    /// Mode that starts after this mode ends (boxed to break recursion)
    public let starts: ModeBox?

    /// Callback when mode begins
    public let onBegin: ModeCallback?

    /// Callback when mode ends
    public let onEnd: ModeCallback?

    /// Begin keywords - converts to a begin pattern matching any of these keywords
    public let beginKeywords: String?

    public init(
        scope: String? = nil,
        className: String? = nil,
        begin: RegexPattern? = nil,
        end: RegexPattern? = nil,
        match: RegexPattern? = nil,
        keywords: Keywords? = nil,
        illegal: RegexPattern? = nil,
        contains: [ModeReference] = [],
        variants: [ModeBox]? = nil,
        relevance: Int? = nil,
        excludeBegin: Bool = false,
        excludeEnd: Bool = false,
        returnBegin: Bool = false,
        returnEnd: Bool = false,
        endsWithParent: Bool = false,
        endsParent: Bool = false,
        skip: Bool = false,
        subLanguage: SubLanguage? = nil,
        beginScope: Scope? = nil,
        endScope: Scope? = nil,
        starts: ModeBox? = nil,
        onBegin: ModeCallback? = nil,
        onEnd: ModeCallback? = nil,
        beginKeywords: String? = nil
    ) {
        self.id = UUID()
        self.scope = scope
        self.className = className
        self.begin = begin
        self.end = end
        self.match = match
        self.keywords = keywords
        self.illegal = illegal
        self.contains = contains
        self.variants = variants
        self.relevance = relevance
        self.excludeBegin = excludeBegin
        self.excludeEnd = excludeEnd
        self.returnBegin = returnBegin
        self.returnEnd = returnEnd
        self.endsWithParent = endsWithParent
        self.endsParent = endsParent
        self.skip = skip
        self.subLanguage = subLanguage
        self.beginScope = beginScope
        self.endScope = endScope
        self.starts = starts
        self.onBegin = onBegin
        self.onEnd = onEnd
        self.beginKeywords = beginKeywords
    }

    // MARK: - Hashable

    public static func == (lhs: Mode, rhs: Mode) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Reference to a mode - allows 'self' references in contains
public enum ModeReference: Sendable, Hashable {
    case mode(ModeBox)
    case `self`

    /// Convenience initializer for creating a mode reference
    public static func mode(_ mode: Mode) -> ModeReference {
        .mode(ModeBox(mode))
    }
}

/// Sub-language specification
public enum SubLanguage: Sendable {
    case single(String)
    case multiple([String])
}

/// Scope specification for multi-class matching
public enum Scope: Sendable {
    case simple(String)
    /// Indexed scopes: key is capture group index (1-based)
    case indexed([Int: String])
}

/// Result of a mode callback indicating how to handle the match
public enum ModeCallbackResult: Sendable {
    /// Continue with normal processing of this match
    case `continue`
    /// Ignore this match and continue scanning
    case ignoreMatch
}

/// Type for mode callbacks - returns a result indicating how to handle the match
public typealias ModeCallback = @Sendable (NSTextCheckingResult) -> ModeCallbackResult
