import Foundation

/// Python language definition with more complete features
/// Ported from highlight.js
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

    let keywords = Keywords(
        pattern: .string("[A-Za-z]\\w+|__\\w+__"),
        keyword: reservedWords,
        builtIn: builtIns,
        literal: literals
    )

    // Simple string modes
    let singleQuoteString = Mode(scope: "string", begin: .string("'"), end: .string("'"))
    singleQuoteString.contains = [.mode(Highlight.backslashEscape)]

    let doubleQuoteString = Mode(scope: "string", begin: .string("\""), end: .string("\""))
    doubleQuoteString.contains = [.mode(Highlight.backslashEscape)]

    // Triple quoted strings (docstrings)
    let tripleDoubleString = Mode(scope: "string", begin: .string("\"\"\""), end: .string("\"\"\""), relevance: 10)
    let tripleSingleString = Mode(scope: "string", begin: .string("'''"), end: .string("'''"), relevance: 10)

    // Number mode
    let number = Mode(scope: "number", begin: .string("\\b\\d+(\\.\\d+)?\\b"), relevance: 0)

    // Comment
    let comment = Highlight.hashCommentMode

    // f-string with expression interpolation
    let fStringInterpolation = Mode(scope: "subst", begin: .string("\\{"), end: .string("\\}"))
    fStringInterpolation.keywords = keywords
    // Use .self to allow nested expressions (e.g., f"{func(x)}")
    fStringInterpolation.contains = [
        .mode(number),
        .self  // Allow nested f-string expressions
    ]

    let fStringSingle = Mode(scope: "string", begin: .string("f'"), end: .string("'"))
    fStringSingle.contains = [.mode(Highlight.backslashEscape), .mode(fStringInterpolation)]

    let fStringDouble = Mode(scope: "string", begin: .string("f\""), end: .string("\""))
    fStringDouble.contains = [.mode(Highlight.backslashEscape), .mode(fStringInterpolation)]

    // Function definition
    let funcDef = Mode(scope: "function", beginKeywords: "def")
    funcDef.end = .string(":")
    funcDef.contains = [
        .mode(Mode(scope: "title", begin: .string("\\b[a-zA-Z_]\\w*"), relevance: 0))
    ]

    // Class definition
    let classDef = Mode(scope: "class", beginKeywords: "class")
    classDef.end = .string(":")
    classDef.contains = [
        .mode(Mode(scope: "title", begin: .string("\\b[a-zA-Z_]\\w*"), relevance: 0))
    ]

    // Decorator
    let decorator = Mode(scope: "meta", begin: .string("@\\w+"))
    decorator.relevance = 10

    let lang = Language(name: "Python")
    lang.aliases = ["py", "gyp", "ipython"]
    lang.keywords = keywords
    lang.contains = [
        .mode(tripleDoubleString),
        .mode(tripleSingleString),
        .mode(fStringSingle),
        .mode(fStringDouble),
        .mode(singleQuoteString),
        .mode(doubleQuoteString),
        .mode(number),
        .mode(comment),
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
