# Highlight.js IR schema (draft)

## Purpose
Provide a stable, language-agnostic JSON representation of highlight.js modes for code generation and parity checks.

## Top-level
```
{
  "version": 1,
  "language": {
    "name": "Swift",
    "aliases": ["swift"],
    "disableAutodetect": false,
    "caseInsensitive": false,
    "unicodeRegex": false,
    "keywords": { ... },
    "illegal": { "type": "regex", "source": "...", "flags": "" },
    "classNameAliases": { "built_in": "builtin" },
    "contains": [ { "ref": "m1" }, { "ref": "m2" }, "self" ]
  },
  "modes": [
    { "id": "m1", ... },
    { "id": "m2", ... }
  ]
}
```

## Mode object
```
{
  "id": "m1",
  "scope": "string",
  "className": null,
  "begin": { "type": "regex", "source": "\"", "flags": "" },
  "end": { "type": "regex", "source": "\"", "flags": "" },
  "match": null,
  "beginScope": "keyword" | { "1": "keyword", "2": "title.function" },
  "endScope": "string" | { ... },
  "contains": [ { "ref": "m3" }, "self" ],
  "variants": [ { "ref": "m4" }, { "ref": "m5" } ],
  "starts": { "ref": "m6" } | null,
  "keywords": { ... },
  "illegal": { "type": "regex", "source": "...", "flags": "" },
  "relevance": 0,
  "excludeBegin": false,
  "excludeEnd": false,
  "returnBegin": false,
  "returnEnd": false,
  "endsWithParent": false,
  "endsParent": false,
  "skip": false,
  "subLanguage": null | "swift" | ["xml", "css"],
  "beginKeywords": null | "import"
}
```

### Pattern object
```
{ "type": "regex", "source": "\\bfoo\\b", "flags": "i" }
{ "type": "string", "source": "\\bfoo\\b" }
```

### Keywords object
```
{
  "pattern": { "type": "regex", "source": "\\b\\w+\\b", "flags": "" },
  "keyword": ["if", "else"],
  "literal": ["true", "false"],
  "built_in": ["print"],
  "type": ["String"],
  "custom": { "section": ["upstream", "location"] },
  "raw": null
}
```

If highlight.js provides keywords as a string, the extractor stores:
```
{
  "pattern": null,
  "keyword": [],
  "literal": [],
  "built_in": [],
  "type": [],
  "custom": {},
  "raw": "if else true|0"
}
```
The generator should split `raw` on whitespace and strip `|<number>` suffixes.

## Reference representation
`contains` and `variants` are lists of:
- `{ "ref": "<mode-id>" }` for another mode
- `"self"` for a self-reference

## Notes
- `begin`, `end`, `match`, `illegal` follow the same pattern object schema.
- `beginScope`/`endScope` can be a string (single scope) or a dictionary of capture index to scope.
- `caseInsensitive` is preserved per-language (global in highlight.js).
- `className` is kept for legacy modes but `scope` is preferred.
