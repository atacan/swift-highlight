import Foundation

public func swiftLanguage(_ hljs: Highlight) -> Language {
    let mode_m2 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m3 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m1 = Mode(scope: "comment", begin: HLJS.re("//"), end: HLJS.re("$"), contains: [.mode(mode_m2), .mode(mode_m3)])

    let mode_m5 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m6 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m4 = Mode(scope: "comment", begin: HLJS.re("/\\*"), end: HLJS.re("\\*/"), contains: [.self, .mode(mode_m5), .mode(mode_m6)])

    let mode_m10 = Mode(className: "type", match: HLJS.re("(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])+"))

    let mode_m11 = Mode(className: "type", match: HLJS.re("[A-Z](?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*"), relevance: 0)

    let mode_m12 = Mode(match: HLJS.re("[?!]+"), relevance: 0)

    let mode_m13 = Mode(match: HLJS.re("\\.\\.\\."), relevance: 0)

    let mode_m14 = Mode(match: HLJS.re("\\s+&\\s+(?=[A-Z](?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*)"), relevance: 0)

    let mode_m16 = Mode()

    let mode_m17 = Mode(match: HLJS.re("\\.(?:actor|any|associatedtype|async|await|as\\?|as!|as|borrowing|break|case|catch|class|consume|consuming|continue|convenience|copy|default|defer|deinit|didSet|distributed|do|dynamic|each|else|enum|extension|fallthrough|fileprivate\\(set\\)|fileprivate|final|for|func|get|guard|if|import|indirect|infix|init\\?|init!|inout|internal\\(set\\)|internal|in|is|isolated|nonisolated|lazy|let|macro|mutating|nonmutating|open\\(set\\)|open|operator|optional|override|package|postfix|precedencegroup|prefix|private\\(set\\)|private|protocol|public\\(set\\)|public|repeat|required|rethrows|return|set|some|static|struct|subscript|super|switch|throws|throw|try\\?|try!|try|typealias|unowned\\(safe\\)|unowned\\(unsafe\\)|unowned|var|weak|where|while|willSet)"), relevance: 0)

    let mode_m19 = Mode(className: "keyword", match: HLJS.re("(?:\\bas\\?\\B|\\bas!\\B|\\bfileprivate\\(set\\)\\B|\\binit\\?\\B|\\binit!\\B|\\binternal\\(set\\)\\B|\\bopen\\(set\\)\\B|\\bprivate\\(set\\)\\B|\\bpublic\\(set\\)\\B|\\btry\\?\\B|\\btry!\\B|\\bunowned\\(safe\\)\\B|\\bunowned\\(unsafe\\)\\B|\\bAny\\b|\\bSelf\\b|\\binit\\b|\\bself\\b)"))

    let mode_m18 = Mode(variants: HLJS.variants([mode_m19]))

    let mode_m20 = Mode(scope: "keyword", match: HLJS.re("(@|#(un)?)available"))

    let mode_m21 = Mode(scope: "keyword", match: HLJS.re("@(?:attached|autoclosure|convention\\((?:swift|block|c)\\)|discardableResult|dynamicCallable|dynamicMemberLookup|escaping|freestanding|frozen|GKInspectable|IBAction|IBDesignable|IBInspectable|IBOutlet|IBSegueAction|inlinable|main|nonobjc|NSApplicationMain|NSCopying|NSManaged|objc\\((?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*\\)|objc|objcMembers|propertyWrapper|requires_stored_property_inits|resultBuilder|Sendable|testable|UIApplicationMain|unchecked|unknown|usableFromInline|warn_unqualified_access)(?=(?:\\(|\\s+))"))

    let mode_m22 = Mode(scope: "meta", match: HLJS.re("@(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*"))

    let mode_m23 = Mode(match: HLJS.re("->"), relevance: 0)

    let mode_m9 = Mode(match: HLJS.re("(?=\\b[A-Z])"), contains: [.mode(mode_m10), .mode(mode_m11), .mode(mode_m12), .mode(mode_m13), .mode(mode_m14), .mode(mode_m15)], relevance: 0)

    let mode_m15 = Mode(begin: HLJS.re("<"), end: HLJS.re(">"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m20), .mode(mode_m21), .mode(mode_m22), .mode(mode_m23), .mode(mode_m9)])

    let mode_m8 = Mode(begin: HLJS.re("<"), end: HLJS.re(">"), keywords: HLJS.kw(keyword: ["repeat", "each"]), contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m9)])

    let mode_m26 = Mode(className: "keyword", match: HLJS.re("\\b_\\b"))

    let mode_m27 = Mode(className: "params", match: HLJS.re("(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*"))

    let mode_m25 = Mode(begin: HLJS.re("(?:(?=(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*\\s*:)|(?=(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*\\s+(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*\\s*:))"), end: HLJS.re(":"), contains: [.mode(mode_m26), .mode(mode_m27)], relevance: 0)

    let mode_m29 = Mode(match: HLJS.re("(?:[/=\\-+!*%<>&|^~?]|[\\u00A1-\\u00A7]|[\\u00A9\\u00AB]|[\\u00AC\\u00AE]|[\\u00B0\\u00B1]|[\\u00B6\\u00BB\\u00BF\\u00D7\\u00F7]|[\\u2016-\\u2017]|[\\u2020-\\u2027]|[\\u2030-\\u203E]|[\\u2041-\\u2053]|[\\u2055-\\u205E]|[\\u2190-\\u23FF]|[\\u2500-\\u2775]|[\\u2794-\\u2BFF]|[\\u2E00-\\u2E7F]|[\\u3001-\\u3003]|[\\u3008-\\u3020]|[\\u3030])(?:(?:[/=\\-+!*%<>&|^~?]|[\\u00A1-\\u00A7]|[\\u00A9\\u00AB]|[\\u00AC\\u00AE]|[\\u00B0\\u00B1]|[\\u00B6\\u00BB\\u00BF\\u00D7\\u00F7]|[\\u2016-\\u2017]|[\\u2020-\\u2027]|[\\u2030-\\u203E]|[\\u2041-\\u2053]|[\\u2055-\\u205E]|[\\u2190-\\u23FF]|[\\u2500-\\u2775]|[\\u2794-\\u2BFF]|[\\u2E00-\\u2E7F]|[\\u3001-\\u3003]|[\\u3008-\\u3020]|[\\u3030])|[\\u0300-\\u036F]|[\\u1DC0-\\u1DFF]|[\\u20D0-\\u20FF]|[\\uFE00-\\uFE0F]|[\\uFE20-\\uFE2F])*"))

    let mode_m30 = Mode(match: HLJS.re("\\.(\\.|(?:(?:[/=\\-+!*%<>&|^~?]|[\\u00A1-\\u00A7]|[\\u00A9\\u00AB]|[\\u00AC\\u00AE]|[\\u00B0\\u00B1]|[\\u00B6\\u00BB\\u00BF\\u00D7\\u00F7]|[\\u2016-\\u2017]|[\\u2020-\\u2027]|[\\u2030-\\u203E]|[\\u2041-\\u2053]|[\\u2055-\\u205E]|[\\u2190-\\u23FF]|[\\u2500-\\u2775]|[\\u2794-\\u2BFF]|[\\u2E00-\\u2E7F]|[\\u3001-\\u3003]|[\\u3008-\\u3020]|[\\u3030])|[\\u0300-\\u036F]|[\\u1DC0-\\u1DFF]|[\\u20D0-\\u20FF]|[\\uFE00-\\uFE0F]|[\\uFE20-\\uFE2F]))+"))

    let mode_m28 = Mode(className: "operator", variants: HLJS.variants([mode_m29, mode_m30]), relevance: 0)

    let mode_m32 = Mode(match: HLJS.re("\\b(([0-9]_*)+)(\\.(([0-9]_*)+))?([eE][+-]?(([0-9]_*)+))?\\b"))

    let mode_m33 = Mode(match: HLJS.re("\\b0x(([0-9a-fA-F]_*)+)(\\.(([0-9a-fA-F]_*)+))?([pP][+-]?(([0-9]_*)+))?\\b"))

    let mode_m34 = Mode(match: HLJS.re("\\b0o([0-7]_*)+\\b"))

    let mode_m35 = Mode(match: HLJS.re("\\b0b([01]_*)+\\b"))

    let mode_m31 = Mode(className: "number", variants: HLJS.variants([mode_m32, mode_m33, mode_m34, mode_m35]), relevance: 0)

    let mode_m39 = Mode(match: HLJS.re("\\\\[0\\\\tnr\"']"))

    let mode_m40 = Mode(match: HLJS.re("\\\\u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m38 = Mode(className: "subst", variants: HLJS.variants([mode_m39, mode_m40]))

    let mode_m41 = Mode(className: "subst", match: HLJS.re("\\\\[\\t ]*(?:[\\r\\n]|\\r\\n)"))

    let mode_m43 = Mode(match: HLJS.re("\\.(?:abs|all|any|assert|assertionFailure|debugPrint|dump|fatalError|getVaList|isKnownUniquelyReferenced|max|min|numericCast|pointwiseMax|pointwiseMin|precondition|preconditionFailure|print|readLine|repeatElement|sequence|stride|swap|swift_unboxFromSwiftValueWithType|transcode|type|unsafeBitCast|unsafeDowncast|withExtendedLifetime|withUnsafeMutablePointer|withUnsafePointer|withVaList|withoutActuallyEscaping|zip)"), relevance: 0)

    let mode_m44 = Mode(className: "built_in", match: HLJS.re("\\b(?:abs|all|any|assert|assertionFailure|debugPrint|dump|fatalError|getVaList|isKnownUniquelyReferenced|max|min|numericCast|pointwiseMax|pointwiseMin|precondition|preconditionFailure|print|readLine|repeatElement|sequence|stride|swap|swift_unboxFromSwiftValueWithType|transcode|type|unsafeBitCast|unsafeDowncast|withExtendedLifetime|withUnsafeMutablePointer|withUnsafePointer|withVaList|withoutActuallyEscaping|zip)(?=\\()"))

    let mode_m45 = Mode(match: HLJS.re("`(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*`"))

    let mode_m46 = Mode(className: "variable", match: HLJS.re("\\$\\d+"))

    let mode_m47 = Mode(className: "variable", match: HLJS.re("\\$(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])+"))

    let mode_m73 = Mode(match: HLJS.re("\\\\u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m72 = Mode(match: HLJS.re("\\\\[0\\\\tnr\"']"))

    let mode_m71 = Mode(className: "subst", variants: HLJS.variants([mode_m72, mode_m73]))

    let mode_m75 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m74 = Mode(className: "subst", begin: HLJS.re("\\\\\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m75)])

    let mode_m70 = Mode(begin: HLJS.re("\""), end: HLJS.re("\""), contains: [.mode(mode_m71), .mode(mode_m74)])

    let mode_m42 = Mode(className: "subst", begin: HLJS.re("\\\\\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m48)])

    let mode_m37 = Mode(begin: HLJS.re("\"\"\""), end: HLJS.re("\"\"\""), contains: [.mode(mode_m38), .mode(mode_m41), .mode(mode_m42)])

    let mode_m60 = Mode(className: "subst", match: HLJS.re("\\\\##[\\t ]*(?:[\\r\\n]|\\r\\n)"))

    let mode_m58 = Mode(match: HLJS.re("\\\\##[0\\\\tnr\"']"))

    let mode_m59 = Mode(match: HLJS.re("\\\\##u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m57 = Mode(className: "subst", variants: HLJS.variants([mode_m58, mode_m59]))

    let mode_m62 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m61 = Mode(className: "subst", begin: HLJS.re("\\\\##\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m62)])

    let mode_m56 = Mode(begin: HLJS.re("##\"\"\""), end: HLJS.re("\"\"\"##"), contains: [.mode(mode_m57), .mode(mode_m60), .mode(mode_m61)])

    let mode_m91 = Mode(match: HLJS.re("\\\\###u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m90 = Mode(match: HLJS.re("\\\\###[0\\\\tnr\"']"))

    let mode_m89 = Mode(className: "subst", variants: HLJS.variants([mode_m90, mode_m91]))

    let mode_m93 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m92 = Mode(className: "subst", begin: HLJS.re("\\\\###\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m93)])

    let mode_m88 = Mode(begin: HLJS.re("###\""), end: HLJS.re("\"###"), contains: [.mode(mode_m89), .mode(mode_m92)])

    let mode_m53 = Mode(className: "subst", match: HLJS.re("\\\\#[\\t ]*(?:[\\r\\n]|\\r\\n)"))

    let mode_m55 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m54 = Mode(className: "subst", begin: HLJS.re("\\\\#\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m55)])

    let mode_m51 = Mode(match: HLJS.re("\\\\#[0\\\\tnr\"']"))

    let mode_m52 = Mode(match: HLJS.re("\\\\#u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m50 = Mode(className: "subst", variants: HLJS.variants([mode_m51, mode_m52]))

    let mode_m49 = Mode(begin: HLJS.re("#\"\"\""), end: HLJS.re("\"\"\"#"), contains: [.mode(mode_m50), .mode(mode_m53), .mode(mode_m54)])

    let mode_m65 = Mode(match: HLJS.re("\\\\###[0\\\\tnr\"']"))

    let mode_m66 = Mode(match: HLJS.re("\\\\###u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m64 = Mode(className: "subst", variants: HLJS.variants([mode_m65, mode_m66]))

    let mode_m67 = Mode(className: "subst", match: HLJS.re("\\\\###[\\t ]*(?:[\\r\\n]|\\r\\n)"))

    let mode_m69 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m68 = Mode(className: "subst", begin: HLJS.re("\\\\###\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m69)])

    let mode_m63 = Mode(begin: HLJS.re("###\"\"\""), end: HLJS.re("\"\"\"###"), contains: [.mode(mode_m64), .mode(mode_m67), .mode(mode_m68)])

    let mode_m79 = Mode(match: HLJS.re("\\\\#u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m78 = Mode(match: HLJS.re("\\\\#[0\\\\tnr\"']"))

    let mode_m77 = Mode(className: "subst", variants: HLJS.variants([mode_m78, mode_m79]))

    let mode_m81 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m80 = Mode(className: "subst", begin: HLJS.re("\\\\#\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m81)])

    let mode_m76 = Mode(begin: HLJS.re("#\""), end: HLJS.re("\"#"), contains: [.mode(mode_m77), .mode(mode_m80)])

    let mode_m84 = Mode(match: HLJS.re("\\\\##[0\\\\tnr\"']"))

    let mode_m85 = Mode(match: HLJS.re("\\\\##u\\{[0-9a-fA-F]{1,8}\\}"))

    let mode_m83 = Mode(className: "subst", variants: HLJS.variants([mode_m84, mode_m85]))

    let mode_m87 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m86 = Mode(className: "subst", begin: HLJS.re("\\\\##\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m87)])

    let mode_m82 = Mode(begin: HLJS.re("##\""), end: HLJS.re("\"##"), contains: [.mode(mode_m83), .mode(mode_m86)])

    let mode_m36 = Mode(className: "string", variants: HLJS.variants([mode_m37, mode_m49, mode_m56, mode_m63, mode_m70, mode_m76, mode_m82, mode_m88]))

    let mode_m48 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), contains: [.self, .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47)])

    let mode_m95 = Mode(match: HLJS.re("(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])(?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*\\s*:"), keywords: HLJS.kw(keyword: ["_"]), relevance: 0)

    let mode_m98 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m99 = Mode(begin: HLJS.re("\\["), end: HLJS.re("\\]"), contains: [.mode(mode_m98)], relevance: 0)

    let mode_m100 = Mode(scope: "comment", begin: HLJS.re("#(?!.*\\/###)"), end: HLJS.re("$"))

    let mode_m97 = Mode(begin: HLJS.re("###\\/"), end: HLJS.re("\\/###"), contains: [.mode(mode_m98), .mode(mode_m99), .mode(mode_m100)])

    let mode_m102 = Mode(scope: "comment", begin: HLJS.re("#(?!.*\\/##)"), end: HLJS.re("$"))

    let mode_m101 = Mode(begin: HLJS.re("##\\/"), end: HLJS.re("\\/##"), contains: [.mode(mode_m98), .mode(mode_m99), .mode(mode_m102)])

    let mode_m104 = Mode(scope: "comment", begin: HLJS.re("#(?!.*\\/#)"), end: HLJS.re("$"))

    let mode_m103 = Mode(begin: HLJS.re("#\\/"), end: HLJS.re("\\/#"), contains: [.mode(mode_m98), .mode(mode_m99), .mode(mode_m104)])

    let mode_m105 = Mode(begin: HLJS.re("\\/[^\\s](?=[^/\\n]*\\/)"), end: HLJS.re("\\/"), contains: [.mode(mode_m98), .mode(mode_m99)])

    let mode_m96 = Mode(scope: "regexp", variants: HLJS.variants([mode_m97, mode_m101, mode_m103, mode_m105]))

    let mode_m94 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.self, .mode(mode_m95), .mode(mode_m1), .mode(mode_m4), .mode(mode_m96), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m20), .mode(mode_m21), .mode(mode_m22), .mode(mode_m9)], relevance: 0)

    let mode_m24 = Mode(begin: HLJS.re("\\("), end: HLJS.re("\\)"), illegal: HLJS.re("[\"']"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m25), .mode(mode_m1), .mode(mode_m4), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m20), .mode(mode_m21), .mode(mode_m22), .mode(mode_m9), .mode(mode_m94)], endsParent: true)

    let mode_m106 = Mode(match: HLJS.re("\\s+"), relevance: 0)

    let mode_m7 = Mode(contains: [.mode(mode_m8), .mode(mode_m24), .mode(mode_m106)])

    let mode_m107 = Mode(illegal: HLJS.re("\\[|%"), contains: [.mode(mode_m8), .mode(mode_m24), .mode(mode_m106)])

    let mode_m108 = Mode()

    let mode_m109 = Mode()

    let mode_m112 = Mode(scope: "title.class.inherited", match: HLJS.re("[A-Z](?:(?:[a-zA-Z_]|[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]|[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]|[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]|[\\u1E00-\\u1FFF]|[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]|[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]|[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]|[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]|[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]|[\\uFE47-\\uFEFE\\uFF00-\\uFFFD])|\\d|[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F])*"))

    let mode_m111 = Mode(begin: HLJS.re(":"), end: HLJS.re("\\{"), keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m112), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18)], relevance: 0)

    let mode_m110 = Mode(keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), beginScope: Scope.indexed([1: "keyword", 3: "title.class"]), contains: [.mode(mode_m8), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m111)])

    let mode_m113 = Mode()

    let mode_m114 = Mode(end: HLJS.re("}"), keywords: Keywords(), contains: [.mode(mode_m9)])

    let mode_m115 = Mode(end: HLJS.re("$"), contains: [.mode(mode_m1), .mode(mode_m4)], relevance: 0, beginKeywords: "import")

    return Language(
        name: "Swift",
        keywords: HLJS.kw(pattern: HLJS.re("(?:\\b\\w+|#\\w+)"), keyword: ["actor", "any", "associatedtype", "async", "await", "as", "borrowing", "break", "case", "catch", "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit", "didSet", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "indirect", "infix", "inout", "internal", "in", "is", "isolated", "nonisolated", "lazy", "let", "macro", "mutating", "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "set", "some", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "_|0", "#colorLiteral", "#column", "#dsohandle", "#else", "#elseif", "#endif", "#error", "#file", "#fileID", "#fileLiteral", "#filePath", "#function", "#if", "#imageLiteral", "#keyPath", "#line", "#selector", "#sourceLocation", "#warning"], literal: ["false", "nil", "true"]), contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m7), .mode(mode_m107), .mode(mode_m108), .mode(mode_m109), .mode(mode_m110), .mode(mode_m113), .mode(mode_m114), .mode(mode_m115), .mode(mode_m96), .mode(mode_m16), .mode(mode_m17), .mode(mode_m18), .mode(mode_m43), .mode(mode_m44), .mode(mode_m23), .mode(mode_m28), .mode(mode_m31), .mode(mode_m36), .mode(mode_m45), .mode(mode_m46), .mode(mode_m47), .mode(mode_m20), .mode(mode_m21), .mode(mode_m22), .mode(mode_m9), .mode(mode_m94)]
    )
}

public extension Highlight {
    func registerSwift() {
        registerLanguage("swift") { hljs in swiftLanguage(hljs) }
    }
}
