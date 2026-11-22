#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'Usage: bash tool/render_example.sh [agent_pipeline|card_sequence]' >&2
  exit 2
fi

case "${1:-}" in
  '') set -- ;;
  agent_pipeline|card_sequence) set -- --plain-name "exports $1 as MP4 and PNG" ;;
  *) printf '%s\n' 'Usage: bash tool/render_example.sh [agent_pipeline|card_sequence]' >&2; exit 2 ;;
esac

cd "$(dirname "${BASH_SOURCE[0]}")/../example"
flutter test --dart-define=RENDER_EXAMPLE=true test/render_example_test.dart "$@"
