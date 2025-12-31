import Foundation

/// A language definition for syntax highlighting.
public final class Language: @unchecked Sendable {
    /// Display name of the language
    public var name: String

    /// Alternative names/aliases for this language
    public var aliases: [String]?

    /// Whether to disable auto-detection for this language
    public var disableAutodetect: Bool

    /// Case insensitive matching
    public var caseInsensitive: Bool

    /// Enable Unicode regex support
    public var unicodeRegex: Bool

    /// Keywords definition
    public var keywords: Keywords?

    /// Illegal patterns (cause highlighting to abort)
    public var illegal: RegexPattern?

    /// Child modes
    public var contains: [ModeReference]

    /// Class name aliases (e.g., "built_in" -> "builtin")
    public var classNameAliases: [String: String]

    /// Compiler extensions (advanced)
    internal var compilerExtensions: [(Mode, Mode?) -> Void] = []

    /// The raw definition function (for re-registration)
    internal var rawDefinition: ((Highlight) -> Language)?

    public init(name: String) {
        self.name = name
        self.aliases = nil
        self.disableAutodetect = false
        self.caseInsensitive = false
        self.unicodeRegex = false
        self.keywords = nil
        self.illegal = nil
        self.contains = []
        self.classNameAliases = [:]
    }
}

/// Type for language definition functions
public typealias LanguageDefinition = @Sendable (Highlight) -> Language
