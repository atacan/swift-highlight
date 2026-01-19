import Foundation

public func diffLanguage(_ hljs: Highlight) -> Language {
    let mode_m1 = Mode(className: "meta", match: HLJS.re("(?:^@@ +-\\d+,\\d+ +\\+\\d+,\\d+ +@@|^@@ +-\\d+ +\\+\\d+,\\d+ +@@|^@@ +-\\d+,\\d+ +\\+\\d+ +@@|^@@ +-\\d+ +\\+\\d+ +@@|^\\*\\*\\* +\\d+,\\d+ +\\*\\*\\*\\*$|^--- +\\d+,\\d+ +----$)"), relevance: 10)

    let mode_m3 = Mode(begin: HLJS.re("(?:Index: |^index|={3,}|^-{3}|^\\*{3} |^\\+{3}|^diff --git)"), end: HLJS.re("$"))

    let mode_m4 = Mode(match: HLJS.re("^\\*{15}$"))

    let mode_m2 = Mode(className: "comment", variants: HLJS.variants([mode_m3, mode_m4]))

    let mode_m5 = Mode(className: "addition", begin: HLJS.re("^\\+"), end: HLJS.re("$"))

    let mode_m6 = Mode(className: "deletion", begin: HLJS.re("^-"), end: HLJS.re("$"))

    let mode_m7 = Mode(className: "addition", begin: HLJS.re("^!"), end: HLJS.re("$"))

    return Language(
        name: "Diff",
        aliases: ["patch"],
        contains: [.mode(mode_m1), .mode(mode_m2), .mode(mode_m5), .mode(mode_m6), .mode(mode_m7)]
    )
}

public extension Highlight {
    func registerDiff() {
        registerLanguage("diff") { hljs in diffLanguage(hljs) }
    }
}
