import Foundation

public func jsonLanguage(_ hljs: Highlight) -> Language {
    let mode_m1 = Mode(className: "attr", begin: HLJS.re("((\"(\\\\.|[^\\\\\"\\r\\n])*\")|('(\\\\.|[^\\\\'\\r\\n])*'))(?=\\s*:)"))

    let mode_m2 = Mode(className: "punctuation", match: HLJS.re("[{}\\[\\],:]"), relevance: 0)

    let mode_m4 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m3 = Mode(scope: "string", begin: HLJS.re("'"), end: HLJS.re("'"), illegal: HLJS.re("\\n"), contains: [.mode(mode_m4)])

    let mode_m5 = Mode(scope: "string", begin: HLJS.re("\""), end: HLJS.re("\""), illegal: HLJS.re("\\n"), contains: [.mode(mode_m4)])

    let mode_m6 = Mode(scope: "literal", keywords: HLJS.kw(keyword: ["true", "false", "null"]), beginKeywords: "true false null")

    let mode_m7 = Mode(scope: "number", match: HLJS.re("([-+]?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)|NaN|[-+]?Infinity"), relevance: 0)

    let mode_m9 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m10 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m8 = Mode(scope: "comment", begin: HLJS.re("//"), end: HLJS.re("$"), contains: [.mode(mode_m9), .mode(mode_m10)])

    let mode_m12 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m13 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m11 = Mode(scope: "comment", begin: HLJS.re("/\\*"), end: HLJS.re("\\*/"), contains: [.mode(mode_m12), .mode(mode_m13)])

    return Language(
        name: "JSON",
        aliases: ["jsonc", "json5"],
        keywords: HLJS.kw(literal: ["true", "false", "null"]),
        illegal: HLJS.re("\\S"),
        contains: [.mode(mode_m1), .mode(mode_m2), .mode(mode_m3), .mode(mode_m5), .mode(mode_m6), .mode(mode_m7), .mode(mode_m8), .mode(mode_m11)]
    )
}

public extension Highlight {
    func registerJSON() {
        registerLanguage("json") { hljs in jsonLanguage(hljs) }
    }
}
