import Foundation

/// A language definition for syntax highlighting.
public struct Language: Sendable, Hashable {
    /// Unique identifier for this language instance
    public let id: UUID

    /// Display name of the language
    public let name: String

    /// Alternative names/aliases for this language
    public let aliases: [String]

    /// Whether to disable auto-detection for this language
    public let disableAutodetect: Bool

    /// Case insensitive matching
    public let caseInsensitive: Bool

    /// Enable Unicode regex support
    public let unicodeRegex: Bool

    /// Keywords definition
    public let keywords: Keywords?

    /// Illegal patterns (cause highlighting to abort)
    public let illegal: RegexPattern?

    /// Child modes
    public let contains: [ModeReference]

    /// Class name aliases (e.g., "built_in" -> "builtin")
    public let classNameAliases: [String: String]

    public init(
        name: String,
        aliases: [String] = [],
        disableAutodetect: Bool = false,
        caseInsensitive: Bool = false,
        unicodeRegex: Bool = false,
        keywords: Keywords? = nil,
        illegal: RegexPattern? = nil,
        contains: [ModeReference] = [],
        classNameAliases: [String: String] = [:]
    ) {
        self.id = UUID()
        self.name = name
        self.aliases = aliases
        self.disableAutodetect = disableAutodetect
        self.caseInsensitive = caseInsensitive
        self.unicodeRegex = unicodeRegex
        self.keywords = keywords
        self.illegal = illegal
        self.contains = contains
        self.classNameAliases = classNameAliases
    }

    // MARK: - Hashable

    public static func == (lhs: Language, rhs: Language) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Type for language definition functions
public typealias LanguageDefinition = @Sendable (Highlight) async -> Language
