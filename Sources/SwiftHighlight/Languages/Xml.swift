import Foundation

public func xmlLanguage(_ hljs: Highlight) -> Language {
    let mode_m3 = Mode(className: "keyword", begin: HLJS.re("#?[a-z_][a-z1-9_-]+"), illegal: HLJS.re("\\n"))

    let mode_m2 = Mode(begin: HLJS.re("\\s"), contains: [.mode(mode_m3)])

    let mode_m5 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m4 = Mode(scope: "string", className: "string", begin: HLJS.re("\""), end: HLJS.re("\""), illegal: HLJS.re("\\n"), contains: [.mode(mode_m5)])

    let mode_m6 = Mode(scope: "string", className: "string", begin: HLJS.re("'"), end: HLJS.re("'"), illegal: HLJS.re("\\n"), contains: [.mode(mode_m5)])

    let mode_m7 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.mode(mode_m3)])

    let mode_m9 = Mode(className: "meta", begin: HLJS.re("<![a-z]"), end: HLJS.re(">"), contains: [.mode(mode_m2), .mode(mode_m7), .mode(mode_m4), .mode(mode_m6)])

    let mode_m8 = Mode(begin: HLJS.re("\\["), end: HLJS.re("\\]"), contains: [.mode(mode_m9)])

    let mode_m1 = Mode(className: "meta", begin: HLJS.re("<![a-z]"), end: HLJS.re(">"), contains: [.mode(mode_m2), .mode(mode_m4), .mode(mode_m6), .mode(mode_m7), .mode(mode_m8)], relevance: 10)

    let mode_m11 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m12 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m10 = Mode(scope: "comment", begin: HLJS.re("<!--"), end: HLJS.re("-->"), contains: [.mode(mode_m11), .mode(mode_m12)], relevance: 10)

    let mode_m13 = Mode(begin: HLJS.re("<!\\[CDATA\\["), end: HLJS.re("\\]\\]>"), relevance: 10)

    let mode_m14 = Mode(className: "symbol", begin: HLJS.re("&[a-z]+;|&#[0-9]+;|&#x[a-f0-9]+;"))

    let mode_m16 = Mode(begin: HLJS.re("<\\?xml"), contains: [.mode(mode_m4)], relevance: 10)

    let mode_m17 = Mode(begin: HLJS.re("<\\?[a-z][a-z0-9]+"))

    let mode_m15 = Mode(className: "meta", end: HLJS.re("\\?>"), variants: HLJS.variants([mode_m16, mode_m17]))

    let mode_m19 = Mode(end: HLJS.re("<\\/style>"), returnEnd: true, subLanguage: SubLanguage.multiple(["css", "xml"]))

    let mode_m21 = Mode(className: "attr", begin: HLJS.re("[\\p{L}0-9._:-]+"), relevance: 0)

    let mode_m24 = Mode(begin: HLJS.re("\""), end: HLJS.re("\""), contains: [.mode(mode_m14)])

    let mode_m25 = Mode(begin: HLJS.re("'"), end: HLJS.re("'"), contains: [.mode(mode_m14)])

    let mode_m26 = Mode(begin: HLJS.re("[^\\s\"'=<>`]+"))

    let mode_m23 = Mode(className: "string", variants: HLJS.variants([mode_m24, mode_m25, mode_m26]), endsParent: true)

    let mode_m22 = Mode(begin: HLJS.re("=\\s*"), contains: [.mode(mode_m23)], relevance: 0)

    let mode_m20 = Mode(illegal: HLJS.re("<"), contains: [.mode(mode_m21), .mode(mode_m22)], relevance: 0, endsWithParent: true)

    let mode_m18 = Mode(className: "tag", begin: HLJS.re("<style(?=\\s|>)"), end: HLJS.re(">"), keywords: HLJS.kw(custom: ["name": ["style"]]), contains: [.mode(mode_m20)], starts: ModeBox(mode_m19))

    let mode_m28 = Mode(end: HLJS.re("<\\/script>"), returnEnd: true, subLanguage: SubLanguage.multiple(["javascript", "handlebars", "xml"]))

    let mode_m27 = Mode(className: "tag", begin: HLJS.re("<script(?=\\s|>)"), end: HLJS.re(">"), keywords: HLJS.kw(custom: ["name": ["script"]]), contains: [.mode(mode_m20)], starts: ModeBox(mode_m28))

    let mode_m29 = Mode(className: "tag", begin: HLJS.re("<>|<\\/>"))

    let mode_m31 = Mode(className: "name", begin: HLJS.re("[\\p{L}_](?:[\\p{L}0-9_.-]*:)?[\\p{L}0-9_.-]*"), relevance: 0, starts: ModeBox(mode_m20))

    let mode_m30 = Mode(className: "tag", begin: HLJS.re("<(?=[\\p{L}_](?:[\\p{L}0-9_.-]*:)?[\\p{L}0-9_.-]*(?:\\/>|>|\\s))"), end: HLJS.re("\\/?>"), contains: [.mode(mode_m31)])

    let mode_m33 = Mode(className: "name", begin: HLJS.re("[\\p{L}_](?:[\\p{L}0-9_.-]*:)?[\\p{L}0-9_.-]*"), relevance: 0)

    let mode_m34 = Mode(begin: HLJS.re(">"), relevance: 0, endsParent: true)

    let mode_m32 = Mode(className: "tag", begin: HLJS.re("<\\/(?=[\\p{L}_](?:[\\p{L}0-9_.-]*:)?[\\p{L}0-9_.-]*>)"), contains: [.mode(mode_m33), .mode(mode_m34)])

    return Language(
        name: "HTML, XML",
        aliases: ["html", "xhtml", "rss", "atom", "xjb", "xsd", "xsl", "plist", "wsf", "svg"],
        caseInsensitive: true,
        unicodeRegex: true,
        contains: [.mode(mode_m1), .mode(mode_m10), .mode(mode_m13), .mode(mode_m14), .mode(mode_m15), .mode(mode_m18), .mode(mode_m27), .mode(mode_m29), .mode(mode_m30), .mode(mode_m32)]
    )
}

public extension Highlight {
    func registerXml() {
        registerLanguage("xml") { hljs in xmlLanguage(hljs) }
    }
}
