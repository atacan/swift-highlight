import Foundation

/// A highlighting mode that defines how to match and highlight a portion of code.
public final class Mode: @unchecked Sendable {
    /// Scope name for CSS class (e.g., "string", "comment", "keyword")
    public var scope: String?

    /// CSS class name (legacy, prefer scope)
    public var className: String?

    /// Pattern to match the beginning of this mode
    public var begin: RegexPattern?

    /// Pattern to match the end of this mode
    public var end: RegexPattern?

    /// Shorthand for a begin-only mode (match)
    public var match: RegexPattern?

    /// Keywords for this mode
    public var keywords: Keywords?

    /// Illegal patterns within this mode
    public var illegal: RegexPattern?

    /// Child modes
    public var contains: [ModeReference]

    /// Mode variants (alternative patterns)
    public var variants: [Mode]?

    /// Relevance score for this mode (default: 1)
    public var relevance: Int?

    /// Exclude the begin match from highlighting
    public var excludeBegin: Bool

    /// Exclude the end match from highlighting
    public var excludeEnd: Bool

    /// Return to parent after begin match
    public var returnBegin: Bool

    /// Return to parent after end match
    public var returnEnd: Bool

    /// End when parent ends
    public var endsWithParent: Bool

    /// End parent when this ends
    public var endsParent: Bool

    /// Skip this mode content (used for sub-language buffer building)
    public var skip: Bool

    /// Sub-language to use for content
    public var subLanguage: SubLanguage?

    /// Begin scope for multi-class matching
    public var beginScope: Scope?

    /// End scope for multi-class matching
    public var endScope: Scope?

    /// Mode that starts after this mode ends
    public var starts: Mode?

    /// Callback when mode begins
    public var onBegin: ModeCallback?

    /// Callback when mode ends
    public var onEnd: ModeCallback?

    /// Begin keywords - converts to a begin pattern matching any of these keywords
    public var beginKeywords: String?

    /// Internal: marks if this mode has been compiled (used to prevent infinite recursion)
    internal var isCompiled = false

    /// Internal: cached compiled mode to reuse for .self references
    internal weak var cachedCompiledMode: CompiledMode?

    /// Internal: cached expanded variants
    internal var cachedVariants: [Mode]?

    public init(
        scope: String? = nil,
        className: String? = nil,
        begin: RegexPattern? = nil,
        end: RegexPattern? = nil,
        match: RegexPattern? = nil,
        keywords: Keywords? = nil,
        illegal: RegexPattern? = nil,
        contains: [ModeReference] = [],
        variants: [Mode]? = nil,
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
        starts: Mode? = nil,
        onBegin: ModeCallback? = nil,
        onEnd: ModeCallback? = nil,
        beginKeywords: String? = nil
    ) {
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

    /// Creates a copy of this mode
    public func copy() -> Mode {
        let m = Mode()
        m.scope = scope
        m.className = className
        m.begin = begin
        m.end = end
        m.match = match
        m.keywords = keywords
        m.illegal = illegal
        m.contains = contains
        m.variants = variants
        m.relevance = relevance
        m.excludeBegin = excludeBegin
        m.excludeEnd = excludeEnd
        m.returnBegin = returnBegin
        m.returnEnd = returnEnd
        m.endsWithParent = endsWithParent
        m.endsParent = endsParent
        m.skip = skip
        m.subLanguage = subLanguage
        m.beginScope = beginScope
        m.endScope = endScope
        m.starts = starts?.copy()
        m.onBegin = onBegin
        m.onEnd = onEnd
        m.beginKeywords = beginKeywords
        return m
    }
}

/// Reference to a mode - allows 'self' references in contains
public enum ModeReference: Sendable {
    case mode(Mode)
    case `self`
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

/// Response object for mode callbacks
public final class ModeCallbackResponse: @unchecked Sendable {
    /// Set to true to ignore this match
    public var isMatchIgnored = false

    /// Data storage for callbacks
    public var data: [String: Any] = [:]

    public init() {}

    public func ignoreMatch() {
        isMatchIgnored = true
    }
}

/// Type for mode callbacks
public typealias ModeCallback = @Sendable (NSTextCheckingResult, ModeCallbackResponse) -> Void
