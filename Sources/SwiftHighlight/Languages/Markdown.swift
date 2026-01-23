import Foundation

public func markdownLanguage(_ hljs: Highlight) -> Language {
    let mode_m3 = Mode(begin: HLJS.re("<\\/?[A-Za-z_]"), end: HLJS.re(">"), relevance: 0, subLanguage: SubLanguage.single("xml"))

    let mode_m5 = Mode(match: HLJS.re("\\[(?=\\])"))

    let mode_m6 = Mode(className: "string", begin: HLJS.re("\\["), end: HLJS.re("\\]"), relevance: 0, excludeBegin: true, returnEnd: true)

    let mode_m7 = Mode(className: "link", begin: HLJS.re("\\]\\("), end: HLJS.re("\\)"), relevance: 0, excludeBegin: true, excludeEnd: true)

    let mode_m8 = Mode(className: "symbol", begin: HLJS.re("\\]\\["), end: HLJS.re("\\]"), relevance: 0, excludeBegin: true, excludeEnd: true)

    let mode_m9 = Mode(begin: HLJS.re("\\[.+?\\]\\[.*?\\]"), relevance: 0)

    let mode_m10 = Mode(begin: HLJS.re("\\[.+?\\]\\(((data|javascript|mailto):|(?:http|ftp)s?:\\/\\/).*?\\)"), relevance: 2)

    let mode_m11 = Mode(begin: HLJS.re("\\[.+?\\]\\([A-Za-z][A-Za-z0-9+.-]*:\\/\\/.*?\\)"), relevance: 2)

    let mode_m12 = Mode(begin: HLJS.re("\\[.+?\\]\\([./?&#].*?\\)"), relevance: 1)

    let mode_m13 = Mode(begin: HLJS.re("\\[.*?\\]\\(.*?\\)"), relevance: 0)

    let mode_m4 = Mode(contains: [.mode(mode_m5), .mode(mode_m6), .mode(mode_m7), .mode(mode_m8)], variants: HLJS.variants([mode_m9, mode_m10, mode_m11, mode_m12, mode_m13]), returnBegin: true)

    let mode_m16 = Mode(begin: HLJS.re("\\*(?![*\\s])"), end: HLJS.re("\\*"))

    let mode_m17 = Mode(begin: HLJS.re("_(?![_\\s])"), end: HLJS.re("_"), relevance: 0)

    let mode_m15 = Mode(className: "emphasis", contains: [.mode(mode_m3), .mode(mode_m4)], variants: HLJS.variants([mode_m16, mode_m17]))

    let mode_m18 = Mode(begin: HLJS.re("_{2}(?!\\s)"), end: HLJS.re("_{2}"))

    let mode_m19 = Mode(begin: HLJS.re("\\*{2}(?!\\s)"), end: HLJS.re("\\*{2}"))

    let mode_m14 = Mode(className: "strong", contains: [.mode(mode_m15), .mode(mode_m3), .mode(mode_m4)], variants: HLJS.variants([mode_m18, mode_m19]))

    let mode_m21 = Mode(className: "strong", contains: [.mode(mode_m3), .mode(mode_m4)], variants: HLJS.variants([mode_m18, mode_m19]))

    let mode_m20 = Mode(className: "emphasis", contains: [.mode(mode_m21), .mode(mode_m3), .mode(mode_m4)], variants: HLJS.variants([mode_m16, mode_m17]))

    let mode_m2 = Mode(begin: HLJS.re("^#{1,6}"), end: HLJS.re("$"), contains: [.mode(mode_m3), .mode(mode_m4), .mode(mode_m14), .mode(mode_m20)])

    let mode_m23 = Mode(begin: HLJS.re("^[=-]{2,}$"), endsParent: true)

    let mode_m24 = Mode(begin: HLJS.re("^"), end: HLJS.re("\\n"), contains: [.mode(mode_m3), .mode(mode_m4), .mode(mode_m14), .mode(mode_m20)])

    let mode_m22 = Mode(begin: HLJS.re("(?=^.+?\\n[=-]{2,}$)"), contains: [.mode(mode_m23), .mode(mode_m24)])

    let mode_m1 = Mode(className: "section", variants: HLJS.variants([mode_m2, mode_m22]))

    let mode_m25 = Mode(className: "bullet", begin: HLJS.re("^[ \t]*([*+-]|(\\d+\\.))(?=\\s+)"), end: HLJS.re("\\s+"), excludeEnd: true)

    let mode_m26 = Mode(className: "quote", begin: HLJS.re("^>\\s+"), end: HLJS.re("$"), contains: [.mode(mode_m3), .mode(mode_m4), .mode(mode_m14), .mode(mode_m20)])

    let mode_m28 = Mode(begin: HLJS.re("(`{3,})[^`](.|\\n)*?\\1`*[ ]*"))

    let mode_m29 = Mode(begin: HLJS.re("(~{3,})[^~](.|\\n)*?\\1~*[ ]*"))

    let mode_m30 = Mode(begin: HLJS.re("```"), end: HLJS.re("```+[ ]*$"))

    let mode_m31 = Mode(begin: HLJS.re("~~~"), end: HLJS.re("~~~+[ ]*$"))

    let mode_m32 = Mode(begin: HLJS.re("`.+?`"))

    let mode_m34 = Mode(begin: HLJS.re("^( {4}|\\t)"), end: HLJS.re("(\\n)$"))

    let mode_m33 = Mode(begin: HLJS.re("(?=^( {4}|\\t))"), contains: [.mode(mode_m34)], relevance: 0)

    let mode_m27 = Mode(className: "code", variants: HLJS.variants([mode_m28, mode_m29, mode_m30, mode_m31, mode_m32, mode_m33]))

    let mode_m35 = Mode(begin: HLJS.re("^[-\\*]{3,}"), end: HLJS.re("$"))

    let mode_m37 = Mode(className: "symbol", begin: HLJS.re("\\["), end: HLJS.re("\\]"), excludeBegin: true, excludeEnd: true)

    let mode_m38 = Mode(className: "link", begin: HLJS.re(":\\s*"), end: HLJS.re("$"), excludeBegin: true)

    let mode_m36 = Mode(begin: HLJS.re("^\\[[^\\n]+\\]:"), contains: [.mode(mode_m37), .mode(mode_m38)], returnBegin: true)

    let mode_m39 = Mode(scope: "literal", match: HLJS.re("&([a-zA-Z0-9]+|#[0-9]{1,7}|#[Xx][0-9a-fA-F]{1,6});"))

    return Language(
        name: "Markdown",
        aliases: ["md", "mkdown", "mkd"],
        contains: [.mode(mode_m1), .mode(mode_m3), .mode(mode_m25), .mode(mode_m14), .mode(mode_m20), .mode(mode_m26), .mode(mode_m27), .mode(mode_m35), .mode(mode_m4), .mode(mode_m36), .mode(mode_m39)]
    )
}

public extension Highlight {
    func registerMarkdown() {
        registerXml()
        registerLanguage("markdown") { hljs in markdownLanguage(hljs) }
    }
}
