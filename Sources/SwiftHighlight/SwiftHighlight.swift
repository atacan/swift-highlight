import Foundation

/// Main syntax highlighting engine.
/// Port of highlight.js for Swift.
public final class Highlight: @unchecked Sendable {
    /// Shared instance with default configuration
    public static let shared = Highlight()

    /// Library version
    public static let version = "1.0.0"

    /// Configuration options
    public var options: HighlightOptions

    /// Maximum keyword hits before stopping relevance counting
    private let maxKeywordHits = 7

    /// Registered languages
    private var languages: [String: Language] = [:]

    /// Language aliases
    private var aliases: [String: String] = [:]

    /// Compiled language cache
    private var compiledLanguages: [String: CompiledMode] = [:]

    /// Plaintext language for fallback
    private let plaintextLanguage: Language = {
        let lang = Language(name: "Plain text")
        lang.disableAutodetect = true
        return lang
    }()

    /// Creates a new Highlight instance
    public init(options: HighlightOptions = HighlightOptions()) {
        self.options = options
    }

    /// Creates a new instance of the highlighter
    public static func newInstance() -> Highlight {
        Highlight()
    }

    // MARK: - Public API

    /// Highlights code with a specific language.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - language: The language name to use
    ///   - ignoreIllegals: Whether to ignore illegal syntax (default: true)
    /// - Returns: The highlight result
    public func highlight(
        _ code: String,
        language: String,
        ignoreIllegals: Bool = true
    ) -> HighlightResult {
        do {
            return try _highlight(language: language, code: code, ignoreIllegals: ignoreIllegals)
        } catch {
            // Safe mode: return escaped code
            return HighlightResult(
                language: language,
                value: Utils.escapeHTML(code),
                relevance: 0,
                illegal: false,
                code: code,
                errorRaised: error
            )
        }
    }

    /// Highlights code with automatic language detection.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - languageSubset: Optional subset of languages to consider
    /// - Returns: The auto-highlight result with best and second-best matches
    public func highlightAuto(
        _ code: String,
        languageSubset: [String]? = nil
    ) -> AutoHighlightResult {
        let subset = languageSubset ?? options.languages ?? Array(languages.keys)

        // Start with plaintext
        let plaintext = justTextResult(code)
        var results: [HighlightResult] = [plaintext]

        // Try each language
        for name in subset {
            guard let lang = getLanguage(name),
                  !lang.disableAutodetect else { continue }

            let result = highlight(code, language: name, ignoreIllegals: false)
            if !result.illegal {
                results.append(result)
            }
        }

        // Sort by relevance
        results.sort { a, b in
            if a.relevance != b.relevance {
                return a.relevance > b.relevance
            }
            // Prefer base language over supersets
            if let langA = getLanguage(a.language),
               let langB = getLanguage(b.language) {
                // This would need supersetOf support
            }
            return false
        }

        let best = results[0]
        let secondBest = results.count > 1 ? results[1] : nil

        return AutoHighlightResult(result: best, secondBest: secondBest)
    }

    /// Registers a language definition.
    ///
    /// - Parameters:
    ///   - name: The language name
    ///   - definition: Function that creates the language definition
    public func registerLanguage(_ name: String, definition: @escaping (Highlight) -> Language) {
        let lang: Language
        do {
            lang = definition(self)
        } catch {
            // Use plaintext as fallback
            let fallback = Language(name: name)
            fallback.disableAutodetect = true
            languages[name] = fallback
            return
        }

        if lang.name.isEmpty {
            lang.name = name
        }
        languages[name] = lang
        lang.rawDefinition = definition
        compiledLanguages.removeValue(forKey: name)

        if let langAliases = lang.aliases {
            registerAliases(langAliases, languageName: name)
        }
    }

    /// Removes a registered language.
    public func unregisterLanguage(_ name: String) {
        languages.removeValue(forKey: name)
        compiledLanguages.removeValue(forKey: name)

        // Remove aliases
        for (alias, langName) in aliases where langName == name {
            aliases.removeValue(forKey: alias)
        }
    }

