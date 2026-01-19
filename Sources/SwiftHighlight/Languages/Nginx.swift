import Foundation

public func nginxLanguage(_ hljs: Highlight) -> Language {
    let mode_m2 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m3 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m1 = Mode(scope: "comment", begin: HLJS.re("#"), end: HLJS.re("$"), contains: [.mode(mode_m2), .mode(mode_m3)])

    let mode_m6 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m8 = Mode(begin: HLJS.re("\\$\\d+"))

    let mode_m9 = Mode(begin: HLJS.re("\\$\\{\\w+\\}"))

    let mode_m10 = Mode(begin: HLJS.re("[$@][a-zA-Z_]\\w*"))

    let mode_m7 = Mode(className: "variable", variants: HLJS.variants([mode_m8, mode_m9, mode_m10]))

    let mode_m11 = Mode(begin: HLJS.re("\""), end: HLJS.re("\""))

    let mode_m12 = Mode(begin: HLJS.re("'"), end: HLJS.re("'"))

    let mode_m5 = Mode(className: "string", contains: [.mode(mode_m6), .mode(mode_m7)], variants: HLJS.variants([mode_m11, mode_m12]))

    let mode_m13 = Mode(begin: HLJS.re("([a-z]+):/"), end: HLJS.re("\\s"), contains: [.mode(mode_m7)], excludeEnd: true, endsWithParent: true)

    let mode_m15 = Mode(begin: HLJS.re("\\s\\^"), end: HLJS.re("\\s|\\{|;"), returnEnd: true)

    let mode_m16 = Mode(begin: HLJS.re("~\\*?\\s+"), end: HLJS.re("\\s|\\{|;"), returnEnd: true)

    let mode_m17 = Mode(begin: HLJS.re("\\*(\\.[a-z\\-]+)+"))

    let mode_m18 = Mode(begin: HLJS.re("([a-z\\-]+\\.)+\\*"))

    let mode_m14 = Mode(className: "regexp", contains: [.mode(mode_m6), .mode(mode_m7)], variants: HLJS.variants([mode_m15, mode_m16, mode_m17, mode_m18]))

    let mode_m19 = Mode(className: "number", begin: HLJS.re("\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(:\\d{1,5})?\\b"))

    let mode_m20 = Mode(className: "number", begin: HLJS.re("\\b\\d+[kKmMgGdshdwy]?\\b"), relevance: 0)

    let mode_m4 = Mode(end: HLJS.re(";|\\{"), keywords: HLJS.kw(custom: ["section": ["upstream", "location"]]), contains: [.mode(mode_m1), .mode(mode_m5), .mode(mode_m13), .mode(mode_m14), .mode(mode_m19), .mode(mode_m20), .mode(mode_m7)], beginKeywords: "upstream location")

    let mode_m21 = Mode(className: "section", begin: HLJS.re("[a-zA-Z_]\\w*(?=\\s+\\{)"), relevance: 0)

    let mode_m24 = Mode(keywords: HLJS.kw(pattern: HLJS.re("[a-z_]{2,}|\\/dev\\/poll"), literal: ["on", "off", "yes", "no", "true", "false", "none", "blocked", "debug", "info", "notice", "warn", "error", "crit", "select", "break", "last", "permanent", "redirect", "kqueue", "rtsig", "epoll", "poll", "/dev/poll"]), illegal: HLJS.re("=>"), contains: [.mode(mode_m1), .mode(mode_m5), .mode(mode_m13), .mode(mode_m14), .mode(mode_m19), .mode(mode_m20), .mode(mode_m7)], relevance: 0, endsWithParent: true)

    let mode_m23 = Mode(className: "attribute", begin: HLJS.re("[a-zA-Z_]\\w*"), starts: ModeBox(mode_m24))

    let mode_m22 = Mode(begin: HLJS.re("(?=[a-zA-Z_]\\w*\\s)"), end: HLJS.re(";|\\{"), contains: [.mode(mode_m23)], relevance: 0)

    return Language(
        name: "Nginx config",
        aliases: ["nginxconf"],
        illegal: HLJS.re("[^\\s\\}\\{]"),
        contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m21), .mode(mode_m22)]
    )
}

public extension Highlight {
    func registerNginx() {
        registerLanguage("nginx") { hljs in nginxLanguage(hljs) }
    }
}
