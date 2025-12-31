import Foundation

/// Type of match found
internal enum MatchType {
    case begin
    case end
    case illegal
}

/// Enhanced match result with metadata
internal struct EnhancedMatch {
    let match: NSTextCheckingResult
    let text: String
    let type: MatchType
    let rule: CompiledMode?
    let position: Int

    var range: NSRange { match.range }
    var index: Int { match.range.location }

    subscript(_ index: Int) -> String? {
        let range = match.range(at: index)
        guard range.location != NSNotFound else { return nil }
        let start = text.index(text.startIndex, offsetBy: range.location)
        let end = text.index(start, offsetBy: range.length)
        return String(text[start..<end])
    }
}

/// A multi-pattern regex matcher
/// Combines multiple patterns into one large alternation and tracks which one matched
internal final class MultiRegex {
    private var matchIndexes: [Int: (MatchType, CompiledMode?, Int)] = [:]
    private var regexes: [(pattern: String, type: MatchType, rule: CompiledMode?)] = []
    private var matchAt = 1
    private var position = 0

    private var matcherRe: NSRegularExpression?
    var lastIndex = 0

    private let caseInsensitive: Bool
    private let unicode: Bool

    init(caseInsensitive: Bool = false, unicode: Bool = false) {
        self.caseInsensitive = caseInsensitive
        self.unicode = unicode
    }

    func addRule(_ pattern: String, type: MatchType, rule: CompiledMode? = nil) {
        let pos = position
        position += 1
        matchIndexes[matchAt] = (type, rule, pos)
        regexes.append((pattern, type, rule))
        matchAt += Regex.countMatchGroups(pattern) + 1
    }

    func compile() {
        guard !regexes.isEmpty else {
            matcherRe = nil
            return
        }

        let patterns = regexes.map { $0.pattern }
        let combined = Regex.rewriteBackreferences(patterns, joinWith: "|")

        var options: NSRegularExpression.Options = [.anchorsMatchLines]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }

        matcherRe = try? NSRegularExpression(pattern: combined, options: options)
    }

    func exec(_ string: String) -> EnhancedMatch? {
        guard let regex = matcherRe else { return nil }

        let searchRange = NSRange(location: lastIndex, length: string.utf16.count - lastIndex)
        guard let match = regex.firstMatch(in: string, options: [], range: searchRange) else {
            return nil
        }

        // Find which group matched
        var matchedIndex: Int?
        for i in 1..<match.numberOfRanges {
            if match.range(at: i).location != NSNotFound {
                matchedIndex = i
                break
            }
        }

        guard let idx = matchedIndex,
              let (type, rule, pos) = matchIndexes[idx] else {
            return nil
        }

        return EnhancedMatch(
            match: match,
            text: string,
            type: type,
            rule: rule,
            position: pos
        )
    }
}

/// A resumable multi-regex that can skip previously matched patterns
internal final class ResumableMultiRegex {
    private var rules: [(pattern: String, type: MatchType, rule: CompiledMode?)] = []
    private var multiRegexes: [Int: MultiRegex] = [:]
    private var count = 0

    var lastIndex = 0
    var regexIndex = 0

    private let caseInsensitive: Bool
    private let unicode: Bool

    init(caseInsensitive: Bool = false, unicode: Bool = false) {
        self.caseInsensitive = caseInsensitive
        self.unicode = unicode
    }

    func addRule(_ pattern: String, type: MatchType, rule: CompiledMode? = nil) {
        rules.append((pattern, type, rule))
        if type == .begin {
            count += 1
        }
    }

    func compile() {
        // Pre-compile the first matcher
        _ = getMatcher(0)
    }

    private func getMatcher(_ index: Int) -> MultiRegex {
        if let existing = multiRegexes[index] {
            return existing
        }

        let matcher = MultiRegex(caseInsensitive: caseInsensitive, unicode: unicode)
        for (pattern, type, rule) in rules.dropFirst(index) {
            matcher.addRule(pattern, type: type, rule: rule)
        }
        matcher.compile()
        multiRegexes[index] = matcher
        return matcher
    }

    func resumingScanAtSamePosition() -> Bool {
        regexIndex != 0
    }

    func considerAll() {
        regexIndex = 0
    }

    func exec(_ string: String) -> EnhancedMatch? {
        let m = getMatcher(regexIndex)
        m.lastIndex = lastIndex
        var result = m.exec(string)

        // If resuming and we got a match at the same position, it's valid
        // Otherwise, try the full matcher from the next position
        if resumingScanAtSamePosition() {
            if result != nil && result!.index == lastIndex {
                // Valid resume match
            } else {
                // Try full matcher from lastIndex + 1
                let m2 = getMatcher(0)
                m2.lastIndex = lastIndex + 1
                result = m2.exec(string)
            }
        }

        if let result = result {
            regexIndex += result.position + 1
            if regexIndex == count {
                considerAll()
            }
        }

        return result
    }
}
