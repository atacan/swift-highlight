import Foundation

/// Compiled mode ready for matching
internal final class CompiledMode {
    var scope: String?
    var begin: NSRegularExpression?
    var end: NSRegularExpression?
    var beginRe: NSRegularExpression?
    var endRe: NSRegularExpression?
    var illegalRe: NSRegularExpression?
    var terminatorEnd: String = ""

    var keywords: CompiledKeywords?
    var keywordPatternRe: NSRegularExpression?

    var contains: [CompiledMode] = []
    var starts: CompiledMode?
    /// Parent mode - strong reference for runtime instances created in startNewMode
    /// (The compile-time modes in ModeCompiler use this as weak via explicit handling)
    var parent: CompiledMode?

    var relevance: Int = 1
    var excludeBegin = false
    var excludeEnd = false
    var returnBegin = false
    var returnEnd = false
    var endsWithParent = false
    var endsParent = false
    var skip = false

    var subLanguage: SubLanguage?
    var beginScope: CompiledScope?
    var endScope: CompiledScope?

    var matcher: ResumableMultiRegex?

    var onBegin: ModeCallback?
    var onEnd: ModeCallback?
    var beforeBegin: ModeCallback?

    /// Cached case-insensitivity flag from language definition
    var caseInsensitive: Bool = false

    init() {}
}

/// Compiled scope for multi-class matching
internal struct CompiledScope {
    var wrap: String?
    var multi: Bool = false
    var emit: [Int: Bool] = [:]
    var scopes: [Int: String] = [:]
}

/// Compiles language definitions into executable form
internal final class ModeCompiler {
    private let language: Language
    private let caseInsensitive: Bool
    private let unicode: Bool

    /// Track modes currently being compiled to detect cycles (using UUID)
    private var compilingModes: Set<UUID> = []

    /// Cache of compiled modes by UUID
    private var modeCache: [UUID: CompiledMode] = [:]

    /// Maximum recursion depth to prevent stack overflow
    private let maxDepth = 50

    init(language: Language) {
        self.language = language
        self.caseInsensitive = language.caseInsensitive
        self.unicode = language.unicodeRegex
    }

    func compile() -> CompiledMode {
        return compileMode(languageToMode(language), parent: nil, depth: 0, selfMode: nil)
    }

    private func languageToMode(_ lang: Language) -> Mode {
        Mode(
            keywords: lang.keywords,
            illegal: lang.illegal,
            contains: lang.contains
        )
    }

    private func langRe(_ pattern: RegexPattern?, global: Bool = false) -> NSRegularExpression? {
        guard let pattern = pattern else { return nil }

        var options: NSRegularExpression.Options = [.anchorsMatchLines]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }

