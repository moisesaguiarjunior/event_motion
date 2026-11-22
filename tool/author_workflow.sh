#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  printf '%s\n' 'Usage: bash tool/author_workflow.sh brief.txt output-directory [event-log.json]' >&2
  exit 2
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dart "$root/example/bin/author_workflow.dart" "$@"
bash "$root/tool/render_example.sh" agent_pipeline "$2/workflow.json" "$2"