    /// Returns list of registered language names.
    public func listLanguages() -> [String] {
        Array(languages.keys)
    }

    /// Gets a language by name or alias.
    public func getLanguage(_ name: String) -> Language? {
        let lowercased = name.lowercased()
        return languages[lowercased] ?? languages[aliases[lowercased] ?? ""]
    }

    /// Registers aliases for a language.
    public func registerAliases(_ aliasList: [String], languageName: String) {
        for alias in aliasList {
            aliases[alias.lowercased()] = languageName
        }
    }

    /// Checks if a language has auto-detection enabled.
    public func autoDetection(_ name: String) -> Bool {
        guard let lang = getLanguage(name) else { return false }
        return !lang.disableAutodetect
    }

    // MARK: - Private Implementation

    private func justTextResult(_ code: String) -> HighlightResult {
        HighlightResult(
            language: "plaintext",
            value: Utils.escapeHTML(code),
            relevance: 0,
            illegal: false,
            code: code
        )
    }

    private func getCompiledLanguage(_ name: String) throws -> CompiledMode {
        if let cached = compiledLanguages[name] {
            return cached
        }

        guard let lang = getLanguage(name) else {
            throw HighlightError.unknownLanguage(name)
        }

        let compiler = ModeCompiler(language: lang)
        let compiled = compiler.compile()
        compiledLanguages[name] = compiled
        return compiled
    }

    private func _highlight(
        language languageName: String,
        code: String,
        ignoreIllegals: Bool,
        continuation: CompiledMode? = nil
    ) throws -> HighlightResult {
        var keywordHits: [String: Int] = [:]

        let language = try getCompiledLanguage(languageName)
        let emitter = TokenTreeEmitter(options: options)
        var top = continuation ?? language
        var modeBuffer = ""
        var relevance = 0

        // Use UTF-16 based indexing to match NSRegularExpression
        var utf16Index = 0
        let codeUTF16 = code.utf16
        var resumeScanAtSamePosition = false

        // Process continuations - open scopes for modes on the stack
        var current: CompiledMode? = top
        var scopeStack: [String] = []
        while current != nil && current !== language {
            if let scope = current?.scope {
                scopeStack.insert(scope, at: 0)
            }
            current = current?.parent
        }
        for scope in scopeStack {
            emitter.openNode(scope)
        }

        // Main parsing loop
        var iterations = 0

        while utf16Index < codeUTF16.count {
            iterations += 1
            if iterations > 100000 {
                throw HighlightError.infiniteLoop
            }

            if resumeScanAtSamePosition {
                resumeScanAtSamePosition = false
            } else {
                top.matcher?.considerAll()
            }
            top.matcher?.lastIndex = utf16Index

            guard let match = top.matcher?.exec(code) else {
                // No more matches - add remaining text
                let startIndex = String.Index(utf16Offset: utf16Index, in: code)
                if startIndex < code.endIndex {
                    let remaining = String(code[startIndex...])
                    modeBuffer += remaining
                }
                processBuffer(&modeBuffer, emitter: emitter, mode: top, keywordHits: &keywordHits, relevance: &relevance, language: language)
                break
            }

            // Add text before match
            if match.index > utf16Index {
                let startIndex = String.Index(utf16Offset: utf16Index, in: code)
                let endIndex = String.Index(utf16Offset: match.index, in: code)
                if startIndex < endIndex {
                    let beforeMatch = String(code[startIndex..<endIndex])
                    modeBuffer += beforeMatch
                }
            }

            // Process the match
            let lexeme = match[0] ?? ""
            let lexemeUTF16Length = lexeme.utf16.count
            let processedCount: Int

            switch match.type {
            case .begin:
                processedCount = try doBeginMatch(
                    match: match,
                    lexeme: lexeme,
                    emitter: emitter,
                    modeBuffer: &modeBuffer,
                    top: &top,
                    keywordHits: &keywordHits,
                    relevance: &relevance,
                    language: language,
                    resumeScan: &resumeScanAtSamePosition
                )

            case .end:
                let result = try doEndMatch(
                    match: match,
                    lexeme: lexeme,
                    emitter: emitter,
                    modeBuffer: &modeBuffer,
                    top: &top,
                    keywordHits: &keywordHits,
                    relevance: &relevance,
                    language: language,
                    code: code
                )
                if let count = result {
                    processedCount = count
                } else {
                    // No match - add lexeme to buffer
                    modeBuffer += lexeme
                    processedCount = lexemeUTF16Length
                }

            case .illegal:
                if !ignoreIllegals {
                    throw HighlightError.illegalSyntax(lexeme: lexeme, mode: top.scope)
                }
                // Handle illegal match at end of text
                if lexeme.isEmpty && match.index == codeUTF16.count {
                    processedCount = 0
                } else {
                    modeBuffer += lexeme.isEmpty ? "\n" : lexeme
                    processedCount = max(1, lexemeUTF16Length)
                }
            }

            // Advance index
            // processedCount is 0 to not advance (returnBegin/returnEnd), or non-zero to advance past lexeme
            utf16Index = match.index + (processedCount > 0 ? lexemeUTF16Length : 0)
        }

        emitter.finalize()
        let result = emitter.toHTML()

        return HighlightResult(
            language: languageName,
            value: result,
            relevance: relevance,
            illegal: false,
            code: code
        )
    }

