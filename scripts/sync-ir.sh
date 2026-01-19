#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node --loader "${repo_root}/tools/hljs-esm-loader.mjs" "${repo_root}/tools/extract-hljs-ir.mjs" --all
python3 "${repo_root}/tools/validate-ir.py" --dir "${repo_root}/tools/ir"
