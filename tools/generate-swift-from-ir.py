#!/usr/bin/env python3
import argparse
import json
import os
import re
from pathlib import Path


SPECIAL_CASES = {
    "json": "JSON"
}

TEMPLATE_OVERRIDES = {
    "python": "Python.swift",
    "swift": "Swift.swift",
}


def swift_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f"\"{escaped}\""


def normalize_raw_keywords(raw: str) -> list[str]:
    tokens = []
    for token in raw.split():
        token = re.sub(r"\|\d+$", "", token)
        if token:
            tokens.append(token)
    return tokens


def sanitize_regex_source(source: str) -> str:
    out = []
    in_class = False
    i = 0
    while i < len(source):
        ch = source[i]
        if ch == "\\":
            out.append(ch)
            if i + 1 < len(source):
                out.append(source[i + 1])
                i += 2
                continue
        if ch == "[":
            if in_class:
                out.append("\\[")
            else:
                in_class = True
                out.append(ch)
            i += 1
            continue
        if ch == "]" and in_class:
            in_class = False
        out.append(ch)
        i += 1
    return "".join(out)


def pattern_expr(pattern: dict | None) -> str | None:
    if not pattern:
        return None
    source = sanitize_regex_source(pattern["source"])
    flags = pattern.get("flags", "")
    if "i" in flags:
        source = "(?i)" + source
    return f"HLJS.re({swift_string(source)})"


def keywords_expr(keywords: dict | None) -> str | None:
    if not keywords:
        return None

    keyword = list(keywords.get("keyword") or [])
    literal = list(keywords.get("literal") or [])
    built_in = list(keywords.get("built_in") or [])
    type_words = list(keywords.get("type") or [])
    custom = keywords.get("custom") or {}
    raw = keywords.get("raw")
    if raw:
        keyword.extend(normalize_raw_keywords(raw))

    def array_expr(items: list[str]) -> str | None:
        if not items:
            return None
        joined = ", ".join(swift_string(item) for item in items)
        return f"[{joined}]"

    parts = []
    if keyword:
        parts.append(f"keyword: {array_expr(keyword)}")
    if literal:
        parts.append(f"literal: {array_expr(literal)}")
    if built_in:
        parts.append(f"builtIn: {array_expr(built_in)}")
    if type_words:
        parts.append(f"type: {array_expr(type_words)}")

    if isinstance(custom, dict):
        items = []
        for key, words in sorted(custom.items(), key=lambda kv: kv[0]):
            if not words:
                continue
            item = f"{swift_string(key)}: {array_expr(list(words))}"
            items.append(item)
        if items:
            parts.append(f"custom: [{', '.join(items)}]")

    pattern = keywords.get("pattern")
    pattern_value = pattern_expr(pattern)
    if pattern_value:
        parts.insert(0, f"pattern: {pattern_value}")

    if not parts:
        return "Keywords()"

    return f"HLJS.kw({', '.join(parts)})"


def scope_expr(scope) -> str | None:
    if scope is None:
        return None
    if isinstance(scope, str):
        return f"Scope.simple({swift_string(scope)})"
    if isinstance(scope, dict):
        items = ", ".join(f"{k}: {swift_string(v)}" for k, v in sorted(scope.items(), key=lambda kv: int(kv[0])))
        return f"Scope.indexed([{items}])"
    return None


def sublanguage_expr(value) -> str | None:
    if not value:
        return None
    if isinstance(value, str):
        return f"SubLanguage.single({swift_string(value)})"
    if isinstance(value, list):
        joined = ", ".join(swift_string(v) for v in value)
        return f"SubLanguage.multiple([{joined}])"
    return None


def dict_expr(value) -> str | None:
    if not value or not isinstance(value, dict):
        return None
    items = ", ".join(
        f"{swift_string(k)}: {swift_string(v)}"
        for k, v in sorted(value.items(), key=lambda kv: kv[0])
    )
    return f"[{items}]"


