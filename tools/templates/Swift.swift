import Foundation

/// Swift language definition - comprehensive port from highlight.js
public func swiftLanguage(_ hljs: Highlight) -> Language {
    // MARK: - Keywords

    // Regular keywords
    let keywordList = [
        "actor", "any", "associatedtype", "async", "await", "as", "borrowing",
        "break", "case", "catch", "class", "consume", "consuming", "continue",
        "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed",
        "do", "dynamic", "each", "else", "enum", "extension", "fallthrough",
        "fileprivate", "final", "for", "func", "get", "guard", "if", "import",
        "indirect", "infix", "init", "inout", "internal", "in", "is", "isolated",
        "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open",
        "operator", "optional", "override", "package", "postfix", "precedencegroup",
        "prefix", "private", "protocol", "public", "repeat", "required", "rethrows",
        "return", "self", "set", "some", "static", "struct", "subscript", "super", "switch",
        "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where",
        "while", "willSet", "_|0"
    ]

    // Keywords that start with #
    let numberSignKeywords = [
        "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif",
        "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function",
        "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation",
        "#warning"
    ]

    // Literals
    let literals = ["false", "nil", "true"]

    // Built-in functions (require function call context)
    let builtInList = [
        "abs", "all", "any", "assert", "assertionFailure", "debugPrint", "dump",
        "fatalError", "getVaList", "isKnownUniquelyReferenced", "max", "min",
        "numericCast", "pointwiseMax", "pointwiseMin", "precondition",
        "preconditionFailure", "print", "readLine", "repeatElement", "sequence",
        "stride", "swap", "swift_unboxFromSwiftValueWithType", "transcode", "type",
        "unsafeBitCast", "unsafeDowncast", "withExtendedLifetime",
        "withUnsafeMutablePointer", "withUnsafePointer", "withVaList",
        "withoutActuallyEscaping", "zip"
    ]

    // Availability keywords for @available and #available
    let availabilityKeywordList = [
        "iOS", "iOSApplicationExtension", "macOS", "macOSApplicationExtension",
        "macCatalyst", "macCatalystApplicationExtension", "watchOS",
        "watchOSApplicationExtension", "tvOS", "tvOSApplicationExtension", "swift"
    ]

    // Precedencegroup keywords
    let precedencegroupKeywordList = [
        "assignment", "associativity", "higherThan", "left", "lowerThan", "none", "right"
    ]

    // Built-in attributes (highlighted as keywords)
    let keywordAttributes = [
        "attached", "autoclosure", "discardableResult", "dynamicCallable",
        "dynamicMemberLookup", "escaping", "freestanding", "frozen", "GKInspectable",
        "IBAction", "IBDesignable", "IBInspectable", "IBOutlet", "IBSegueAction",
        "inlinable", "main", "nonobjc", "NSApplicationMain", "NSCopying", "NSManaged",
        "objc", "objcMembers", "propertyWrapper", "requires_stored_property_inits",
        "resultBuilder", "Sendable", "testable", "UIApplicationMain", "unchecked",
        "unknown", "usableFromInline", "warn_unqualified_access"
    ]

    let keywords = Keywords(
        pattern: .string(#"\b\w+|#\w+"#),
        keyword: keywordList + numberSignKeywords,
        literal: literals
    )

    // MARK: - Identifier patterns

    let identifierChar = #"[a-zA-Z_0-9]"#
    let identifier = #"[a-zA-Z_][a-zA-Z_0-9]*"#
    let typeIdentifier = #"[A-Z][a-zA-Z_0-9]*"#

    // Operator characters
    let operatorHead = #"[/=\-+!*%<>&|^~?]"#
    let operatorChar = #"[/=\-+!*%<>&|^~?]"#
    let operatorPattern = operatorHead + operatorChar + "*"

    // MARK: - Comments

    let lineComment = Highlight.cLineCommentMode

    let blockComment = Mode(
        scope: "comment",
        begin: .string(#"/\*"#),
        end: .string(#"\*/"#),
        contains: [.self]  // Swift allows nested block comments
    )

    // MARK: - Numbers

    // Note: Swift allows underscores anywhere in numbers, including trailing underscores
    let decimalDigits = #"([0-9]_*)+"#
    let hexDigits = #"([0-9a-fA-F]_*)+"#

    // Guard mode for invalid number literals (no highlighting)
    // Must come before dotNumber to prevent partial matching
    let invalidNumberGuard = Mode(
        match: .string(#"0[xXoObB]\.[0-9]+([pPeE][+-]?[0-9]+)?"#),
        relevance: 0
    )

    let number = Mode(
        scope: "number",
        variants: [
            // Binary (must come before decimal to avoid matching just the leading 0)
            // Negative lookahead prevents matching when followed by word chars (invalid continuation)
            ModeBox(Mode(match: .string(#"\b0b([01]_*)+(?![\w])"#))),
            // Octal
            // Negative lookahead prevents matching when followed by word chars (invalid continuation)
            ModeBox(Mode(match: .string(#"\b0o([0-7]_*)+(?![\w])"#))),
            // Hexadecimal floating-point (subsumes hex integer)
            // Negative lookahead prevents matching when followed by invalid hex continuation
            ModeBox(Mode(match: .string(#"\b0x(\#(hexDigits))(\.\#(hexDigits))?([pP][+-]?(\#(decimalDigits)))?(?![g-zG-Z])"#))),
            // Decimal floating-point (subsumes decimal integer)
            // Negative lookahead prevents matching 0 followed by radix prefix (b, o, x, B, O, X)
            // Also prevents matching when followed by invalid exponent (e/E not followed by valid digits)
            ModeBox(Mode(match: .string(#"\b(?!0[boxBOX])(\#(decimalDigits))(\.\#(decimalDigits))?([eE][+-]?(\#(decimalDigits)))?(?![eE](?![+-]?[0-9]))"#)))
        ],
        relevance: 0
    )

    // .0 format (decimal after dot, like tuple member access)
    // Match the full .digits pattern with beginScope to only highlight the digits part
    // Negative lookbehind prevents matching after radix prefixes (invalid number literals)
    let dotNumber = Mode(
        match: .string(#"(?<!0x)(?<!0X)(?<!0o)(?<!0O)(?<!0b)(?<!0B)\.([0-9]+)"#),
        beginScope: .indexed([1: "number"])
    )

    // MARK: - Regex Literals (Swift 5.7+)

    let regexContents: [ModeReference] = [
        .mode(Highlight.backslashEscape),
        .mode(Mode(
            begin: .string(#"\["#),
            end: .string(#"\]"#),
            contains: [.mode(Highlight.backslashEscape)],
            relevance: 0
        ))
    ]

    let bareRegex = Mode(
        begin: .string(#"/[^\s](?=[^/\n]*/)"#),
        end: .string("/"),
        contains: regexContents
    )

    func extendedRegex(_ rawDelimiter: String) -> Mode {
        Mode(
            begin: .string(#"\#(rawDelimiter)/"#),
            end: .string(#"/\#(rawDelimiter)"#),
            contains: regexContents + [
                .mode(Mode(
                    scope: "comment",
                    begin: .string(#"#(?!.*/\#(rawDelimiter))"#),
                    end: .string("$")
                ))
            ]
        )
    }

    let regexMode = Mode(
        scope: "regexp",
        variants: [
            ModeBox(extendedRegex("###")),
            ModeBox(extendedRegex("##")),
            ModeBox(extendedRegex("#")),
            ModeBox(bareRegex)
        ]
    )

    // MARK: - Identifiers

    let quotedIdentifier = Mode(
        match: .string(#"`\#(identifier)`"#)
    )

    let implicitParameter = Mode(
        scope: "variable",
        match: .string(#"\$[0-9]+"#)
    )

    let propertyWrapperProjection = Mode(
        scope: "variable",
        match: .string(#"\$\#(identifierChar)+"#)
    )

    // MARK: - Keywords with special patterns

    // .Protocol, .Type (required dot) - match dot separately from keyword
    let dotKeyword = Mode(
        match: .string(#"\.(Protocol|Type)\b"#),
        beginScope: .indexed([1: "keyword"])
    )

    // .init, .self (optional dot) - match dot separately from keyword
    let optionalDotKeyword = Mode(
        match: .string(#"\.(init|self)\b"#),
        beginScope: .indexed([1: "keyword"])
    )

    // Guard against highlighting .keyword as a keyword (e.g., object.class)
    let keywordGuard = Mode(
        match: .string(#"\.("# + keywordList.joined(separator: "|") + #")\b"#),
        relevance: 0
    )

    // as?, as!, try?, try!, init?, init!
    let regexKeyword = Mode(
        scope: "keyword",
        match: .string(#"\b(as|try|init)[?!]"#)
    )

    // private(set), fileprivate(set), internal(set), public(set), open(set)
    let accessSetKeyword = Mode(
        scope: "keyword",
        match: .string(#"\b(private|fileprivate|internal|public|open)\(set\)"#)
    )

    // unowned(safe), unowned(unsafe)
    let unownedKeyword = Mode(
        scope: "keyword",
        match: .string(#"\bunowned\((safe|unsafe)\)"#)
    )

    // Any, Self (keyword types, not regular keywords)
    let keywordTypes = Mode(
        scope: "keyword",
        match: .string(#"\b(Any|Self)\b"#)
    )

    let keywordModes: [ModeReference] = [
        .mode(dotKeyword),
        .mode(keywordGuard),
        .mode(regexKeyword),
        .mode(accessSetKeyword),
        .mode(unownedKeyword),
        .mode(keywordTypes),
        .mode(optionalDotKeyword)
    ]

    // MARK: - Built-ins

    // Guard against .builtIn (e.g., array.min)
    let builtInGuard = Mode(
        match: .string(#"\.("# + builtInList.joined(separator: "|") + #")\b"#),
        relevance: 0
    )

    // Built-in functions (only when followed by parenthesis)
    let builtIn = Mode(
        scope: "built_in",
        match: .string(#"\b("# + builtInList.joined(separator: "|") + #")(?=\()"#)
    )

    let builtIns: [ModeReference] = [
        .mode(builtInGuard),
        .mode(builtIn)
    ]

    // MARK: - Operators

    // Guard against -> being highlighted as operator
    let operatorGuard = Mode(
        match: .string("->"),
        relevance: 0
    )

    let operatorMode = Mode(
        scope: "operator",
        variants: [
            ModeBox(Mode(match: .string(operatorPattern))),
            // Dot operators: .*, ..<, ..., etc.
            ModeBox(Mode(match: .string(#"\.(\.|"# + operatorChar + #")+"#)))
        ],
        relevance: 0
    )

    let operators: [ModeReference] = [
        .mode(operatorGuard),
        .mode(operatorMode)
    ]

    // MARK: - Strings (defined here so interpolation can reference number, operator, etc.)

    /// Creates escaped character mode for strings
    func escapedCharacter(_ rawDelimiter: String = "") -> Mode {
        Mode(
            scope: "subst",
            variants: [
                ModeBox(Mode(match: .string(#"\\\#(rawDelimiter)[0\\tnr"']"#))),
                ModeBox(Mode(match: .string(#"\\\#(rawDelimiter)u\{[0-9a-fA-F]{1,8}\}"#)))
            ]
        )
    }

    /// Creates escaped newline mode for multiline strings
    func escapedNewline(_ rawDelimiter: String = "") -> Mode {
        Mode(
            scope: "subst",
            match: .string(#"\\\#(rawDelimiter)[\t ]*(?:[\r\n]|\r\n)"#)
        )
    }

    /// Creates string interpolation mode with content highlighting
    func interpolation(_ rawDelimiter: String = "") -> Mode {
        // Define submodes that can appear inside interpolation
        let stringInInterpolation = Mode(
            scope: "string",
            variants: [
                ModeBox(Mode(begin: .string("\""), end: .string("\""))),
                ModeBox(Mode(begin: .string("#\""), end: .string("\"#"))),
                ModeBox(Mode(begin: .string("##\""), end: .string("\"##"))),
                ModeBox(Mode(begin: .string("###\""), end: .string("\"###")))
            ]
        )

        let identifierKeywordList = (keywordList + literals).filter {
            $0.range(of: #"^[A-Za-z_][A-Za-z_0-9]*$"#, options: .regularExpression) != nil
        }
        let identifierKeywordAlternation = identifierKeywordList.joined(separator: "|")
        let identifierKeywordExclusion = identifierKeywordAlternation.isEmpty
            ? ""
            : #"(?!\#(identifierKeywordAlternation)\b)"#
        let plainIdentifier = Mode(
            match: .string(#"\b\#(identifierKeywordExclusion)\#(identifier)\b"#),
            relevance: 0
        )

        let submodes: [ModeReference] = keywordModes + builtIns + [
            .mode(number),
            .mode(plainIdentifier)
        ] + operators + [
            .mode(stringInInterpolation),
            .mode(quotedIdentifier),
            .mode(implicitParameter),
            .mode(propertyWrapperProjection)
        ]

        // Nested parentheses mode to prevent premature end while preserving content highlighting
        let nestedParens = Mode(
            begin: .string(#"\("#),
            end: .string(#"\)"#),
            keywords: keywords,
            contains: [.self] + submodes,
            excludeBegin: true,
            excludeEnd: true
        )

        return Mode(
            scope: "subst",
            begin: .string(#"\\\#(rawDelimiter)\("#),
            end: .string(#"\)"#),
            keywords: keywords,
            contains: submodes + [.mode(nestedParens)]
        )
    }

    /// Creates multiline string mode
    func multilineString(_ rawDelimiter: String = "") -> Mode {
        Mode(
            begin: .string(#"\#(rawDelimiter)""""#),
            end: .string(#""""\#(rawDelimiter)"#),
            contains: [
                .mode(escapedCharacter(rawDelimiter)),
                .mode(escapedNewline(rawDelimiter)),
                .mode(interpolation(rawDelimiter))
            ]
        )
    }

    /// Creates single-line string mode
    func singleLineString(_ rawDelimiter: String = "") -> Mode {
        Mode(
            begin: .string(#"\#(rawDelimiter)""#),
            end: .string(#""\#(rawDelimiter)"#),
            contains: [
                .mode(escapedCharacter(rawDelimiter)),
                .mode(interpolation(rawDelimiter))
            ]
        )
    }

    let stringMode = Mode(
        scope: "string",
        variants: [
            ModeBox(multilineString()),
            ModeBox(multilineString("#")),
            ModeBox(multilineString("##")),
            ModeBox(multilineString("###")),
            ModeBox(singleLineString()),
            ModeBox(singleLineString("#")),
            ModeBox(singleLineString("##")),
            ModeBox(singleLineString("###"))
        ]
    )

    // MARK: - Attributes

    // @available, #available, #unavailable
    let availableAttribute = Mode(
        scope: "keyword",
        match: .string(#"(@|#(un)?)available"#),
        starts: ModeBox(Mode(
            contains: [
                .mode(Mode(
                    begin: .string(#"\("#),
                    end: .string(#"\)"#),
                    keywords: Keywords(keyword: availabilityKeywordList),
                    contains: [
                        .mode(operatorGuard),
                        .mode(operatorMode),
                        .mode(number),
                        .mode(stringMode)
                    ]
                ))
            ]
        ))
    )

    // Built-in keyword attributes (e.g., @autoclosure, @escaping)
    let keywordAttribute = Mode(
        scope: "keyword",
        match: .string(#"@("# + keywordAttributes.joined(separator: "|") + #")(?=\(|\s)"#)
    )

    // @objc(...) - includes the parenthesized name
    let objcWithNameAttribute = Mode(
        scope: "keyword",
        match: .string(#"@objc\(\#(identifier)\)"#)
    )

    // @convention(swift|block|c)
    let conventionAttribute = Mode(
        scope: "keyword",
        match: .string(#"@convention\((swift|block|c)\)"#)
    )

    // Plain @objc without parens (handled by keywordAttribute)

    // User-defined attributes
    let userAttribute = Mode(
        scope: "meta",
        match: .string(#"@\#(identifier)"#)
    )

    // MARK: - Types

    // Apple framework types for relevance boost
    let appleFrameworkType = Mode(
        scope: "type",
        match: .string(#"\b(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)\#(identifierChar)+\b"#)
    )

    // Generic type identifier
    let typeIdentifierMode = Mode(
        scope: "type",
        match: .string(#"\b\#(typeIdentifier)"#),
        relevance: 0
    )

    // Optional/implicitly unwrapped optional marker
    let optionalMarker = Mode(
        match: .string(#"[?!]+"#),
        relevance: 0
    )

    // Variadic parameter
    let variadicMarker = Mode(
        match: .string(#"\.\.\."#),
        relevance: 0
    )

    // Protocol composition
    let protocolComposition = Mode(
        match: .string(#"\s+&\s+(?=\#(typeIdentifier))"#),
        relevance: 0
    )

    // Generic arguments <T, U>
    let genericArguments = Mode(
        begin: .string("<"),
        end: .string(#">+"#),
        keywords: keywords,
        contains: [
            .mode(lineComment),
            .mode(blockComment),
            .mode(dotKeyword),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes),
            .mode(availableAttribute),
            .mode(objcWithNameAttribute),
            .mode(conventionAttribute),
            .mode(keywordAttribute),
            .mode(userAttribute),
            .mode(operatorGuard),
            .mode(appleFrameworkType),
            .mode(typeIdentifierMode),
            .mode(optionalMarker),
            .mode(variadicMarker),
            .mode(protocolComposition)
        ]
    )

    // Type mode that includes generic arguments
    let typeMode = Mode(
        match: .string(#"(?=\b[A-Z])"#),
        contains: [
            .mode(appleFrameworkType),
            .mode(typeIdentifierMode),
            .mode(optionalMarker),
            .mode(variadicMarker),
            .mode(protocolComposition),
            .mode(genericArguments)
        ],
        relevance: 0
    )

    // MARK: - Tuples and Function Parameters

    // Tuple element name (prevents highlighting as keyword)
    let tupleElementName = Mode(
        match: .string(#"\#(identifier)\s*:"#),
        keywords: Keywords(keyword: ["_|0"]),
        relevance: 0
    )

    // Generic parameters <T, U>
    let genericParameters = Mode(
        begin: .string("<"),
        end: .string(">"),
        keywords: Keywords(keyword: ["repeat", "each"]),
        contains: [
            .mode(lineComment),
            .mode(blockComment),
            .mode(typeMode)
        ]
    )

    // Function parameter names - match single and external/internal names
    let functionParameterName = Mode(
        begin: .string(#"(?=\#(identifier)\s*:|\#(identifier)\s+\#(identifier)\s*:)"#),
        end: .string(#":"#),
        contains: [
            .mode(Mode(
                scope: "keyword",
                match: .string(#"\b_\b"#)
            )),
            .mode(Mode(
                scope: "params",
                match: .string(identifier)
            ))
        ],
        relevance: 0
    )

    // Tuple mode
    let tuple = Mode(
        begin: .string(#"\("#),
        end: .string(#"\)"#),
        keywords: keywords,
        contains: [
            .mode(tupleElementName),
            .mode(lineComment),
            .mode(blockComment),
            .mode(regexMode),
            .mode(dotKeyword),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes),
            .mode(builtInGuard),
            .mode(builtIn),
            .mode(operatorGuard),
            .mode(dotNumber),
            .mode(operatorMode),
            .mode(number),
            .mode(stringMode),
            .mode(quotedIdentifier),
            .mode(implicitParameter),
            .mode(propertyWrapperProjection),
            .mode(availableAttribute),
            .mode(objcWithNameAttribute),
            .mode(conventionAttribute),
            .mode(keywordAttribute),
            .mode(userAttribute),
            .mode(typeMode)
        ],
        relevance: 0
    )

    // Function parameters (...)
    let functionParameters = Mode(
        begin: .string(#"\("#),
        end: .string(#"\)"#),
        keywords: keywords,
        illegal: .string(#"[\"']"#),
        contains: [
            .mode(functionParameterName),
            .mode(lineComment),
            .mode(blockComment),
            .mode(dotKeyword),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes),
            .mode(operatorGuard),
            .mode(dotNumber),
            .mode(operatorMode),
            .mode(number),
            .mode(stringMode),
            .mode(availableAttribute),
            .mode(objcWithNameAttribute),
            .mode(conventionAttribute),
            .mode(keywordAttribute),
            .mode(userAttribute),
            .mode(typeMode),
            .mode(tuple)
        ],
        endsParent: true
    )

    // MARK: - Declarations

    // func and macro declarations
    let functionOrMacro = Mode(
        begin: .string(#"\b(func|macro)\s+(`\#(identifier)`|\#(identifier)|\#(operatorPattern))"#),
        illegal: .string(#"[\[%]"#),
        contains: [
            .mode(genericParameters),
            .mode(functionParameters)
        ],
        endsWithParent: true,
        beginScope: .indexed([1: "keyword", 2: "title.function"])
    )

    // init, init?, init!, subscript
    let initSubscript = Mode(
        begin: .string(#"\b(subscript|init[?!]?)\s*(?=[<(])"#),
        illegal: .string(#"[\[%]"#),
        contains: [
            .mode(genericParameters),
            .mode(functionParameters)
        ],
        beginScope: .indexed([1: "keyword"])
    )

    // operator declarations
    let operatorDeclaration = Mode(
        begin: .string(#"\b(operator)\s+(\#(operatorPattern))"#),
        beginScope: .indexed([1: "keyword", 2: "title"])
    )

    // precedencegroup declarations
    // Includes appleFrameworkType and typeIdentifierMode for type highlighting after higherThan: and lowerThan:
    let precedencegroupDecl = Mode(
        begin: .string(#"\b(precedencegroup)\s+(\#(typeIdentifier))"#),
        end: .string("}"),
        keywords: Keywords(keyword: precedencegroupKeywordList + literals),
        contains: [
            .mode(Mode(
                scope: "type",
                match: .string(#"\b[A-Z][a-zA-Z0-9_]*\b"#),
                relevance: 0
            ))
        ],
        beginScope: .indexed([1: "keyword", 2: "title"])
    )

    // class func, class var
    let classFuncDeclaration = Mode(
        begin: .string(#"\b(class)\s+(func)\s+([A-Za-z_][A-Za-z0-9_]*)\b"#),
        beginScope: .indexed([1: "keyword", 2: "keyword", 3: "title.function"])
        // No contains - brackets after class func are highlighted as operators at top level
    )

    let classVarDeclaration = Mode(
        begin: .string(#"\b(class)\s+(var)\b"#),
        beginScope: .indexed([1: "keyword", 2: "keyword"])
    )

    // Type declarations: struct, class, enum, protocol, extension, actor
    let inheritanceList = Mode(
        begin: .string(":"),
        end: .string(#"\{"#),
        keywords: keywords,
        contains: [
            .mode(Mode(
                scope: "title.class.inherited",
                match: .string(typeIdentifier)
            )),
            .mode(dotKeyword),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes)
        ],
        relevance: 0
    )

    let typeDeclaration = Mode(
        begin: .string(#"\b(struct|protocol|class|extension|enum|actor)\s+(\#(identifier))\s*"#),
        keywords: keywords,
        contains: [
            .mode(genericParameters),
            .mode(dotKeyword),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes),
            .mode(inheritanceList)
        ],
        beginScope: .indexed([1: "keyword", 2: "title.class"])
    )

    // Import statement
    let importStatement = Mode(
        begin: .string(#"\bimport\b"#),
        end: .string("$"),
        contains: [
            .mode(lineComment),
            .mode(blockComment)
        ],
        relevance: 0
    )

    // MARK: - Language Definition

    return Language(
        name: "Swift",
        keywords: keywords,
        contains: [
            .mode(lineComment),
            .mode(blockComment),
            .mode(functionOrMacro),
            .mode(initSubscript),
            .mode(classFuncDeclaration),
            .mode(classVarDeclaration),
            .mode(typeDeclaration),
            .mode(operatorDeclaration),
            .mode(precedencegroupDecl),
            .mode(importStatement),
            .mode(regexMode),
            .mode(dotKeyword),
            .mode(optionalDotKeyword),
            .mode(invalidNumberGuard),
            .mode(dotNumber),
            .mode(keywordGuard),
            .mode(regexKeyword),
            .mode(accessSetKeyword),
            .mode(unownedKeyword),
            .mode(keywordTypes),
            .mode(builtInGuard),
            .mode(builtIn),
            .mode(operatorGuard),
            .mode(operatorMode),
            .mode(number),
            .mode(stringMode),
            .mode(quotedIdentifier),
            .mode(implicitParameter),
            .mode(propertyWrapperProjection),
            .mode(availableAttribute),
            .mode(objcWithNameAttribute),
            .mode(conventionAttribute),
            .mode(keywordAttribute),
            .mode(userAttribute),
            .mode(typeMode),
            .mode(tuple)
        ]
    )
}

/// Registers Swift with the highlighter
public extension Highlight {
    /// Registers the Swift language
    func registerSwift() {
        registerLanguage("swift") { hljs in swiftLanguage(hljs) }
    }
}