        return try? NSRegularExpression(pattern: pattern.source, options: options)
    }

    private func langRe(_ pattern: String, global: Bool = false) -> NSRegularExpression? {
        langRe(RegexPattern.string(pattern), global: global)
    }

    private func compileMode(_ mode: Mode, parent: CompiledMode?, depth: Int, selfMode: Mode?) -> CompiledMode {
        // Recursion depth check
        guard depth < maxDepth else {
            // Return a minimal compiled mode to prevent stack overflow
            return CompiledMode()
        }

        // Check if already compiled (reuse cached result)
        if let cached = modeCache[mode.id] {
            return cached
        }

        // Detect cycles - if we're already compiling this exact mode instance, return a placeholder
        if compilingModes.contains(mode.id) {
            return CompiledMode()
        }

        // Mark as being compiled
        compilingModes.insert(mode.id)
        defer { compilingModes.remove(mode.id) }

        let cmode = CompiledMode()
        cmode.caseInsensitive = caseInsensitive

        // Cache early so .self references can find it
        modeCache[mode.id] = cmode

        if mode.scope != nil || mode.className != nil {
            cmode.scope = mode.scope ?? mode.className
        }

        // Compute effective begin pattern (handle match -> begin and beginKeywords)
        let effectiveBegin: RegexPattern? = {
            if let match = mode.match {
                return match
            }
            if let beginKeywords = mode.beginKeywords {
                let words = beginKeywords.split(separator: " ").map { String($0) }
                let pattern = "\\b(" + words.joined(separator: "|") + ")\\b"
                return .string(pattern)
            }
            return mode.begin
        }()

        // Compile begin/end patterns
        if parent != nil {
            let beginPattern = effectiveBegin ?? .string(#"\B|\b"#)
            cmode.beginRe = langRe(beginPattern)

            let effectiveEnd: RegexPattern?
            if mode.end == nil && !mode.endsWithParent {
                effectiveEnd = .string(#"\B|\b"#)
            } else {
                effectiveEnd = mode.end
            }

            if let end = effectiveEnd {
                cmode.endRe = langRe(end)
            }

            cmode.terminatorEnd = effectiveEnd?.source ?? ""
            if mode.endsWithParent, let parentEnd = parent?.terminatorEnd {
                cmode.terminatorEnd += (effectiveEnd != nil ? "|" : "") + parentEnd
            }
        }

        // Compile illegal
        if let illegal = mode.illegal {
            cmode.illegalRe = langRe(illegal)
        }

        // Copy flags
        cmode.relevance = mode.relevance ?? 1
        cmode.excludeBegin = mode.excludeBegin
        cmode.excludeEnd = mode.excludeEnd
        cmode.returnBegin = mode.returnBegin
        cmode.returnEnd = mode.returnEnd
        cmode.endsWithParent = mode.endsWithParent
        cmode.endsParent = mode.endsParent
        cmode.skip = mode.skip
        cmode.subLanguage = mode.subLanguage
        cmode.onBegin = mode.onBegin
        cmode.onEnd = mode.onEnd

        // Compile begin/end scopes
        if let beginScope = mode.beginScope {
            cmode.beginScope = compileScope(beginScope)
        }
        if let endScope = mode.endScope {
            cmode.endScope = compileScope(endScope)
        }

        // Compile keywords
        if let keywords = mode.keywords {
            cmode.keywords = compileKeywords(keywords)
            let pattern = keywords.pattern?.source ?? #"\w+"#
            cmode.keywordPatternRe = langRe(pattern, global: true)
        }

        // Determine the selfMode for .self references
        let effectiveSelfMode = selfMode ?? mode

        // Expand variants
        var containsModes: [Mode] = []
        if let variants = mode.variants {
            for variantBox in variants {
                let merged = mergeMode(mode, variantBox.value)
                containsModes.append(contentsOf: expandContains(merged.contains, selfMode: effectiveSelfMode))
            }
        } else {
            containsModes = expandContains(mode.contains, selfMode: effectiveSelfMode)
        }

        // Compile contains
        for childMode in containsModes {
            let compiled = compileMode(childMode, parent: cmode, depth: depth + 1, selfMode: effectiveSelfMode)
            compiled.parent = cmode
            cmode.contains.append(compiled)
        }

        // Compile starts
        if let startsBox = mode.starts {
            cmode.starts = compileMode(startsBox.value, parent: parent, depth: depth + 1, selfMode: effectiveSelfMode)
        }

        // Build matcher
        cmode.matcher = buildModeRegex(cmode)

        return cmode
    }

    private func compileScope(_ scope: Scope) -> CompiledScope {
        var compiled = CompiledScope()
        switch scope {
        case .simple(let name):
            compiled.wrap = name
        case .indexed(let scopes):
            compiled.multi = true
            for (idx, name) in scopes {
                compiled.scopes[idx] = name
                compiled.emit[idx] = true
            }
        }
        return compiled
    }

    private func expandContains(_ contains: [ModeReference], selfMode: Mode) -> [Mode] {
        var result: [Mode] = []
        for ref in contains {
            switch ref {
            case .self:
                // Create a shallow wrapper that refers to selfMode but WITHOUT .self in contains
                // This breaks the infinite recursion
                let selfCopy = Mode(
                    scope: selfMode.scope,
                    className: selfMode.className,
                    begin: selfMode.begin,
                    end: selfMode.end,
                    match: selfMode.match,
                    keywords: selfMode.keywords,
                    illegal: selfMode.illegal,
                    contains: [],  // Important: do NOT copy contains - leave empty to prevent recursion
                    relevance: selfMode.relevance,
                    excludeBegin: selfMode.excludeBegin,
                    excludeEnd: selfMode.excludeEnd,
                    returnBegin: selfMode.returnBegin,
                    returnEnd: selfMode.returnEnd,
                    endsWithParent: true,  // .self references should end with parent
                    endsParent: selfMode.endsParent,
                    skip: selfMode.skip,
                    subLanguage: selfMode.subLanguage,
                    beginScope: selfMode.beginScope,
                    endScope: selfMode.endScope,
                    onBegin: selfMode.onBegin,
                    onEnd: selfMode.onEnd,
                    beginKeywords: selfMode.beginKeywords
                )
                result.append(selfCopy)
            case .mode(let mBox):
                let m = mBox.value
                if let variants = m.variants {
                    for variantBox in variants {
                        result.append(mergeMode(m, variantBox.value))
                    }
                } else {
                    result.append(m)
                }
            }
        }
        return result
    }

    private func mergeMode(_ base: Mode, _ override: Mode) -> Mode {
        Mode(
            scope: override.scope ?? base.scope,
            className: override.className ?? base.className,
            begin: override.begin ?? base.begin,
            end: override.end ?? base.end,
            match: override.match ?? base.match,
            keywords: override.keywords ?? base.keywords,
            illegal: override.illegal ?? base.illegal,
            contains: override.contains.isEmpty ? base.contains : override.contains,
            variants: nil,  // Variants are expanded, so no longer needed
            relevance: override.relevance ?? base.relevance,
            excludeBegin: override.excludeBegin || base.excludeBegin,
            excludeEnd: override.excludeEnd || base.excludeEnd,
            returnBegin: override.returnBegin || base.returnBegin,
            returnEnd: override.returnEnd || base.returnEnd,
            endsWithParent: override.endsWithParent || base.endsWithParent,
            endsParent: override.endsParent || base.endsParent,
            skip: override.skip || base.skip,
            subLanguage: override.subLanguage ?? base.subLanguage,
            beginScope: override.beginScope ?? base.beginScope,
            endScope: override.endScope ?? base.endScope,
            starts: override.starts ?? base.starts,
            onBegin: override.onBegin ?? base.onBegin,
            onEnd: override.onEnd ?? base.onEnd,
            beginKeywords: override.beginKeywords ?? base.beginKeywords
        )
    }

    private func compileKeywords(_ keywords: Keywords) -> CompiledKeywords? {
        var compiled: [String: (scope: String, relevance: Int)] = [:]

        func addKeywords(_ words: [String], scope: String) {
            for word in words {
                let parts = word.split(separator: "|")
                let keyword = String(parts[0])
                let relevance = parts.count > 1 ? Int(parts[1]) ?? 1 : defaultRelevance(keyword)
                let key = caseInsensitive ? keyword.lowercased() : keyword
                compiled[key] = (scope, relevance)
            }
        }

        if let kw = keywords.keyword { addKeywords(kw, scope: "keyword") }
        if let bi = keywords.builtIn { addKeywords(bi, scope: "built_in") }
        if let lit = keywords.literal { addKeywords(lit, scope: "literal") }
        if let typ = keywords.type { addKeywords(typ, scope: "type") }
        for (scope, words) in keywords.custom {
            addKeywords(words, scope: scope)
        }

        let pattern = keywords.pattern?.source ?? #"\w+"#
        guard let patternRe = langRe(pattern, global: true) else {
            return nil
        }

        return CompiledKeywords(pattern: patternRe, keywords: compiled)
    }

    private func defaultRelevance(_ keyword: String) -> Int {
        let commonKeywords = ["of", "and", "for", "in", "not", "or", "if", "then", "parent", "list", "value"]
        return commonKeywords.contains(keyword.lowercased()) ? 0 : 1
    }

    private func buildModeRegex(_ mode: CompiledMode) -> ResumableMultiRegex {
        let mm = ResumableMultiRegex(caseInsensitive: caseInsensitive, unicode: unicode)

        for child in mode.contains {
            if let beginRe = child.beginRe {
                mm.addRule(beginRe.pattern, type: .begin, rule: child)
            }
        }

        if !mode.terminatorEnd.isEmpty {
            mm.addRule(mode.terminatorEnd, type: .end)
        }

        if let illegalRe = mode.illegalRe {
            mm.addRule(illegalRe.pattern, type: .illegal)
        }

        mm.compile()
        return mm
    }
}
