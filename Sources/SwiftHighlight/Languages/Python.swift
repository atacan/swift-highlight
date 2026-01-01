import Foundation

/// Python language definition - comprehensive port from highlight.js
public func pythonLanguage(_ hljs: Highlight) -> Language {
    let reservedWords = [
        "and", "as", "assert", "async", "await", "break", "case", "class",
        "continue", "def", "del", "elif", "else", "except", "finally", "for",
        "from", "global", "if", "import", "in", "is", "lambda", "match",
        "nonlocal|10", "not", "or", "pass", "raise", "return", "try", "while",
        "with", "yield"
    ]

    let builtIns = [
        "__import__", "abs", "all", "any", "ascii", "bin", "bool", "breakpoint",
        "bytearray", "bytes", "callable", "chr", "classmethod", "compile",
        "complex", "delattr", "dict", "dir", "divmod", "enumerate", "eval",
        "exec", "filter", "float", "format", "frozenset", "getattr", "globals",
        "hasattr", "hash", "help", "hex", "id", "input", "int", "isinstance",
        "issubclass", "iter", "len", "list", "locals", "map", "max", "memoryview",
        "min", "next", "object", "oct", "open", "ord", "pow", "print", "property",
        "range", "repr", "reversed", "round", "set", "setattr", "slice", "sorted",
        "staticmethod", "str", "sum", "super", "tuple", "type", "vars", "zip"
    ]

    let literals = [
        "__debug__", "Ellipsis", "False", "None", "NotImplemented", "True"
    ]

    let types = [
        "Any", "Callable", "Coroutine", "Dict", "List", "Literal", "Generic",
        "Optional", "Sequence", "Set", "Tuple", "Type", "Union"
    ]

    let keywords = Keywords(
        pattern: .string("[A-Za-z]\\w+|__\\w+__"),
        keyword: reservedWords,
        builtIn: builtIns,
        literal: literals,
        type: types
    )

    // MARK: - Numbers
    // Python number patterns based on https://docs.python.org/3.9/reference/lexical_analysis.html
    // Using raw strings (#"..."#) for cleaner regex - use \#() for interpolation

    let digitpart = #"[0-9](_?[0-9])*"#

    // Lookahead to avoid matching prefixes
    let lookahead = #"(?=\b|"# + reservedWords.joined(separator: "|") + ")"

    // Exponent float (e.g., 1e10, .5e-3)
    let exponentFloat = Mode(scope: "number")
    exponentFloat.begin = .string(#"(\b(\#(digitpart))|(\b(\#(digitpart)))?\.(\#(digitpart))|\b(\#(digitpart))\.)[eE][+-]?(\#(digitpart))[jJ]?\#(lookahead)"#)
    exponentFloat.relevance = 0

    // Point float (e.g., 3.14, .5, 5.)
    // Pattern: (optional integer part with word boundary).(fractional part)[j]? | (integer part with word boundary).[j]?
    let pointFloat = Mode(scope: "number")
    pointFloat.begin = .string(#"(\b(\#(digitpart)))?\.(\#(digitpart))[jJ]?|\b(\#(digitpart))\.[jJ]?"#)
    pointFloat.relevance = 0

    // Decimal integer with optional long/imaginary suffix
    let decInteger = Mode(scope: "number")
    decInteger.begin = .string(#"\b([1-9](_?[0-9])*|0+(_?0)*)[lLjJ]?\#(lookahead)"#)
    decInteger.relevance = 0

    // Binary integer
    let binInteger = Mode(scope: "number")
    binInteger.begin = .string(#"\b0[bB](_?[01])+[lL]?\#(lookahead)"#)
    binInteger.relevance = 0

    // Octal integer
    let octInteger = Mode(scope: "number")
    octInteger.begin = .string(#"\b0[oO](_?[0-7])+[lL]?\#(lookahead)"#)
    octInteger.relevance = 0

    // Hex integer
    let hexInteger = Mode(scope: "number")
    hexInteger.begin = .string(#"\b0[xX](_?[0-9a-fA-F])+[lL]?\#(lookahead)"#)
    hexInteger.relevance = 0

    // Imaginary number
    let imagNumber = Mode(scope: "number")
    imagNumber.begin = .string(#"\b(\#(digitpart))[jJ]\#(lookahead)"#)
    imagNumber.relevance = 0

    // MARK: - Strings

    // Regular strings with prefixes
    let tripleDoubleString = Mode(scope: "string")
    tripleDoubleString.begin = .string("([uUbBrR]|[bB][rR]|[rR][bB])?\"\"\"")
    tripleDoubleString.end = .string("\"\"\"")
    tripleDoubleString.relevance = 10
    tripleDoubleString.contains = [.mode(Highlight.backslashEscape)]

    let tripleSingleString = Mode(scope: "string")
    tripleSingleString.begin = .string("([uUbBrR]|[bB][rR]|[rR][bB])?'''")
    tripleSingleString.end = .string("'''")
    tripleSingleString.relevance = 10
    tripleSingleString.contains = [.mode(Highlight.backslashEscape)]

    // Prefixed strings use lookbehind to avoid matching inside words like 'or""'
    let prefixedDoubleString = Mode(scope: "string")
    prefixedDoubleString.begin = .string("(?<![a-zA-Z])([uUbBrR]|[bB][rR]|[rR][bB])\"")
    prefixedDoubleString.end = .string("\"")
    prefixedDoubleString.contains = [.mode(Highlight.backslashEscape)]

    let prefixedSingleString = Mode(scope: "string")
    prefixedSingleString.begin = .string("(?<![a-zA-Z])([uUbBrR]|[bB][rR]|[rR][bB])'")
    prefixedSingleString.end = .string("'")
    prefixedSingleString.contains = [.mode(Highlight.backslashEscape)]

    // F-strings with interpolation
    // Note: fStringSubst.contains is set below after all string modes are defined
    let fStringSubst = Mode(scope: "subst")
    fStringSubst.begin = .string(#"\{"#)
    fStringSubst.end = .string(#"\}"#)
    fStringSubst.keywords = keywords

    let literalBracket = Mode()
    literalBracket.begin = .string(#"\{\{"#)
    literalBracket.relevance = 0

    // F-string patterns use lookbehind to avoid matching inside words like 'if"text"'
    let fTripleDoubleString = Mode(scope: "string")
    fTripleDoubleString.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\"\"\"")
    fTripleDoubleString.end = .string("\"\"\"")
    fTripleDoubleString.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]

    let fTripleSingleString = Mode(scope: "string")
    fTripleSingleString.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'''")
    fTripleSingleString.end = .string("'''")
    fTripleSingleString.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]

    let fDoubleString = Mode(scope: "string")
    fDoubleString.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\"")
    fDoubleString.end = .string("\"")
    fDoubleString.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]

    let fSingleString = Mode(scope: "string")
    fSingleString.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'")
    fSingleString.end = .string("'")
    fSingleString.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]

    // Plain strings
    let doubleString = Mode(scope: "string")
    doubleString.begin = .string("\"")
    doubleString.end = .string("\"")
    doubleString.illegal = .string(#"\n"#)
    doubleString.contains = [.mode(Highlight.backslashEscape)]

    let singleString = Mode(scope: "string")
    singleString.begin = .string("'")
    singleString.end = .string("'")
    singleString.illegal = .string(#"\n"#)
    singleString.contains = [.mode(Highlight.backslashEscape)]

    // Now set fStringSubst.contains after all string modes are defined
    fStringSubst.contains = [
        // Numbers - order matters, more specific first
        .mode(exponentFloat),
        .mode(pointFloat),
        .mode(binInteger),
        .mode(octInteger),
        .mode(hexInteger),
        .mode(imagNumber),
        .mode(decInteger),
        // Strings (plain strings for expressions like f"{x + 'text'}")
        .mode(doubleString),
        .mode(singleString)
    ]

    // MARK: - Comments

    let comment = Highlight.hashCommentMode

    // MARK: - Prompt (for REPL)

    let prompt = Mode(scope: "meta")
    prompt.begin = .string(#"^(>>>|\.\.\.) "#)

    // Add prompt to triple-quoted f-strings for REPL continuation
    fTripleDoubleString.contains = [.mode(prompt), .mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]
    fTripleSingleString.contains = [.mode(prompt), .mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]

    // Also add to regular triple-quoted strings
    tripleDoubleString.contains = [.mode(prompt), .mode(Highlight.backslashEscape)]
    tripleSingleString.contains = [.mode(prompt), .mode(Highlight.backslashEscape)]

    // Add prompt to f-string subst for multiline subst expressions
    fStringSubst.contains.insert(.mode(prompt), at: 0)

    // Create separate modes for nested f-strings to avoid circular reference issues
    // These are simpler versions that don't contain the full fStringSubst
    let nestedFSubst = Mode(scope: "subst")
    nestedFSubst.begin = .string(#"\{"#)
    nestedFSubst.end = .string(#"\}"#)
    nestedFSubst.keywords = keywords

    let nestedFDouble = Mode(scope: "string")
    nestedFDouble.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\"")
    nestedFDouble.end = .string("\"")
    nestedFDouble.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(nestedFSubst)]

    let nestedFSingle = Mode(scope: "string")
    nestedFSingle.begin = .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'")
    nestedFSingle.end = .string("'")
    nestedFSingle.contains = [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(nestedFSubst)]

    // Add nested f-strings to subst for patterns like f"{name + f'{name}'}"
    fStringSubst.contains.append(.mode(nestedFDouble))
    fStringSubst.contains.append(.mode(nestedFSingle))

    // MARK: - self variable

    let selfVar = Mode(scope: "variable.language")
    selfVar.match = .string("\\bself\\b")

    // MARK: - Function definition
    // Using beginScope to highlight the function name directly

    let funcParams = Mode(scope: "params")
    funcParams.begin = .string("\\(")
    funcParams.end = .string("\\)")
    funcParams.excludeBegin = true
    funcParams.excludeEnd = true
    funcParams.keywords = keywords
    funcParams.contains = [
        .mode(decInteger),
        .mode(pointFloat),
        .mode(doubleString),
        .mode(singleString),
        .mode(comment)
    ]

    // Match: def <title.function>(params) -> ReturnType:
    // Use Unicode letter classes for Python 3 PEP 3131 compliance
    let funcDef = Mode()
    funcDef.begin = .string("\\b(def)\\s+([\\p{L}_][\\p{L}\\p{N}_]*)")
    funcDef.beginScope = .indexed([1: "keyword", 2: "title.function"])
    funcDef.end = .string(":")
    funcDef.returnEnd = true
    funcDef.keywords = keywords  // For return type annotations like -> None
    funcDef.contains = [.mode(funcParams)]

    // MARK: - Class definition
    // Using beginScope to highlight class name

    // Class inheritance - match identifier only when followed by delimiter (not . or ()
    // Use positive lookahead for safe delimiters: , ) : or whitespace
    let classInherit = Mode(scope: "title.class.inherited")
    classInherit.match = .string("[\\p{L}_][\\p{L}\\p{N}_]*(?=\\s*[,):])")

    let classParams = Mode()
    classParams.begin = .string("\\(")
    classParams.end = .string("\\)")
    classParams.excludeBegin = true
    classParams.excludeEnd = true
    classParams.keywords = keywords
    classParams.contains = [
        .mode(classInherit),
        .mode(doubleString),
        .mode(singleString),
        .mode(comment)
    ]

    // Match: class <title.class>(inherited):
    // Use Unicode letter classes for Python 3 PEP 3131 compliance
    let classDef = Mode()
    classDef.begin = .string("\\b(class)\\s+([\\p{L}_][\\p{L}\\p{N}_]*)")
    classDef.beginScope = .indexed([1: "keyword", 2: "title.class"])
    classDef.end = .string(":")
    classDef.returnEnd = true
    classDef.contains = [.mode(classParams)]

    // MARK: - Decorator

    // Decorator params
    let decoratorParams = Mode(scope: "params")
    decoratorParams.begin = .string("\\(")
    decoratorParams.end = .string("\\)")
    decoratorParams.excludeBegin = true
    decoratorParams.excludeEnd = true
    decoratorParams.keywords = keywords
    decoratorParams.contains = [
        // Numbers - order matters, more specific first
        .mode(exponentFloat),
        .mode(pointFloat),
        .mode(decInteger),
        .mode(doubleString),
        .mode(singleString)
    ]

    let decorator = Mode(scope: "meta")
    decorator.begin = .string("^[\\t ]*@")
    decorator.end = .string("(?=#)|$")
    decorator.contains = [
        // Numbers - order matters, more specific first
        .mode(exponentFloat),
        .mode(pointFloat),
        .mode(decInteger),
        .mode(doubleString),
        .mode(singleString),
        .mode(decoratorParams)
    ]

    // MARK: - Language definition

    let lang = Language(name: "Python")
    lang.aliases = ["py", "gyp", "ipython"]
    lang.unicodeRegex = true
    lang.keywords = keywords
    lang.illegal = .string("(<\\/|\\?)|=>")
    lang.contains = [
        .mode(prompt),
        // Numbers - order matters, more specific first
        .mode(exponentFloat),
        .mode(pointFloat),
        .mode(binInteger),
        .mode(octInteger),
        .mode(hexInteger),
        .mode(imagNumber),
        .mode(decInteger),
        // self
        .mode(selfVar),
        // Strings - order matters, longer prefixes first
        .mode(fTripleDoubleString),
        .mode(fTripleSingleString),
        .mode(tripleDoubleString),
        .mode(tripleSingleString),
        .mode(fDoubleString),
        .mode(fSingleString),
        .mode(prefixedDoubleString),
        .mode(prefixedSingleString),
        .mode(doubleString),
        .mode(singleString),
        // Comments
        .mode(comment),
        // Definitions
        .mode(funcDef),
        .mode(classDef),
        .mode(decorator)
    ]

    return lang
}


/// Registers Python with the highlighter
public extension Highlight {
    /// Registers the Python language
    func registerPython() {
        registerLanguage("python", definition: pythonLanguage)
    }
}
