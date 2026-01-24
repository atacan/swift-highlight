import Foundation

/// Small helper DSL used by generated language files.
public enum HLJS {
    /// Returns a regex pattern using the Swift engine.
    public static func re(_ source: String) -> RegexPattern {
        .string(source)
    }

    /// Convenience wrapper for keyword lists.
    public static func kw(
        pattern: RegexPattern? = nil,
        keyword: [String]? = nil,
        literal: [String]? = nil,
        builtIn: [String]? = nil,
        type: [String]? = nil,
        custom: [String: [String]]? = nil
    ) -> Keywords {
        Keywords(
            pattern: pattern,
            keyword: keyword,
            builtIn: builtIn,
            literal: literal,
            type: type,
            custom: custom ?? [:]
        )
    }

    /// Wraps variants into the boxed representation.
    public static func variants(_ modes: [Mode]) -> [ModeBox] {
        modes.map(ModeBox.init)
    }
}
