import Foundation

public func iniLanguage(_ hljs: Highlight) -> Language {
    let mode_m2 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m3 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m4 = Mode(begin: HLJS.re(";"), end: HLJS.re("$"))

    let mode_m5 = Mode(begin: HLJS.re("#"), end: HLJS.re("$"))

    let mode_m1 = Mode(scope: "comment", contains: [.mode(mode_m2), .mode(mode_m3)], variants: HLJS.variants([mode_m4, mode_m5]))

    let mode_m6 = Mode(className: "section", begin: HLJS.re("\\[+"), end: HLJS.re("\\]+"))

    let mode_m10 = Mode(className: "literal", begin: HLJS.re("\\bon|off|true|false|yes|no\\b"))

    let mode_m12 = Mode(begin: HLJS.re("\\$[\\w\\d\"][\\w\\d_]*"))

    let mode_m13 = Mode(begin: HLJS.re("\\$\\{(.*?)\\}"))

    let mode_m11 = Mode(className: "variable", variants: HLJS.variants([mode_m12, mode_m13]))

    let mode_m15 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m16 = Mode(begin: HLJS.re("'''"), end: HLJS.re("'''"), relevance: 10)

    let mode_m17 = Mode(begin: HLJS.re("\"\"\""), end: HLJS.re("\"\"\""), relevance: 10)

    let mode_m18 = Mode(begin: HLJS.re("\""), end: HLJS.re("\""))

    let mode_m19 = Mode(begin: HLJS.re("'"), end: HLJS.re("'"))

    let mode_m14 = Mode(className: "string", contains: [.mode(mode_m15)], variants: HLJS.variants([mode_m16, mode_m17, mode_m18, mode_m19]))

    let mode_m21 = Mode(begin: HLJS.re("([+-]+)?[\\d]+_[\\d_]+"))

    let mode_m22 = Mode(begin: HLJS.re("\\b\\d+(\\.\\d+)?"))

    let mode_m20 = Mode(className: "number", variants: HLJS.variants([mode_m21, mode_m22]), relevance: 0)

    let mode_m9 = Mode(begin: HLJS.re("\\["), end: HLJS.re("\\]"), contains: [.mode(mode_m1), .mode(mode_m10), .mode(mode_m11), .mode(mode_m14), .mode(mode_m20), .self], relevance: 0)

    let mode_m8 = Mode(end: HLJS.re("$"), contains: [.mode(mode_m1), .mode(mode_m9), .mode(mode_m10), .mode(mode_m11), .mode(mode_m14), .mode(mode_m20)])

    let mode_m7 = Mode(className: "attr", begin: HLJS.re("(?:[A-Za-z0-9_-]+|\"(\\\\\"|[^\"])*\"|'[^']*')(\\s*\\.\\s*(?:[A-Za-z0-9_-]+|\"(\\\\\"|[^\"])*\"|'[^']*'))*(?=\\s*=\\s*[^#\\s])"), starts: ModeBox(mode_m8))

    return Language(
        name: "TOML, also INI",
        aliases: ["toml"],
        caseInsensitive: true,
        illegal: HLJS.re("\\S"),
        contains: [.mode(mode_m1), .mode(mode_m6), .mode(mode_m7)]
    )
}

public extension Highlight {
    func registerIni() {
        registerLanguage("ini") { hljs in iniLanguage(hljs) }
    }
}
