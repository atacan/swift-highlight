import Foundation

/// Regex utility functions for building patterns.
public enum Regex {
    /// Concatenates multiple patterns into one
    public static func concat(_ patterns: Any...) -> String {
        patterns.map { source($0) }.joined()
    }

    /// Creates an alternation (a|b|c)
    public static func either(_ patterns: Any..., capture: Bool = false) -> String {
        let joined = patterns.map { source($0) }.joined(separator: "|")
        return capture ? "(\(joined))" : "(?:\(joined))"
    }

    /// Creates a lookahead assertion (?=...)
    public static func lookahead(_ pattern: Any) -> String {
        "(?=\(source(pattern)))"
    }

    /// Creates a negative lookahead assertion (?!...)
    public static func negativeLookahead(_ pattern: Any) -> String {
        "(?!\(source(pattern)))"
    }

    /// Makes a pattern optional (?:...)?
    public static func optional(_ pattern: Any) -> String {
        "(?:\(source(pattern)))?"
    }

    /// Makes a pattern repeat any number of times (?:...)*
    public static func anyNumberOfTimes(_ pattern: Any) -> String {
        "(?:\(source(pattern)))*"
    }

    /// Escapes special regex characters in a string
    public static func escape(_ value: String) -> String {
        let specialChars = CharacterSet(charactersIn: "[-/\\^$*+?.()|[\\]{}]")
        var result = ""
        for char in value.unicodeScalars {
            if specialChars.contains(char) {
                result += "\\"
            }
            result += String(char)
        }
        return result
    }

    /// Extracts the source string from various pattern types
    public static func source(_ value: Any) -> String {
        switch value {
        case let pattern as RegexPattern:
            return pattern.source
        case let regex as NSRegularExpression:
            return regex.pattern
        case let string as String:
            return string
        default:
            return String(describing: value)
        }
    }

    /// Counts the number of capture groups in a pattern
    public static func countMatchGroups(_ pattern: String) -> Int {
        // Create a test regex with an extra alternation to find capture count
        guard let regex = try? NSRegularExpression(pattern: pattern + "|", options: []) else {
            return 0
        }
        return regex.numberOfCaptureGroups
    }

    /// Checks if a regex matches at the start of a string
    public static func startsWith(_ regex: NSRegularExpression?, _ lexeme: String) -> Bool {
        guard let regex = regex else { return false }
        let range = NSRange(lexeme.startIndex..., in: lexeme)
        guard let match = regex.firstMatch(in: lexeme, options: [], range: range) else {
            return false
        }
        return match.range.location == 0
    }

    /// Rewrites backreferences when joining multiple patterns
    /// Each pattern is wrapped in a capture group and backreferences are adjusted
    public static func rewriteBackreferences(_ patterns: [String], joinWith separator: String) -> String {
        // Regex to find backreferences and capture groups
        // Matches: [...] elements, escape sequences, non-capturing groups, or backreferences
        let backrefPattern = #"\[(?:[^\\\]]|\\.)*\]|\(\??|\\([1-9][0-9]*)|\\."#
        guard let backrefRE = try? NSRegularExpression(pattern: backrefPattern, options: []) else {
            // Fallback: just join without rewriting
            return patterns.map { "(\($0))" }.joined(separator: separator)
        }

        var numCaptures = 0
        var results: [String] = []

        for pattern in patterns {
            numCaptures += 1
            let offset = numCaptures
            var remaining = pattern
            var output = ""

            while !remaining.isEmpty {
                let range = NSRange(remaining.startIndex..., in: remaining)
                guard let match = backrefRE.firstMatch(in: remaining, options: [], range: range) else {
                    output += remaining
                    break
                }

                guard let matchRange = Range(match.range, in: remaining) else {
                    output += remaining
                    break
                }
                output += String(remaining[..<matchRange.lowerBound])

                let matchedText = String(remaining[matchRange])
                remaining = String(remaining[matchRange.upperBound...])

                // Check if this is a backreference
                if matchedText.hasPrefix("\\"),
                   match.range(at: 1).location != NSNotFound,
                   Range(match.range(at: 1), in: remaining) != nil {
                    // This is a backreference - need to look at original remaining
                    let originalRemaining = pattern.suffix(from: pattern.index(pattern.startIndex, offsetBy: pattern.count - remaining.count - matchedText.count))
                    let fullMatch = String(originalRemaining[..<originalRemaining.index(originalRemaining.startIndex, offsetBy: matchedText.count)])
                    if fullMatch.hasPrefix("\\") && fullMatch.count > 1 {
                        let numStr = String(fullMatch.dropFirst())
                        if let num = Int(numStr) {
                            output += "\\\(num + offset)"
                            continue
                        }
                    }
                }

                output += matchedText
                if matchedText == "(" {
                    numCaptures += 1
                }
            }

            results.append("(\(output))")
        }

        return results.joined(separator: separator)
    }
}

// MARK: - Common Regex Patterns

extension Regex {
    /// Matches nothing (useful for disabled patterns)
    public static let matchNothingRE = #"\b\B"#

    /// Basic identifier: starts with letter, followed by word chars
    public static let identifierRE = #"[a-zA-Z]\w*"#

    /// Identifier allowing leading underscore
    public static let underscoreIdentifierRE = #"[a-zA-Z_]\w*"#

    /// Simple number
    public static let numberRE = #"\b\d+(\.\d+)?"#

    /// C-style number (hex, decimal, float, exponent)
    public static let cNumberRE = #"(-?)(\b0[xX][a-fA-F0-9]+|(\b\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?)"#

    /// Binary number
    public static let binaryNumberRE = #"\b(0b[01]+)"#

    /// RE starters (operators that can precede a regex)
    public static let reStartersRE = #"!|!=|!==|%|%=|&|&&|&=|\*|\*=|\+|\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\?|\[|\{|\(|\^|\^=|\||\|=|\|\||~"#
}
