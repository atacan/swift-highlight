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
    let digitpart = #"[0-9](_?[0-9])*"#
    let lookahead = #"(?=\b|"# + reservedWords.joined(separator: "|") + ")"

    let exponentFloat = Mode(
        scope: "number",
        begin: .string(#"(\b(\#(digitpart))|(\b(\#(digitpart)))?\.(\#(digitpart))|\b(\#(digitpart))\.)[eE][+-]?(\#(digitpart))[jJ]?\#(lookahead)"#),
        relevance: 0
    )

    let pointFloat = Mode(
        scope: "number",
        begin: .string(#"(\b(\#(digitpart)))?\.(\#(digitpart))[jJ]?|\b(\#(digitpart))\.[jJ]?"#),
        relevance: 0
    )

    let decInteger = Mode(
        scope: "number",
        begin: .string(#"\b([1-9](_?[0-9])*|0+(_?0)*)[lLjJ]?\#(lookahead)"#),
        relevance: 0
    )

    let binInteger = Mode(
        scope: "number",
        begin: .string(#"\b0[bB](_?[01])+[lL]?\#(lookahead)"#),
        relevance: 0
    )

    let octInteger = Mode(
        scope: "number",
        begin: .string(#"\b0[oO](_?[0-7])+[lL]?\#(lookahead)"#),
        relevance: 0
    )

    let hexInteger = Mode(
        scope: "number",
        begin: .string(#"\b0[xX](_?[0-9a-fA-F])+[lL]?\#(lookahead)"#),
        relevance: 0
    )

    let imagNumber = Mode(
        scope: "number",
        begin: .string(#"\b(\#(digitpart))[jJ]\#(lookahead)"#),
        relevance: 0
    )

    // MARK: - Strings

    let doubleString = Mode(
        scope: "string",
        begin: .string("\""),
        end: .string("\""),
        illegal: .string(#"\n"#),
        contains: [.mode(Highlight.backslashEscape)]
    )

    let singleString = Mode(
        scope: "string",
        begin: .string("'"),
        end: .string("'"),
        illegal: .string(#"\n"#),
        contains: [.mode(Highlight.backslashEscape)]
    )

    let prompt = Mode(
        scope: "meta",
        begin: .string(#"^(>>>|\.\.\.) "#)
    )

    let literalBracket = Mode(
        begin: .string(#"\{\{"#),
        relevance: 0
    )

    // Nested f-string substitution (simplified to avoid circular references)
    let nestedFSubst = Mode(
        scope: "subst",
        begin: .string(#"\{"#),
        end: .string(#"\}"#),
        keywords: keywords
    )

    let nestedFDouble = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\""),
        end: .string("\""),
        contains: [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(nestedFSubst)]
    )

    let nestedFSingle = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'"),
        end: .string("'"),
        contains: [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(nestedFSubst)]
    )

    // F-string substitution with full contains
    let fStringSubst = Mode(
        scope: "subst",
        begin: .string(#"\{"#),
        end: .string(#"\}"#),
        keywords: keywords,
        contains: [
            .mode(prompt),
            .mode(exponentFloat),
            .mode(pointFloat),
            .mode(binInteger),
            .mode(octInteger),
            .mode(hexInteger),
            .mode(imagNumber),
            .mode(decInteger),
            .mode(doubleString),
            .mode(singleString),
            .mode(nestedFDouble),
            .mode(nestedFSingle)
        ]
    )

    // F-string patterns
    let fTripleDoubleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\"\"\""),
        end: .string("\"\"\""),
        contains: [.mode(prompt), .mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]
    )

    let fTripleSingleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'''"),
        end: .string("'''"),
        contains: [.mode(prompt), .mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]
    )

    let fDoubleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])\""),
        end: .string("\""),
        contains: [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]
    )

    let fSingleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([fF][rR]|[rR][fF]|[fF])'"),
        end: .string("'"),
        contains: [.mode(Highlight.backslashEscape), .mode(literalBracket), .mode(fStringSubst)]
    )

    // Regular strings with prefixes
    let tripleDoubleString = Mode(
        scope: "string",
        begin: .string("([uUbBrR]|[bB][rR]|[rR][bB])?\"\"\""),
        end: .string("\"\"\""),
        contains: [.mode(prompt), .mode(Highlight.backslashEscape)],
        relevance: 10
    )

    let tripleSingleString = Mode(
        scope: "string",
        begin: .string("([uUbBrR]|[bB][rR]|[rR][bB])?'''"),
        end: .string("'''"),
        contains: [.mode(prompt), .mode(Highlight.backslashEscape)],
        relevance: 10
    )

    let prefixedDoubleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([uUbBrR]|[bB][rR]|[rR][bB])\""),
        end: .string("\""),
        contains: [.mode(Highlight.backslashEscape)]
    )

    let prefixedSingleString = Mode(
        scope: "string",
        begin: .string("(?<![a-zA-Z])([uUbBrR]|[bB][rR]|[rR][bB])'"),
        end: .string("'"),
        contains: [.mode(Highlight.backslashEscape)]
    )

    // MARK: - Comments
    let comment = Highlight.hashCommentMode

    // MARK: - self variable
    let selfVar = Mode(
        scope: "variable.language",
        match: .string("\\bself\\b")
    )

    // MARK: - Function definition
    let funcParams = Mode(
        scope: "params",
        begin: .string("\\("),
        end: .string("\\)"),
        keywords: keywords,
        contains: [
            .mode(decInteger),
            .mode(pointFloat),
            .mode(doubleString),
            .mode(singleString),
            .mode(comment)
        ],
        excludeBegin: true,
        excludeEnd: true
    )

    let funcDef = Mode(
        begin: .string("\\b(def)\\s+([\\p{L}_][\\p{L}\\p{N}_]*)"),
        end: .string(":"),
        keywords: keywords,
        contains: [.mode(funcParams)],
        returnEnd: true,
        beginScope: .indexed([1: "keyword", 2: "title.function"])
    )

    // MARK: - Class definition
    let classInherit = Mode(
        scope: "title.class.inherited",
        match: .string("[\\p{L}_][\\p{L}\\p{N}_]*(?=\\s*[,):])")
    )

    let classParams = Mode(
        begin: .string("\\("),
        end: .string("\\)"),
        keywords: keywords,
        contains: [
            .mode(classInherit),
            .mode(doubleString),
            .mode(singleString),
            .mode(comment)
        ],
        excludeBegin: true,
        excludeEnd: true
    )

    let classDef = Mode(
        begin: .string("\\b(class)\\s+([\\p{L}_][\\p{L}\\p{N}_]*)"),
        end: .string(":"),
        contains: [.mode(classParams)],
        returnEnd: true,
        beginScope: .indexed([1: "keyword", 2: "title.class"])
    )

    // MARK: - Decorator
    let decoratorParams = Mode(
        scope: "params",
        begin: .string("\\("),
        end: .string("\\)"),
        keywords: keywords,
        contains: [
            .mode(exponentFloat),
            .mode(pointFloat),
            .mode(decInteger),
            .mode(doubleString),
            .mode(singleString)
        ],
        excludeBegin: true,
        excludeEnd: true
    )

    let decorator = Mode(
        scope: "meta",
        begin: .string("^[\\t ]*@"),
        end: .string("(?=#)|$"),
        contains: [
            .mode(exponentFloat),
            .mode(pointFloat),
            .mode(decInteger),
            .mode(doubleString),
            .mode(singleString),
            .mode(decoratorParams)
        ]
    )

    // MARK: - Language definition
    return Language(
        name: "Python",
        aliases: ["py", "gyp", "ipython"],
        unicodeRegex: true,
        keywords: keywords,
        illegal: .string("(<\\/|\\?)|=>"),
        contains: [
            .mode(prompt),
            .mode(exponentFloat),
            .mode(pointFloat),
            .mode(binInteger),
            .mode(octInteger),
            .mode(hexInteger),
            .mode(imagNumber),
            .mode(decInteger),
            .mode(selfVar),
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
            .mode(comment),
            .mode(funcDef),
            .mode(classDef),
            .mode(decorator)
        ]
    )
}

/// Registers Python with the highlighter
public extension Highlight {
    /// Registers the Python language
    func registerPython() {
        registerLanguage("python") { hljs in pythonLanguage(hljs) }
    }
}