def mode_expr(mode, mode_refs, *, shallow=False) -> str:
    values = {}

    scope = mode.get("scope")
    if isinstance(scope, str) and scope:
        values["scope"] = swift_string(scope)
    class_name = mode.get("className")
    if isinstance(class_name, str) and class_name:
        values["className"] = swift_string(class_name)

    values["begin"] = pattern_expr(mode.get("begin"))
    values["end"] = pattern_expr(mode.get("end"))
    values["match"] = pattern_expr(mode.get("match"))
    keywords = keywords_expr(mode.get("keywords"))
    begin_keywords = mode.get("beginKeywords")
    if not keywords and begin_keywords and (scope == "literal" or class_name == "literal"):
        tokens = normalize_raw_keywords(begin_keywords)
        if tokens:
            joined = ", ".join(swift_string(token) for token in tokens)
            keywords = f"HLJS.kw(keyword: [{joined}])"
    values["keywords"] = keywords
    values["illegal"] = pattern_expr(mode.get("illegal"))

    if not shallow:
        values["contains"] = mode_refs.get("contains")
        values["starts"] = mode_refs.get("starts")
    values["variants"] = mode_refs.get("variants")

    relevance = mode.get("relevance")
    if isinstance(relevance, int) and not isinstance(relevance, bool):
        values["relevance"] = str(relevance)

    for key in (
        "excludeBegin",
        "excludeEnd",
        "returnBegin",
        "returnEnd",
        "endsWithParent",
        "endsParent",
        "skip",
    ):
        if mode.get(key) is True:
            values[key] = "true"

    values["subLanguage"] = sublanguage_expr(mode.get("subLanguage"))
    values["beginScope"] = scope_expr(mode.get("beginScope"))
    values["endScope"] = scope_expr(mode.get("endScope"))

    if begin_keywords:
        values["beginKeywords"] = swift_string(begin_keywords)

    ordered_keys = [
        "scope",
        "className",
        "begin",
        "end",
        "match",
        "keywords",
        "illegal",
        "contains",
        "variants",
        "relevance",
        "excludeBegin",
        "excludeEnd",
        "returnBegin",
        "returnEnd",
        "endsWithParent",
        "endsParent",
        "skip",
        "subLanguage",
        "beginScope",
        "endScope",
        "starts",
        "onBegin",
        "onEnd",
        "beginKeywords",
    ]

    args = []
    for key in ordered_keys:
        value = values.get(key)
        if value is None:
            continue
        args.append(f"{key}: {value}")

    return f"Mode({', '.join(args)})"


def build_edges(modes):
    edges = {}
    for mode in modes:
        mid = mode["id"]
        edges[mid] = []
        for idx, ref in enumerate(mode.get("contains") or []):
            if ref == "self":
                continue
            if isinstance(ref, dict) and ref.get("ref"):
                if ref["ref"] == mid:
                    continue
                edges[mid].append(("contains", idx, ref["ref"]))
        for idx, ref in enumerate(mode.get("variants") or []):
            if isinstance(ref, dict) and ref.get("ref"):
                if ref["ref"] == mid:
                    continue
                edges[mid].append(("variants", idx, ref["ref"]))
        starts = mode.get("starts")
        if isinstance(starts, dict) and starts.get("ref"):
            if starts["ref"] != mid:
                edges[mid].append(("starts", 0, starts["ref"]))
    return edges


def tarjan_scc(nodes, edges):
    index = 0
    stack = []
    on_stack = set()
    indices = {}
    lowlinks = {}
    sccs = []

    def strongconnect(node):
        nonlocal index
        indices[node] = index
        lowlinks[node] = index
        index += 1
        stack.append(node)
        on_stack.add(node)

        for _, _, target in edges.get(node, []):
            if target not in indices:
                strongconnect(target)
                lowlinks[node] = min(lowlinks[node], lowlinks[target])
            elif target in on_stack:
                lowlinks[node] = min(lowlinks[node], indices[target])

        if lowlinks[node] == indices[node]:
            scc = []
            while True:
                w = stack.pop()
                on_stack.remove(w)
                scc.append(w)
                if w == node:
                    break
            sccs.append(scc)

    for node in nodes:
        if node not in indices:
            strongconnect(node)

    return sccs


def mode_rank(mode):
    scope = mode.get("scope") or mode.get("className")
    if scope == "string":
        return 0
    if scope == "subst":
        return 2
    return 1


