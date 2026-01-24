import Foundation

public func goLanguage(_ hljs: Highlight) -> Language {
    let mode_m2 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m3 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m1 = Mode(scope: "comment", begin: HLJS.re("//"), end: HLJS.re("$"), contains: [.mode(mode_m2), .mode(mode_m3)])

    let mode_m5 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m6 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m4 = Mode(scope: "comment", begin: HLJS.re("/\\*"), end: HLJS.re("\\*/"), contains: [.mode(mode_m5), .mode(mode_m6)])

    let mode_m9 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m8 = Mode(scope: "string", begin: HLJS.re("\""), end: HLJS.re("\""), illegal: HLJS.re("\\n"), contains: [.mode(mode_m9)])

    let mode_m10 = Mode(scope: "string", begin: HLJS.re("'"), end: HLJS.re("'"), illegal: HLJS.re("\\n"), contains: [.mode(mode_m9)])

    let mode_m11 = Mode(begin: HLJS.re("`"), end: HLJS.re("`"))

    let mode_m7 = Mode(className: "string", variants: HLJS.variants([mode_m8, mode_m10, mode_m11]))

    let mode_m13 = Mode(match: HLJS.re("-?\\b0[xX]\\.[a-fA-F0-9](_?[a-fA-F0-9])*[pP][+-]?\\d(_?\\d)*i?"), relevance: 0)

    let mode_m14 = Mode(match: HLJS.re("-?\\b0[xX](_?[a-fA-F0-9])+((\\.([a-fA-F0-9](_?[a-fA-F0-9])*)?)?[pP][+-]?\\d(_?\\d)*)?i?"), relevance: 0)

    let mode_m15 = Mode(match: HLJS.re("-?\\b0[oO](_?[0-7])*i?"), relevance: 0)

    let mode_m16 = Mode(match: HLJS.re("-?\\.\\d(_?\\d)*([eE][+-]?\\d(_?\\d)*)?i?"), relevance: 0)

    let mode_m17 = Mode(match: HLJS.re("-?\\b\\d(_?\\d)*(\\.(\\d(_?\\d)*)?)?([eE][+-]?\\d(_?\\d)*)?i?"), relevance: 0)

    let mode_m12 = Mode(className: "number", variants: HLJS.variants([mode_m13, mode_m14, mode_m15, mode_m16, mode_m17]))

    let mode_m18 = Mode(begin: HLJS.re(":="))

    let mode_m20 = Mode(scope: "title", begin: HLJS.re("[a-zA-Z]\\w*"), relevance: 0)

    let mode_m21 = Mode(className: "params", begin: HLJS.re("\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(keyword: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct", "switch", "type", "var"], literal: ["true", "false", "iota", "nil"], builtIn: ["append", "cap", "close", "complex", "copy", "imag", "len", "make", "new", "panic", "print", "println", "real", "recover", "delete"], type: ["bool", "byte", "complex64", "complex128", "error", "float32", "float64", "int8", "int16", "int32", "int64", "string", "uint8", "uint16", "uint32", "uint64", "int", "uint", "uintptr", "rune"]), illegal: HLJS.re("[\"']"), endsParent: true)

    let mode_m19 = Mode(className: "function", end: HLJS.re("\\s*(\\{|$)"), contains: [.mode(mode_m20), .mode(mode_m21)], excludeEnd: true, beginKeywords: "func")

    return Language(
        name: "Go",
        aliases: ["golang"],
        keywords: HLJS.kw(keyword: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct", "switch", "type", "var"], literal: ["true", "false", "iota", "nil"], builtIn: ["append", "cap", "close", "complex", "copy", "imag", "len", "make", "new", "panic", "print", "println", "real", "recover", "delete"], type: ["bool", "byte", "complex64", "complex128", "error", "float32", "float64", "int8", "int16", "int32", "int64", "string", "uint8", "uint16", "uint32", "uint64", "int", "uint", "uintptr", "rune"]),
        illegal: HLJS.re("</"),
        contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m7), .mode(mode_m12), .mode(mode_m18), .mode(mode_m19)]
    )
}

public extension Highlight {
    func registerGo() {
        registerLanguage("go") { hljs in goLanguage(hljs) }
    }
}
