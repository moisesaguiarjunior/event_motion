#!/usr/bin/env bash
set -euo pipefail

unset EVENT_MOTION_WORKFLOW
unset EVENT_MOTION_WORKFLOW_OUT
unset EVENT_MOTION_AUDIO
unset EVENT_MOTION_MATERIAL
unset EVENT_MOTION_CARDS
unset EVENT_MOTION_EDITORIAL
unset EVENT_MOTION_EDITORIAL_OUT

absolute_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$PWD" "$1" ;;
  esac
}

case "$#:${1:-}" in
  0:) set -- --name 'exports (agent_pipeline|card_sequence) as MP4 and PNG' ;;
  1:agent_pipeline|1:card_sequence|1:activation|1:cha_de_estrelas|1:jardim_sonho) set -- --plain-name "exports $1 as MP4 and PNG" ;;
  1:comparison) set -- --plain-name 'exports comparison as PNG' ;;
  [123]:editorial_catalog|[123]:editorial_matrix|[123]:editorial_illustration|[123]:editorial_illustration_video|[123]:character_poster|[123]:character_dashboard|[123]:data_story|[123]:data_story_video)
    if [[ $# -ge 2 ]]; then
      if [[ ! -f "$2" ]]; then
        printf 'Editorial input not found: %s\n' "$2" >&2
        exit 2
      fi
      EVENT_MOTION_EDITORIAL=$(absolute_path "$2")
      export EVENT_MOTION_EDITORIAL
    fi
    if [[ $# -eq 3 ]]; then
      EVENT_MOTION_EDITORIAL_OUT=$(absolute_path "$3")
      export EVENT_MOTION_EDITORIAL_OUT
    fi
    editorial_name=$1
    formats='MP4 and PNG'
    case "$1" in
      character_poster|data_story|editorial_matrix|editorial_illustration) formats='PNG' ;;
    esac
    set -- --plain-name "exports $1 as $formats"
    ;;
  2:card_sequence)
    if [[ ! -f "$2" ]]; then
      printf 'Card file not found: %s\n' "$2" >&2
      exit 2
    fi
    EVENT_MOTION_CARDS=$(absolute_path "$2")
    export EVENT_MOTION_CARDS
    set -- --plain-name 'exports card_sequence as MP4 and PNG'
    ;;
  2:activation)
    if [[ ! -f "$2" ]]; then
      printf 'Audio file not found: %s\n' "$2" >&2
      exit 2
    fi
    EVENT_MOTION_AUDIO=$(absolute_path "$2")
    export EVENT_MOTION_AUDIO
    set -- --plain-name 'exports activation as MP4 and PNG'
    ;;
  2:comparison)
    case "$2" in
      paper|linen) export EVENT_MOTION_MATERIAL="$2" ;;
      *) printf '%s\n' 'Comparison material must be paper or linen.' >&2; exit 2 ;;
    esac
    set -- --plain-name 'exports comparison as PNG'
    ;;
  2:agent_pipeline|3:agent_pipeline)
    if [[ ! -f "$2" ]]; then
      printf 'Workflow file not found: %s\n' "$2" >&2
      exit 2
    fi
    EVENT_MOTION_WORKFLOW=$(absolute_path "$2")
    export EVENT_MOTION_WORKFLOW
    if [[ $# -eq 3 ]]; then
      EVENT_MOTION_WORKFLOW_OUT=$(absolute_path "$3")
      export EVENT_MOTION_WORKFLOW_OUT
    fi
    set -- --plain-name 'exports agent_pipeline as MP4 and PNG'
    ;;
  *)
    printf '%s\n' 'Usage: bash tool/render_example.sh [agent_pipeline [workflow.json [output-directory]]|card_sequence [cards.json]|activation [audio.wav]|comparison [paper|linen]]' >&2
    printf '%s\n' '       bash tool/render_example.sh editorial_catalog|character_poster|character_dashboard [input.json [output-directory]]' >&2
    printf '%s\n' '       bash tool/render_example.sh data_story|data_story_video [input.json [output-directory]]' >&2
    printf '%s\n' '       bash tool/render_example.sh editorial_matrix [input.json [output-directory]]' >&2
    printf '%s\n' '       bash tool/render_example.sh editorial_illustration|editorial_illustration_video [input.json [output-directory]]' >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/../example"
flutter test --dart-define=RENDER_EXAMPLE=true test/render_example_test.dart "$@"

case "${editorial_name:-}" in
  editorial_illustration|editorial_illustration_video)
    destination="${EVENT_MOTION_EDITORIAL_OUT:-build/$editorial_name}"
    python3 -B "$script_dir/png_alt_text.py" "$destination/$editorial_name.png" \
      "${EVENT_MOTION_EDITORIAL:-fixtures/editorial_illustration.json}"
    ;;
  data_story|data_story_video)
    destination="${EVENT_MOTION_EDITORIAL_OUT:-build/$editorial_name}"
    poster="$destination/$editorial_name.png"
    if [[ -n "${EVENT_MOTION_EDITORIAL:-}" ]]; then
      python3 -B "$script_dir/png_alt_text.py" "$poster" "$EVENT_MOTION_EDITORIAL"
    elif [[ -n "${EVENT_MOTION_EDITORIAL_ALT_TEXT:-}" ]]; then
      python3 -B "$script_dir/png_alt_text.py" "$poster"
    fi
    ;;
esac