def find_break_edges(edges, mode_order, mode_by_id):
    order_index = {mid: idx for idx, mid in enumerate(mode_order)}
    ranks = {mid: mode_rank(mode_by_id[mid]) for mid in mode_by_id}
    sccs = tarjan_scc(mode_order, edges)
    scc_map = {mid: set(scc) for scc in sccs for mid in scc}
    break_edges = set()

    for scc in sccs:
        if len(scc) <= 1:
            continue
        ordered = sorted(scc, key=lambda mid: (ranks.get(mid, 1), order_index.get(mid, 0)))
        scc_index = {mid: idx for idx, mid in enumerate(ordered)}

        for src in scc:
            for kind, idx, target in edges.get(src, []):
                if target not in scc_index:
                    continue
                if scc_index[src] > scc_index[target]:
                    break_edges.add((src, kind, idx))

    return break_edges, scc_map


def toposort_modes(modes, edges, break_edges):
    mode_ids = [m["id"] for m in modes]
    order_index = {mid: idx for idx, mid in enumerate(mode_ids)}
    dependents = {mid: set() for mid in mode_ids}
    indegree = {mid: 0 for mid in mode_ids}

    for src in mode_ids:
        for kind, idx, target in edges.get(src, []):
            if (src, kind, idx) in break_edges:
                continue
            if target not in indegree:
                continue
            dependents[target].add(src)
            indegree[src] += 1

    queue = [mid for mid in mode_ids if indegree[mid] == 0]
    queue.sort(key=lambda m: order_index[m])
    ordered = []

    while queue:
        mid = queue.pop(0)
        ordered.append(mid)
        for dep in sorted(dependents[mid], key=lambda m: order_index[m]):
            indegree[dep] -= 1
            if indegree[dep] == 0:
                queue.append(dep)
                queue.sort(key=lambda m: order_index[m])

    if len(ordered) != len(mode_ids):
        ordered = mode_ids

    id_to_mode = {m["id"]: m for m in modes}
    return [id_to_mode[mid] for mid in ordered if mid in id_to_mode]


