#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/validate-project.py
for script in scripts/*.sh; do bash -n "$script"; done
swift test --jobs 4
if [[ "$(uname -s)" == Darwin ]]; then
  ./scripts/build-app.sh debug
else
  # Parse macOS-only files without resolving unavailable Apple frameworks.
  while IFS= read -r -d '' source; do
    swiftc -frontend -parse "$source"
  done < <(find Sources/GlassFinder -name '*.swift' -print0)
  swiftc -frontend -parse scripts/make-icon.swift
fi
