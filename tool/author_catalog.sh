#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf '%s\n' 'Usage: bash tool/author_catalog.sh brief.txt output-directory' >&2
  exit 2
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dart "$root/example/bin/author_catalog.dart" "$@"
bash "$root/tool/render_example.sh" editorial_catalog "$2/catalog.json" "$2"