def generate_language(ir, lang_id):
    language = ir["language"]
    mode_list = ir.get("modes", [])
    mode_by_id = {mode["id"]: mode for mode in mode_list}
    edges = build_edges(mode_list)
    mode_order = [mode["id"] for mode in mode_list]
    break_edges, scc_map = find_break_edges(edges, mode_order, mode_by_id)
    modes = toposort_modes(mode_list, edges, break_edges)

    lines = []
    lines.append("import Foundation")
    lines.append("")
    lines.append(f"public func {lang_id}Language(_ hljs: Highlight) -> Language {{")

    mode_names = {}
    for mode in modes:
        mode_names[mode["id"]] = f"mode_{mode['id']}"

    def pruned_expr(mode_id: str, blocked_set: set, stack=None) -> str:
        if stack is None:
            stack = set()
        if mode_id in stack:
            target = mode_by_id[mode_id]
            return mode_expr(target, {}, shallow=True)

        stack.add(mode_id)
        target = mode_by_id[mode_id]

        contains = []
        for ref in (target.get("contains") or []):
            if ref == "self":
                contains.append(".self")
            elif isinstance(ref, dict):
                ref_id = ref["ref"]
                if ref_id == mode_id:
                    contains.append(".self")
                else:
                    contains.append(f".mode({pruned_expr(ref_id, blocked_set, stack)})")

        variants = []
        for ref in (target.get("variants") or []):
            if isinstance(ref, dict):
                ref_id = ref["ref"]
                variants.append(pruned_expr(ref_id, blocked_set, stack))

        mode_refs = {}
        if contains:
            mode_refs["contains"] = "[" + ", ".join(contains) + "]"
        if variants:
            mode_refs["variants"] = f"HLJS.variants([{', '.join(variants)}])"

        starts = target.get("starts")
        if isinstance(starts, dict) and starts.get("ref"):
            ref_id = starts["ref"]
            mode_refs["starts"] = f"ModeBox({pruned_expr(ref_id, blocked_set, stack)})"

        expr = mode_expr(target, mode_refs, shallow=False)
        stack.remove(mode_id)
        return expr

    for mode in modes:
        mode_id = mode["id"]
        contains = []
        for idx, ref in enumerate(mode.get("contains") or []):
            if ref == "self":
                contains.append(".self")
            elif isinstance(ref, dict):
                ref_id = ref["ref"]
                if ref_id == mode_id:
                    contains.append(".self")
                elif (mode_id, "contains", idx) in break_edges:
                    blocked = scc_map.get(mode_id, set())
                    contains.append(f".mode({pruned_expr(ref_id, blocked)})")
                else:
                    contains.append(f".mode({mode_names[ref_id]})")
        variants = []
        for idx, ref in enumerate(mode.get("variants") or []):
            if isinstance(ref, dict):
                ref_id = ref["ref"]
                if (mode_id, "variants", idx) in break_edges:
                    blocked = scc_map.get(mode_id, set())
                    variants.append(pruned_expr(ref_id, blocked))
                else:
                    variants.append(mode_names[ref_id])

        mode_refs = {}
        if contains:
            mode_refs["contains"] = "[" + ", ".join(contains) + "]"
        if variants:
            mode_refs["variants"] = f"HLJS.variants([{', '.join(variants)}])"

        starts = mode.get("starts")
        if isinstance(starts, dict) and starts.get("ref"):
            ref_id = starts["ref"]
            if ref_id == mode_id or (mode_id, "starts", 0) in break_edges:
                blocked = scc_map.get(mode_id, set())
                mode_refs["starts"] = f"ModeBox({pruned_expr(ref_id, blocked)})"
            else:
                mode_refs["starts"] = f"ModeBox({mode_names[ref_id]})"

        expr = mode_expr(mode, mode_refs)
        lines.append(f"    let {mode_names[mode['id']]} = {expr}")
        lines.append("")

    lang_contains = []
    for ref in (language.get("contains") or []):
        if ref == "self":
            lang_contains.append(".self")
        elif isinstance(ref, dict):
            lang_contains.append(f".mode({mode_names[ref['ref']]})")

    lang_args = []
    lang_args.append(f"name: {swift_string(language.get('name') or lang_id)}")

    aliases = language.get("aliases") or []
    if aliases:
        joined = ", ".join(swift_string(alias) for alias in aliases)
        lang_args.append(f"aliases: [{joined}]")

    if language.get("disableAutodetect"):
        lang_args.append("disableAutodetect: true")
    if language.get("caseInsensitive"):
        lang_args.append("caseInsensitive: true")
    if language.get("unicodeRegex"):
        lang_args.append("unicodeRegex: true")

    lang_keywords = keywords_expr(language.get("keywords"))
    if lang_keywords:
        lang_args.append(f"keywords: {lang_keywords}")

    lang_illegal = pattern_expr(language.get("illegal"))
    if lang_illegal:
        lang_args.append(f"illegal: {lang_illegal}")

    if lang_contains:
        lang_args.append(f"contains: [{', '.join(lang_contains)}]")

    class_name_aliases = dict_expr(language.get("classNameAliases"))
    if class_name_aliases:
        lang_args.append(f"classNameAliases: {class_name_aliases}")

    lines.append("    return Language(")
    for idx, arg in enumerate(lang_args):
        suffix = "," if idx < len(lang_args) - 1 else ""
        lines.append(f"        {arg}{suffix}")
    lines.append("    )")
    lines.append("}")
    lines.append("")
    lines.append("public extension Highlight {")
    reg_name = SPECIAL_CASES.get(lang_id, lang_id[:1].upper() + lang_id[1:])
    lines.append(f"    func register{reg_name}() {{")
    lines.append(f"        registerLanguage({swift_string(lang_id)}) {{ hljs in {lang_id}Language(hljs) }}")
    lines.append("    }")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", required=True, help="language id, e.g. swift")
    parser.add_argument("--input", help="path to IR json")
    parser.add_argument("--output", help="path to output swift file")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    input_path = Path(args.input) if args.input else repo_root / "tools" / "ir" / f"{args.lang}.json"
    file_base = SPECIAL_CASES.get(args.lang, args.lang.capitalize())
    output_path = Path(args.output) if args.output else repo_root / "Sources" / "SwiftHighlight" / "Languages" / f"{file_base}.swift"

    override = TEMPLATE_OVERRIDES.get(args.lang)
    if override:
        template_path = repo_root / "tools" / "templates" / override
        output_path.write_text(template_path.read_text(encoding="utf-8"), encoding="utf-8")
        return

    with open(input_path, "r", encoding="utf-8") as f:
        ir = json.load(f)

    swift = generate_language(ir, args.lang)
    output_path.write_text(swift, encoding="utf-8")


if __name__ == "__main__":
    main()
