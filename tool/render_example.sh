#!/usr/bin/env bash
set -euo pipefail

unset EVENT_MOTION_WORKFLOW
case "$#:${1:-}" in
  0:) ;;
  1:agent_pipeline|1:card_sequence) set -- --plain-name "exports $1 as MP4 and PNG" ;;
  2:agent_pipeline)
    if [[ ! -f "$2" ]]; then
      printf 'Workflow file not found: %s\n' "$2" >&2
      exit 2
    fi
    case "$2" in
      /*) export EVENT_MOTION_WORKFLOW="$2" ;;
      *) export EVENT_MOTION_WORKFLOW="$PWD/$2" ;;
    esac
    set -- --plain-name 'exports agent_pipeline as MP4 and PNG'
    ;;
  *)
    printf '%s\n' 'Usage: bash tool/render_example.sh [agent_pipeline [workflow.json]|card_sequence]' >&2
    exit 2
    ;;
esac

cd "$(dirname "${BASH_SOURCE[0]}")/../example"
flutter test --dart-define=RENDER_EXAMPLE=true test/render_example_test.dart "$@"
