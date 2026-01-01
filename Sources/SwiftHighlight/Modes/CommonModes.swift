import Foundation

/// Common modes used across many languages
extension Highlight {
    /// Backslash escape sequence
    public static var backslashEscape: Mode {
        Mode(begin: #"\\[\s\S]"#, relevance: 0)
    }

    /// Single-quoted string
    public static var aposStringMode: Mode {
        Mode(
            scope: "string",
            begin: "'",
            end: "'",
            illegal: #"\n"#,
            contains: [.mode(backslashEscape)]
        )
    }

    /// Double-quoted string
    public static var quoteStringMode: Mode {
        Mode(
            scope: "string",
            begin: "\"",
            end: "\"",
            illegal: #"\n"#,
            contains: [.mode(backslashEscape)]
        )
    }

    /// Creates a comment mode
    public static func comment(begin: RegexPattern, end: RegexPattern, relevance: Int? = nil) -> Mode {
        // Doctag highlighting
        let doctag = Mode(
            scope: "doctag",
            begin: .string(#"(?=TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX)"#),
            end: .string(#"(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"#),
            relevance: 0,
            excludeBegin: true
        )

        return Mode(
            scope: "comment",
            begin: begin,
            end: end,
            contains: [.mode(doctag)],
            relevance: relevance
        )
    }

    /// C-style line comment //
    public static var cLineCommentMode: Mode {
        comment(begin: "//", end: "$")
    }

    /// C-style block comment /* */
    public static var cBlockCommentMode: Mode {
        comment(begin: #"/\*"#, end: #"\*/"#)
    }

    /// Hash comment #
    public static var hashCommentMode: Mode {
        comment(begin: "#", end: "$")
    }

    /// Simple number mode
    public static var numberMode: Mode {
        Mode(
            scope: "number",
            begin: .string(Regex.numberRE),
            relevance: 0
        )
    }

    /// C-style number mode (hex, float, exponent)
    public static var cNumberMode: Mode {
        Mode(
            scope: "number",
            begin: .string(Regex.cNumberRE),
            relevance: 0
        )
    }

    /// Binary number mode
    public static var binaryNumberMode: Mode {
        Mode(
            scope: "number",
            begin: .string(Regex.binaryNumberRE),
            relevance: 0
        )
    }

    /// Title mode for function/class names
    public static var titleMode: Mode {
        Mode(
            scope: "title",
            begin: .string(Regex.identifierRE),
            relevance: 0
        )
    }

    /// Underscore title mode (allows leading underscore)
    public static var underscoreTitleMode: Mode {
        Mode(
            scope: "title",
            begin: .string(Regex.underscoreIdentifierRE),
            relevance: 0
        )
    }

    /// Method guard (excludes method names from keyword processing)
    public static var methodGuard: Mode {
        Mode(
            begin: .string(#"\.\s*"# + Regex.underscoreIdentifierRE),
            relevance: 0
        )
    }

    /// Shebang mode
    public static func shebang(binary: String? = nil) -> Mode {
        var beginPattern = #"^#![ ]*/"#
        if let binary = binary {
            beginPattern = Regex.concat(#"^#![ ]*/"#, ".*\\b", binary, "\\b.*")
        }

        return Mode(
            scope: "meta",
            begin: .string(beginPattern),
            end: "$",
            relevance: 0,
            // Only match at start of file
            onBegin: { match in
                if match.range.location != 0 {
                    return .ignoreMatch
                }
                return .continue
            }
        )
    }
}
