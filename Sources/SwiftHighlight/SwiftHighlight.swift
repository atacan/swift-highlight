import Foundation

/// Main syntax highlighting engine.
/// Port of highlight.js for Swift.
public actor Highlight {
    /// Shared instance with default configuration
    public static let shared = Highlight()

    /// Library version
    public nonisolated static let version = "1.0.0"

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
    private let plaintextLanguage = Language(name: "Plain text", disableAutodetect: true)

    /// Creates a new Highlight instance
    public init(options: HighlightOptions = HighlightOptions()) {
        self.options = options
    }

    /// Creates a new instance of the highlighter
    public static func newInstance() -> Highlight {
        Highlight()
    }

    // MARK: - Public API

    /// Parses code and returns the token tree without rendering.
    /// Use this for custom rendering or when you need to render the same code multiple times.
    ///
    /// - Parameters:
    ///   - code: The source code to parse
    ///   - language: The language name to use
    ///   - ignoreIllegals: Whether to ignore illegal syntax (default: true)
    /// - Returns: The parse result with token tree
    public func parse(
        _ code: String,
        language: String,
        ignoreIllegals: Bool = true
    ) -> ParseResult {
        do {
            return try _parse(language: language, code: code, ignoreIllegals: ignoreIllegals)
        } catch {
            // Return empty tree on error
            let emptyTree = TokenTree(root: ScopeNode(), language: language)
            return ParseResult(
                language: language,
                tokenTree: emptyTree,
                relevance: 0,
                illegal: false,
                code: code,
                errorRaised: error
            )
        }
    }

    /// Highlights code using a custom renderer.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - language: The language name to use
    ///   - ignoreIllegals: Whether to ignore illegal syntax (default: true)
    ///   - renderer: The renderer to use for output
    /// - Returns: The highlight result with rendered output
    public func highlight<R: TokenRenderer>(
        _ code: String,
        language: String,
        ignoreIllegals: Bool = true,
        renderer: R
    ) -> HighlightResult<R.Output> {
        let parseResult = parse(code, language: language, ignoreIllegals: ignoreIllegals)
        let output = renderer.render(parseResult.tokenTree)

        return HighlightResult(
            language: parseResult.language,
            value: output,
            relevance: parseResult.relevance,
            illegal: parseResult.illegal,
            code: code,
            tokenTree: parseResult.tokenTree,
            errorRaised: parseResult.errorRaised
        )
    }

    /// Highlights code with a specific language (HTML output).
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - language: The language name to use
    ///   - ignoreIllegals: Whether to ignore illegal syntax (default: true)
    /// - Returns: The highlight result with HTML output
    public func highlight(
        _ code: String,
        language: String,
        ignoreIllegals: Bool = true
    ) -> HighlightResult<String> {
        let htmlRenderer = HTMLRenderer(theme: HTMLTheme(classPrefix: options.classPrefix))
        return highlight(code, language: language, ignoreIllegals: ignoreIllegals, renderer: htmlRenderer)
    }

    /// Highlights code with automatic language detection using a custom renderer.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - languageSubset: Optional subset of languages to consider
    ///   - renderer: The renderer to use for output
    /// - Returns: The auto-highlight result with best and second-best matches
    public func highlightAuto<R: TokenRenderer>(
        _ code: String,
        languageSubset: [String]? = nil,
        renderer: R
    ) -> AutoHighlightResult<R.Output> {
        let subset = languageSubset ?? options.languages ?? Array(languages.keys)

        // Start with plaintext
        let plaintext = justTextResult(code, renderer: renderer)
        var results: [HighlightResult<R.Output>] = [plaintext]

        // Try each language
        for name in subset {
            guard let lang = getLanguage(name),
                  !lang.disableAutodetect else { continue }

            let result = highlight(code, language: name, ignoreIllegals: false, renderer: renderer)
            if !result.illegal {
                results.append(result)
            }
        }

        // Sort by relevance (higher is better)
        results.sort { $0.relevance > $1.relevance }

        let best = results[0]
        let secondBest = results.count > 1 ? results[1] : nil

        return AutoHighlightResult(result: best, secondBest: secondBest)
    }

    /// Highlights code with automatic language detection (HTML output).
    ///
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - languageSubset: Optional subset of languages to consider
    /// - Returns: The auto-highlight result with best and second-best matches
    public func highlightAuto(
        _ code: String,
        languageSubset: [String]? = nil
    ) -> AutoHighlightResult<String> {
        let htmlRenderer = HTMLRenderer(theme: HTMLTheme(classPrefix: options.classPrefix))
        return highlightAuto(code, languageSubset: languageSubset, renderer: htmlRenderer)
    }

    /// Registers a language definition.
    ///
    /// - Parameters:
    ///   - name: The language name
    ///   - definition: Function that creates the language definition
    public func registerLanguage(_ name: String, definition: @Sendable (Highlight) -> Language) {
        let lang = definition(self)
        languages[name] = lang
        compiledLanguages.removeValue(forKey: name)

        if !lang.aliases.isEmpty {
            registerAliases(lang.aliases, languageName: name)
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

    private func justTextResult<R: TokenRenderer>(_ code: String, renderer: R) -> HighlightResult<R.Output> {
        // Create a simple token tree with just the text
        let root = ScopeNode(children: [.text(code)])
        let tree = TokenTree(root: root, language: "plaintext")
        let output = renderer.render(tree)

        return HighlightResult(
            language: "plaintext",
            value: output,
            relevance: 0,
            illegal: false,
            code: code,
            tokenTree: tree
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

    private func _parse(
        language languageName: String,
        code: String,
        ignoreIllegals: Bool,
        continuation: CompiledMode? = nil
    ) throws -> ParseResult {
        var keywordHits: [String: Int] = [:]

        let language = try getCompiledLanguage(languageName)
        let emitter = TokenTreeEmitter(options: options)
        var top = continuation ?? language
        var modeBuffer = ""
        modeBuffer.reserveCapacity(code.count)
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

        // Process any remaining buffer content (e.g., from excludeEnd)
        if !modeBuffer.isEmpty {
            processBuffer(&modeBuffer, emitter: emitter, mode: top, keywordHits: &keywordHits, relevance: &relevance, language: language)
        }

        emitter.finalize()
        let tokenTree = TokenTree(root: emitter.root, language: languageName)

        return ParseResult(
            language: languageName,
            tokenTree: tokenTree,
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

        // Use matches(in:range:) instead of enumerateMatches to avoid closure capture issues
        let matches = patternRe.matches(in: text, options: [], range: range)

        // Use cached case-insensitivity flag from compiled language
        let useCaseInsensitive = language.caseInsensitive

        for result in matches {
            guard let matchRange = Range(result.range, in: text) else { continue }

            // Add text before keyword
            if matchRange.lowerBound > lastIndex {
                emitter.addText(String(text[lastIndex..<matchRange.lowerBound]))
            }

            let word = String(text[matchRange])
            let key = useCaseInsensitive ? word.lowercased() : word

            if let (scope, keywordRelevance) = keywords.keywords[key] {
                let hits = keywordHits[key, default: 0] + 1
                keywordHits[key] = hits
                if hits <= maxKeywordHits {
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
            if mode.relevance > 0 {
                relevance += result.relevance
            }

        case .multiple(let subset):
            let result = highlightAuto(text, languageSubset: subset.isEmpty ? nil : subset)
            emitter.addText(result.value)
            if mode.relevance > 0 {
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
        if let onBegin = newMode.onBegin {
            let result = onBegin(match.match)
            if result == .ignoreMatch {
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

        // Debug: verify parent chain
        // Uncomment to debug: print("  AFTER startNewMode: newTop.scope=\(top.scope ?? "nil") newTop.parent.scope=\(top.parent?.scope ?? "nil")")

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

        // CRITICAL: Set parent to current top BEFORE reassigning top
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
            let result = onEnd(match.match)
            if result == .ignoreMatch {
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
        // Get the full match text and iterate through it, emitting spans for capture groups
        guard let fullText = match[0] else { return }

        // Collect all capture group ranges (relative to fullText start)
        let fullMatchStart = match.match.range.location
        var segments: [(start: Int, end: Int, scope: String?)] = []

        // Find all capture groups that have scopes
        guard let maxScope = scope.scopes.keys.max() else { return }
        for i in 1...maxScope {
            guard scope.emit[i] == true,
                  let scopeName = scope.scopes[i] else { continue }

            // Get the actual range in the combined regex
            let adjustedIndex = match.groupOffset + i
            guard adjustedIndex < match.match.numberOfRanges else { continue }
            let range = match.match.range(at: adjustedIndex)
            guard range.location != NSNotFound else { continue }

            // Convert to offsets relative to fullText
            let relativeStart = range.location - fullMatchStart
            let relativeEnd = relativeStart + range.length
            segments.append((relativeStart, relativeEnd, scopeName))
        }

        // Sort segments by start position
        segments.sort { $0.start < $1.start }

        // Emit text with scopes
        var pos = 0
        for seg in segments {
            // Emit any text before this segment
            if seg.start > pos {
                let startIdx = fullText.index(fullText.startIndex, offsetBy: pos)
                let endIdx = fullText.index(fullText.startIndex, offsetBy: seg.start)
                emitter.addText(String(fullText[startIdx..<endIdx]))
            }

            // Emit the scoped segment
            let startIdx = fullText.index(fullText.startIndex, offsetBy: seg.start)
            let endIdx = fullText.index(fullText.startIndex, offsetBy: seg.end)
            let segText = String(fullText[startIdx..<endIdx])
            if let scopeName = seg.scope {
                emitter.startScope(scopeName)
                emitter.addText(segText)
                emitter.endScope()
            } else {
                emitter.addText(segText)
            }
            pos = seg.end
        }

        // Emit any remaining text after last segment
        if pos < fullText.count {
            let startIdx = fullText.index(fullText.startIndex, offsetBy: pos)
            emitter.addText(String(fullText[startIdx...]))
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