    private func processBuffer(
        _ buffer: inout String,
        emitter: TokenTreeEmitter,
        mode: CompiledMode,
        keywordHits: inout [String: Int],
        relevance: inout Int,
        language: CompiledMode
    ) {
        guard !buffer.isEmpty else { return }

        if mode.subLanguage != nil {
            processSubLanguage(buffer, emitter: emitter, mode: mode, relevance: &relevance)
        } else {
            processKeywords(buffer, emitter: emitter, mode: mode, keywordHits: &keywordHits, relevance: &relevance, language: language)
        }
        buffer = ""
    }

    private func processKeywords(
        _ text: String,
        emitter: TokenTreeEmitter,
        mode: CompiledMode,
        keywordHits: inout [String: Int],
        relevance: inout Int,
        language: CompiledMode
    ) {
        guard let keywords = mode.keywords,
              let patternRe = mode.keywordPatternRe else {
            emitter.addText(text)
            return
        }

        var lastIndex = text.startIndex
        let range = NSRange(text.startIndex..., in: text)

        patternRe.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
            guard let result = result else { return }
            let matchRange = Range(result.range, in: text)!

            // Add text before keyword
            if matchRange.lowerBound > lastIndex {
                emitter.addText(String(text[lastIndex..<matchRange.lowerBound]))
            }

            let word = String(text[matchRange])
            let key = language.isCompiled && languages.values.first(where: { $0.caseInsensitive })?.caseInsensitive == true
                ? word.lowercased() : word

            if let (scope, keywordRelevance) = keywords.keywords[key] {
                keywordHits[key, default: 0] += 1
                if keywordHits[key]! <= maxKeywordHits {
                    relevance += keywordRelevance
                }

                if scope.hasPrefix("_") {
                    // Relevance only, no highlighting
                    emitter.addText(word)
                } else {
                    let cssClass = language.scope.flatMap { _ in nil } ?? scope
                    emitter.startScope(cssClass)
                    emitter.addText(word)
                    emitter.endScope()
                }
            } else {
                emitter.addText(word)
            }

            lastIndex = matchRange.upperBound
        }

