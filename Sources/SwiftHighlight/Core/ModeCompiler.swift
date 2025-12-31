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
    weak var parent: CompiledMode?

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

    var isCompiled = false

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

    /// Track modes currently being compiled to detect cycles
    private var compilingModes: Set<ObjectIdentifier> = []

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
        let mode = Mode()
        mode.scope = nil
        mode.keywords = lang.keywords
        mode.illegal = lang.illegal
        mode.contains = lang.contains
        return mode
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
            let cmode = CompiledMode()
            cmode.isCompiled = true
            return cmode
        }

        // Check if already compiled (reuse cached result)
        if mode.isCompiled, let cached = mode.cachedCompiledMode {
            return cached
        }

        // Detect cycles - if we're already compiling this exact mode instance, return a placeholder
        let modeId = ObjectIdentifier(mode)
        if compilingModes.contains(modeId) {
            let cmode = CompiledMode()
            cmode.isCompiled = true
            return cmode
        }

        // Mark as being compiled
        compilingModes.insert(modeId)
        defer { compilingModes.remove(modeId) }

        let cmode = CompiledMode()

        // Cache early so .self references can find it
        mode.cachedCompiledMode = cmode

        if mode.scope != nil || mode.className != nil {
            cmode.scope = mode.scope ?? mode.className
        }

        // Handle match -> begin conversion
        if let match = mode.match {
            mode.begin = match
        }

        // Handle beginKeywords
        if let beginKeywords = mode.beginKeywords {
            let words = beginKeywords.split(separator: " ").map { String($0) }
            let pattern = "\\b(" + words.joined(separator: "|") + ")\\b"
            mode.begin = .string(pattern)
        }

        // Compile begin/end patterns
        if parent != nil {
            if mode.begin == nil {
                mode.begin = .string(#"\B|\b"#)
            }
            cmode.beginRe = langRe(mode.begin)

            if mode.end == nil && !mode.endsWithParent {
                mode.end = .string(#"\B|\b"#)
            }
            if let end = mode.end {
                cmode.endRe = langRe(end)
            }

            cmode.terminatorEnd = mode.end?.source ?? ""
            if mode.endsWithParent, let parentEnd = parent?.terminatorEnd {
                cmode.terminatorEnd += (mode.end != nil ? "|" : "") + parentEnd
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
            for variant in variants {
                let merged = mergeMode(mode, variant)
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
        if let starts = mode.starts {
            cmode.starts = compileMode(starts, parent: parent, depth: depth + 1, selfMode: effectiveSelfMode)
        }

        // Build matcher
        cmode.matcher = buildModeRegex(cmode)

        cmode.isCompiled = true
        mode.isCompiled = true
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
                let selfCopy = Mode()
                selfCopy.scope = selfMode.scope
                selfCopy.className = selfMode.className
                selfCopy.begin = selfMode.begin
                selfCopy.end = selfMode.end
                selfCopy.match = selfMode.match
                selfCopy.keywords = selfMode.keywords
                selfCopy.illegal = selfMode.illegal
                // Important: do NOT copy contains - leave empty to prevent recursion
                // The actual content will be inherited from parent context
                selfCopy.relevance = selfMode.relevance
                selfCopy.excludeBegin = selfMode.excludeBegin
                selfCopy.excludeEnd = selfMode.excludeEnd
                selfCopy.returnBegin = selfMode.returnBegin
                selfCopy.returnEnd = selfMode.returnEnd
                selfCopy.endsWithParent = true  // .self references should end with parent
                selfCopy.endsParent = selfMode.endsParent
                selfCopy.skip = selfMode.skip
                selfCopy.subLanguage = selfMode.subLanguage
                selfCopy.beginScope = selfMode.beginScope
                selfCopy.endScope = selfMode.endScope
                selfCopy.onBegin = selfMode.onBegin
                selfCopy.onEnd = selfMode.onEnd
                selfCopy.beginKeywords = selfMode.beginKeywords
                result.append(selfCopy)
            case .mode(let m):
                if let variants = m.variants {
                    for variant in variants {
                        result.append(mergeMode(m, variant))
                    }
                } else {
                    result.append(m)
                }
            }
        }
        return result
    }

    private func mergeMode(_ base: Mode, _ override: Mode) -> Mode {
        let merged = base.copy()
        if let scope = override.scope { merged.scope = scope }
        if let begin = override.begin { merged.begin = begin }
        if let end = override.end { merged.end = end }
        if let keywords = override.keywords { merged.keywords = keywords }
        if let relevance = override.relevance { merged.relevance = relevance }
        merged.excludeBegin = override.excludeBegin || base.excludeBegin
        merged.excludeEnd = override.excludeEnd || base.excludeEnd
        merged.returnBegin = override.returnBegin || base.returnBegin
        merged.returnEnd = override.returnEnd || base.returnEnd
        merged.endsWithParent = override.endsWithParent || base.endsWithParent
        merged.endsParent = override.endsParent || base.endsParent
        merged.skip = override.skip || base.skip
        if !override.contains.isEmpty { merged.contains = override.contains }
        return merged
    }

    private func compileKeywords(_ keywords: Keywords) -> CompiledKeywords {
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
        let patternRe = langRe(pattern, global: true)!

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
