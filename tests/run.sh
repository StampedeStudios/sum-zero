#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

godot="${GODOT:-godot}"
"$godot" --headless --editor --path . --import
gdlint scripts tests

for test in tests/*test.gd; do
  if [[ "$test" == *editor_preview_test.gd ]]; then
    "$godot" --headless --editor --path . --script "$test"
  else
    "$godot" --headless --path . --script "$test"
  fi
done
