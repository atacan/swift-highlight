#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ir_dir="${repo_root}/tools/ir"

if [[ ! -d "${ir_dir}" ]]; then
  echo "Missing ${ir_dir}. Run scripts/sync-ir.sh first."
  exit 1
fi

for json in "${ir_dir}"/*.json; do
  lang="$(basename "${json}" .json)"
  python3 "${repo_root}/tools/generate-swift-from-ir.py" --lang "${lang}" --input "${json}"
done
