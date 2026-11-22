#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../example"
flutter test --dart-define=RENDER_EXAMPLE=true test/render_example_test.dart