        // Add remaining text
        if lastIndex < text.endIndex {
            emitter.addText(String(text[lastIndex...]))
        }
    }

    private func processSubLanguage(
        _ text: String,
        emitter: TokenTreeEmitter,
        mode: CompiledMode,
        relevance: inout Int
    ) {
        guard let subLanguage = mode.subLanguage else {
            emitter.addText(text)
            return
        }

        switch subLanguage {
        case .single(let langName):
            guard languages[langName] != nil else {
                emitter.addText(text)
                return
            }
            let result = highlight(text, language: langName, ignoreIllegals: true)
            // Would need to add sublanguage emitter
            emitter.addText(result.value)
            if mode.relevance ?? 0 > 0 {
                relevance += result.relevance
            }

        case .multiple(let subset):
            let result = highlightAuto(text, languageSubset: subset.isEmpty ? nil : subset)
            emitter.addText(result.value)
            if mode.relevance ?? 0 > 0 {
                relevance += result.relevance
            }
        }
    }

    private func doBeginMatch(
        match: EnhancedMatch,
        lexeme: String,
        emitter: TokenTreeEmitter,
        modeBuffer: inout String,
        top: inout CompiledMode,
        keywordHits: inout [String: Int],
        relevance: inout Int,
        language: CompiledMode,
        resumeScan: inout Bool
    ) throws -> Int {
        guard let newMode = match.rule else { return lexeme.count }

        // Check callbacks
        let resp = ModeCallbackResponse()
        if let onBegin = newMode.onBegin {
            onBegin(match.match, resp)
            if resp.isMatchIgnored {
                return doIgnore(lexeme: lexeme, matcher: top.matcher, modeBuffer: &modeBuffer, resumeScan: &resumeScan)
            }
        }

        if newMode.skip {
            modeBuffer += lexeme
        } else {
            if newMode.excludeBegin {
                modeBuffer += lexeme
            }
            processBuffer(&modeBuffer, emitter: emitter, mode: top, keywordHits: &keywordHits, relevance: &relevance, language: language)
            if !newMode.returnBegin && !newMode.excludeBegin {
                modeBuffer = lexeme
            }
        }

        startNewMode(newMode, match: match, emitter: emitter, top: &top, modeBuffer: &modeBuffer, language: language)

        return newMode.returnBegin ? 0 : lexeme.count
    }

    private func startNewMode(
        _ mode: CompiledMode,
        match: EnhancedMatch,
        emitter: TokenTreeEmitter,
        top: inout CompiledMode,
        modeBuffer: inout String,
        language: CompiledMode
    ) {
        if let scope = mode.scope {
            emitter.openNode(scope)
        }

        if let beginScope = mode.beginScope {
            if let wrap = beginScope.wrap {
                emitter.startScope(wrap)
                emitter.addText(modeBuffer)
                emitter.endScope()
                modeBuffer = ""
            } else if beginScope.multi {
                // Multi-class begin scope
                emitMultiClass(scope: beginScope, match: match, emitter: emitter, modeBuffer: &modeBuffer, language: language)
                modeBuffer = ""
            }
        }

        let newTop = CompiledMode()
        // Copy essential properties
        newTop.scope = mode.scope
        newTop.keywords = mode.keywords
        newTop.keywordPatternRe = mode.keywordPatternRe
        newTop.contains = mode.contains
        newTop.matcher = mode.matcher
        newTop.terminatorEnd = mode.terminatorEnd
        newTop.endRe = mode.endRe
        newTop.relevance = mode.relevance
        newTop.excludeEnd = mode.excludeEnd
        newTop.returnEnd = mode.returnEnd
        newTop.endsWithParent = mode.endsWithParent
        newTop.endsParent = mode.endsParent
        newTop.skip = mode.skip
        newTop.subLanguage = mode.subLanguage
        newTop.starts = mode.starts
        newTop.onEnd = mode.onEnd
        newTop.endScope = mode.endScope
        newTop.parent = top

        top = newTop
    }

    private func doEndMatch(
        match: EnhancedMatch,
        lexeme: String,
        emitter: TokenTreeEmitter,
        modeBuffer: inout String,
        top: inout CompiledMode,
        keywordHits: inout [String: Int],
        relevance: inout Int,
        language: CompiledMode,
        code: String
    ) throws -> Int? {
        let matchPlusRemainder = String(code[code.index(code.startIndex, offsetBy: match.index)...])

        guard let endMode = endOfMode(mode: top, match: match, matchPlusRemainder: matchPlusRemainder) else {
            return nil
        }

        let origin = top

        // Check callback
        if let onEnd = origin.onEnd {
            let resp = ModeCallbackResponse()
            onEnd(match.match, resp)
            if resp.isMatchIgnored {
                return nil
            }
        }

        // Handle end scope
        if let endScope = origin.endScope, let wrap = endScope.wrap {
            processBuffer(&modeBuffer, emitter: emitter, mode: origin, keywordHits: &keywordHits, relevance: &relevance, language: language)
            emitter.startScope(wrap)
            emitter.addText(lexeme)
            emitter.endScope()
        } else if let endScope = origin.endScope, endScope.multi {
            processBuffer(&modeBuffer, emitter: emitter, mode: origin, keywordHits: &keywordHits, relevance: &relevance, language: language)
            emitMultiClass(scope: endScope, match: match, emitter: emitter, modeBuffer: &modeBuffer, language: language)
        } else if origin.skip {
            modeBuffer += lexeme
        } else {
            if !origin.returnEnd && !origin.excludeEnd {
                modeBuffer += lexeme
            }
            processBuffer(&modeBuffer, emitter: emitter, mode: origin, keywordHits: &keywordHits, relevance: &relevance, language: language)
            if origin.excludeEnd {
                modeBuffer = lexeme
            }
        }

        // Close modes up to and including endMode
        var current: CompiledMode? = top
        while current !== endMode.parent {
            if current?.scope != nil {
                emitter.closeNode()
            }
            if !(current?.skip ?? false) && current?.subLanguage == nil {
                relevance += current?.relevance ?? 0
            }
            current = current?.parent
            if current == nil { break }
        }
        top = endMode.parent ?? language

        // Handle starts
        if let starts = endMode.starts {
            startNewMode(starts, match: match, emitter: emitter, top: &top, modeBuffer: &modeBuffer, language: language)
        }

        return origin.returnEnd ? 0 : lexeme.count
    }

    private func endOfMode(
        mode: CompiledMode,
        match: EnhancedMatch,
        matchPlusRemainder: String
    ) -> CompiledMode? {
        if let endRe = mode.endRe, Regex.startsWith(endRe, matchPlusRemainder) {
            // This mode ends here
            var current = mode
            while current.endsParent, let parent = current.parent {
                current = parent
            }
            return current
        }

        if mode.endsWithParent, let parent = mode.parent {
            return endOfMode(mode: parent, match: match, matchPlusRemainder: matchPlusRemainder)
        }

        return nil
    }

    private func doIgnore(
        lexeme: String,
        matcher: ResumableMultiRegex?,
        modeBuffer: inout String,
        resumeScan: inout Bool
    ) -> Int {
        if matcher?.regexIndex == 0 {
            modeBuffer += String(lexeme.prefix(1))
            return 1
        } else {
            resumeScan = true
            return 0
        }
    }

    private func emitMultiClass(
        scope: CompiledScope,
        match: EnhancedMatch,
        emitter: TokenTreeEmitter,
        modeBuffer: inout String,
        language: CompiledMode
    ) {
        for i in 1..<match.match.numberOfRanges {
            guard scope.emit[i] == true else { continue }
            let scopeName = scope.scopes[i]
            let text = match[i]

            if let scopeName = scopeName, let text = text {
                emitter.startScope(scopeName)
                emitter.addText(text)
                emitter.endScope()
            } else if let text = text {
                emitter.addText(text)
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during highlighting
public enum HighlightError: Error, LocalizedError {
    case unknownLanguage(String)
    case illegalSyntax(lexeme: String, mode: String?)
    case infiniteLoop

    public var errorDescription: String? {
        switch self {
        case .unknownLanguage(let name):
            return "Unknown language: \(name)"
        case .illegalSyntax(let lexeme, let mode):
            return "Illegal lexeme \"\(lexeme)\" for mode \"\(mode ?? "<unnamed>")\""
        case .infiniteLoop:
            return "Potential infinite loop detected"
        }
    }
}
