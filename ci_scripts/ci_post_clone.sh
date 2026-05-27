#!/bin/sh
set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
FLUTTER_ROOT="${HOME}/flutter"

echo "Repository root: ${REPO_ROOT}"
cd "${REPO_ROOT}"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
  echo "Using existing Flutter: ${FLUTTER_BIN}"
else
  echo "Flutter not found. Cloning stable SDK to ${FLUTTER_ROOT}..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable "${FLUTTER_ROOT}"
  FLUTTER_BIN="${FLUTTER_ROOT}/bin/flutter"
  export PATH="${FLUTTER_ROOT}/bin:${PATH}"
fi

"${FLUTTER_BIN}" --version
"${FLUTTER_BIN}" precache --ios
"${FLUTTER_BIN}" pub get
"${FLUTTER_BIN}" build ios --release --no-codesign --config-only

cd ios
pod install
