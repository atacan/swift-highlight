import Foundation

public func rustLanguage(_ hljs: Highlight) -> Language {
    let mode_m2 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m3 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m1 = Mode(scope: "comment", begin: HLJS.re("//"), end: HLJS.re("$"), contains: [.mode(mode_m2), .mode(mode_m3)])

    let mode_m5 = Mode(scope: "doctag", begin: HLJS.re("[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)"), end: HLJS.re("(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):"), relevance: 0, excludeBegin: true)

    let mode_m6 = Mode(begin: HLJS.re("[ ]+((?:I|a|is|so|us|to|at|if|in|it|on|[A-Za-z]+['](d|ve|re|ll|t|s|n)|[A-Za-z]+[-][a-z]+|[A-Za-z][a-z]{2,})[.]?[:]?([.][ ]|[ ])){3}"))

    let mode_m4 = Mode(scope: "comment", begin: HLJS.re("/\\*"), end: HLJS.re("\\*/"), contains: [.self, .mode(mode_m5), .mode(mode_m6)])

    let mode_m8 = Mode(begin: HLJS.re("\\\\[\\s\\S]"), relevance: 0)

    let mode_m7 = Mode(scope: "string", begin: HLJS.re("b?\""), end: HLJS.re("\""), contains: [.mode(mode_m8)])

    let mode_m9 = Mode(className: "symbol", begin: HLJS.re("'[a-zA-Z_][a-zA-Z0-9_]*(?!')"))

    let mode_m11 = Mode(begin: HLJS.re("b?r(#*)\"(.|\\n)*?\"\\1(?!#)"))

    let mode_m13 = Mode(scope: "char.escape", match: HLJS.re("\\\\('|\\w|x\\w{2}|u\\w{4}|U\\w{8})"))

    let mode_m12 = Mode(begin: HLJS.re("b?'"), end: HLJS.re("'"), contains: [.mode(mode_m13)])

    let mode_m10 = Mode(scope: "string", variants: HLJS.variants([mode_m11, mode_m12]))

    let mode_m15 = Mode(begin: HLJS.re("\\b0b([01_]+)([ui](8|16|32|64|128|size)|f(32|64))?"))

    let mode_m16 = Mode(begin: HLJS.re("\\b0o([0-7_]+)([ui](8|16|32|64|128|size)|f(32|64))?"))

    let mode_m17 = Mode(begin: HLJS.re("\\b0x([A-Fa-f0-9_]+)([ui](8|16|32|64|128|size)|f(32|64))?"))

    let mode_m18 = Mode(begin: HLJS.re("\\b(\\d[\\d_]*(\\.[0-9_]+)?([eE][+-]?[0-9_]+)?)([ui](8|16|32|64|128|size)|f(32|64))?"))

    let mode_m14 = Mode(className: "number", variants: HLJS.variants([mode_m15, mode_m16, mode_m17, mode_m18]), relevance: 0)

    let mode_m19 = Mode(begin: HLJS.re("(fn)(\\s+)((r#)?[a-zA-Z_]\\w*)"), beginScope: Scope.indexed([1: "keyword", 3: "title.function"]))

    let mode_m21 = Mode(className: "string", begin: HLJS.re("\""), end: HLJS.re("\""), contains: [.mode(mode_m8)])

    let mode_m20 = Mode(className: "meta", begin: HLJS.re("#!?\\["), end: HLJS.re("\\]"), contains: [.mode(mode_m21)])

    let mode_m22 = Mode(begin: HLJS.re("(let)(\\s+)((?:mut\\s+)?)((r#)?[a-zA-Z_]\\w*)"), beginScope: Scope.indexed([1: "keyword", 3: "keyword", 4: "variable"]))

    let mode_m23 = Mode(begin: HLJS.re("(for)(\\s+)((r#)?[a-zA-Z_]\\w*)(\\s+)(in)"), beginScope: Scope.indexed([1: "keyword", 3: "variable", 6: "keyword"]))

    let mode_m24 = Mode(begin: HLJS.re("(type)(\\s+)((r#)?[a-zA-Z_]\\w*)"), beginScope: Scope.indexed([1: "keyword", 3: "title.class"]))

    let mode_m25 = Mode(begin: HLJS.re("((?:trait|enum|struct|union|impl|for))(\\s+)((r#)?[a-zA-Z_]\\w*)"), beginScope: Scope.indexed([1: "keyword", 3: "title.class"]))

    let mode_m26 = Mode(begin: HLJS.re("[a-zA-Z]\\w*::"), keywords: HLJS.kw(keyword: ["Self"], builtIn: ["drop ", "Copy", "Send", "Sized", "Sync", "Drop", "Fn", "FnMut", "FnOnce", "ToOwned", "Clone", "Debug", "PartialEq", "PartialOrd", "Eq", "Ord", "AsRef", "AsMut", "Into", "From", "Default", "Iterator", "Extend", "IntoIterator", "DoubleEndedIterator", "ExactSizeIterator", "SliceConcatExt", "ToString", "assert!", "assert_eq!", "bitflags!", "bytes!", "cfg!", "col!", "concat!", "concat_idents!", "debug_assert!", "debug_assert_eq!", "env!", "eprintln!", "panic!", "file!", "format!", "format_args!", "include_bytes!", "include_str!", "line!", "local_data_key!", "module_path!", "option_env!", "print!", "println!", "select!", "stringify!", "try!", "unimplemented!", "unreachable!", "vec!", "write!", "writeln!", "macro_rules!", "assert_ne!", "debug_assert_ne!"], type: ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "str", "char", "bool", "Box", "Option", "Result", "String", "Vec"]))

    let mode_m27 = Mode(className: "punctuation", begin: HLJS.re("->"))

    let mode_m28 = Mode(className: "title.function.invoke", begin: HLJS.re("\\b(?!let|for|while|if|else|match\\b)(r#)?[a-zA-Z]\\w*(?=\\s*\\()"), relevance: 0)

    return Language(
        name: "Rust",
        aliases: ["rs"],
        keywords: HLJS.kw(pattern: HLJS.re("[a-zA-Z]\\w*!?"), keyword: ["abstract", "as", "async", "await", "become", "box", "break", "const", "continue", "crate", "do", "dyn", "else", "enum", "extern", "false", "final", "fn", "for", "if", "impl", "in", "let", "loop", "macro", "match", "mod", "move", "mut", "override", "priv", "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait", "true", "try", "type", "typeof", "union", "unsafe", "unsized", "use", "virtual", "where", "while", "yield"], literal: ["true", "false", "Some", "None", "Ok", "Err"], builtIn: ["drop ", "Copy", "Send", "Sized", "Sync", "Drop", "Fn", "FnMut", "FnOnce", "ToOwned", "Clone", "Debug", "PartialEq", "PartialOrd", "Eq", "Ord", "AsRef", "AsMut", "Into", "From", "Default", "Iterator", "Extend", "IntoIterator", "DoubleEndedIterator", "ExactSizeIterator", "SliceConcatExt", "ToString", "assert!", "assert_eq!", "bitflags!", "bytes!", "cfg!", "col!", "concat!", "concat_idents!", "debug_assert!", "debug_assert_eq!", "env!", "eprintln!", "panic!", "file!", "format!", "format_args!", "include_bytes!", "include_str!", "line!", "local_data_key!", "module_path!", "option_env!", "print!", "println!", "select!", "stringify!", "try!", "unimplemented!", "unreachable!", "vec!", "write!", "writeln!", "macro_rules!", "assert_ne!", "debug_assert_ne!"], type: ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "str", "char", "bool", "Box", "Option", "Result", "String", "Vec"]),
        illegal: HLJS.re("</"),
        contains: [.mode(mode_m1), .mode(mode_m4), .mode(mode_m7), .mode(mode_m9), .mode(mode_m10), .mode(mode_m14), .mode(mode_m19), .mode(mode_m20), .mode(mode_m22), .mode(mode_m23), .mode(mode_m24), .mode(mode_m25), .mode(mode_m26), .mode(mode_m27), .mode(mode_m28)]
    )
}

public extension Highlight {
    func registerRust() {
        registerLanguage("rust") { hljs in rustLanguage(hljs) }
    }
}
