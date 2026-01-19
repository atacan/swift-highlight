#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


ALLOWED_PATTERN_TYPES = {"regex", "string"}
ALLOWED_FLAGS = {"i", "u"}


def validate_pattern(pattern, path, errors):
    if pattern is None:
        return
    if not isinstance(pattern, dict):
        errors.append(f"{path}: pattern is not an object")
        return
    ptype = pattern.get("type")
    if ptype not in ALLOWED_PATTERN_TYPES:
        errors.append(f"{path}: unsupported pattern type '{ptype}'")
    flags = pattern.get("flags", "")
    for flag in flags:
        if flag not in ALLOWED_FLAGS:
            errors.append(f"{path}: unsupported regex flag '{flag}'")


def validate_mode(mode, mode_ids, errors):
    mid = mode.get("id", "<unknown>")
    for key in ("begin", "end", "match", "illegal"):
        validate_pattern(mode.get(key), f"mode {mid}.{key}", errors)

    for key in ("contains", "variants"):
        refs = mode.get(key) or []
        if not isinstance(refs, list):
            errors.append(f"mode {mid}.{key}: not a list")
            continue
        for ref in refs:
            if ref == "self":
                continue
            if not isinstance(ref, dict) or "ref" not in ref:
                errors.append(f"mode {mid}.{key}: invalid ref '{ref}'")
                continue
            if ref["ref"] not in mode_ids:
                errors.append(f"mode {mid}.{key}: unknown ref '{ref['ref']}'")

    starts = mode.get("starts")
    if starts is not None:
        if not isinstance(starts, dict) or "ref" not in starts:
            errors.append(f"mode {mid}.starts: invalid ref '{starts}'")
        elif starts["ref"] not in mode_ids:
            errors.append(f"mode {mid}.starts: unknown ref '{starts['ref']}'")


def validate_ir(path: Path) -> list[str]:
    errors = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [f"{path}: failed to parse JSON: {exc}"]

    if data.get("version") != 1:
        errors.append(f"{path}: unsupported IR version '{data.get('version')}'")

    language = data.get("language")
    if not isinstance(language, dict):
        errors.append(f"{path}: missing language object")
        return errors

    for key in ("contains",):
        refs = language.get(key) or []
        if not isinstance(refs, list):
            errors.append(f"{path}: language.{key} is not a list")

    for key in ("keywords",):
        kw = language.get(key)
        if kw and not isinstance(kw, dict):
            errors.append(f"{path}: language.{key} is not an object")

    validate_pattern(language.get("illegal"), f"{path}: language.illegal", errors)

    modes = data.get("modes") or []
    if not isinstance(modes, list):
        errors.append(f"{path}: modes is not a list")
        return errors

    mode_ids = set()
    for mode in modes:
        if not isinstance(mode, dict):
            errors.append(f"{path}: mode entry is not an object")
            continue
        mid = mode.get("id")
        if not mid:
            errors.append(f"{path}: mode missing id")
        else:
            if mid in mode_ids:
                errors.append(f"{path}: duplicate mode id '{mid}'")
            mode_ids.add(mid)

    for mode in modes:
        if isinstance(mode, dict):
            validate_mode(mode, mode_ids, errors)

    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="IR json file to validate")
    parser.add_argument("--dir", help="Directory of IR json files")
    args = parser.parse_args()

    if not args.input and not args.dir:
        print("Usage: tools/validate-ir.py --input <file> | --dir <dir>")
        sys.exit(1)

    paths = []
    if args.input:
        paths.append(Path(args.input))
    if args.dir:
        dir_path = Path(args.dir)
        paths.extend(sorted(dir_path.glob("*.json")))

    all_errors = []
    for path in paths:
        all_errors.extend(validate_ir(path))

    if all_errors:
        for err in all_errors:
            print(err)
        sys.exit(1)

    print("IR validation passed.")


if __name__ == "__main__":
    main()
