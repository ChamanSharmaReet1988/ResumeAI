#!/usr/bin/env bash
# Pre-populates PDFium for the pdfium_flutter CocoaPods pod so `pod install` does not
# rely on a single curl (GitHub often returns 504/HTML for tiny bodies that fail the SHA check).
#
# Keep PDFIUM_URL / EXPECTED_HASH in sync with:
#   ~/.pub-cache/hosted/pub.dev/pdfium_flutter-*/darwin/pdfium_flutter.podspec

set -euo pipefail

PDFIUM_DARWIN_DIR="${1:-}"
if [[ -z "${PDFIUM_DARWIN_DIR}" ]]; then
  echo "usage: $0 <path/to/pdfium_flutter/darwin>" >&2
  exit 1
fi

PDFIUM_URL="https://github.com/espresso3389/pdfium-xcframework/releases/download/v144.0.7520.0-20251111-190355/PDFium-chromium-7520-20251111-190355.xcframework.zip"
EXPECTED_HASH="bd2a9542f13c78b06698c7907936091ceee2713285234cbda2e16bc03c64810b"
MIN_BYTES=500000

cd "${PDFIUM_DARWIN_DIR}"

HASH_FILE=".pdfium_hash"
if [[ -d PDFium.xcframework && -f "${HASH_FILE}" && "$(cat "${HASH_FILE}")" == "${EXPECTED_HASH}" ]]; then
  echo "[ensure_pdfium] PDFium.xcframework already present and hash matches."
  exit 0
fi

echo "[ensure_pdfium] Preparing PDFium.xcframework under ${PDFIUM_DARWIN_DIR}"

rm -rf PDFium.xcframework
rm -f "${HASH_FILE}" pdfium.zip

attempt=1
max_attempts=12
while [[ "${attempt}" -le "${max_attempts}" ]]; do
  echo "[ensure_pdfium] Download attempt ${attempt}/${max_attempts}..."

  rm -f pdfium.zip
  if curl -fL \
    --connect-timeout 30 \
    --max-time 900 \
    --retry 5 \
    --retry-delay 8 \
    --retry-all-errors \
    -o pdfium.zip \
    "${PDFIUM_URL}"; then
    :
  else
    echo "[ensure_pdfium] curl failed (exit $?)."
    attempt=$((attempt + 1))
    sleep $((attempt * 5))
    continue
  fi

  size=$(wc -c < pdfium.zip | tr -d ' ')
  if [[ "${size}" -lt "${MIN_BYTES}" ]]; then
    echo "[ensure_pdfium] Downloaded file too small (${size} bytes), not a valid zip. Retrying..."
    rm -f pdfium.zip
    attempt=$((attempt + 1))
    sleep $((attempt * 5))
    continue
  fi

  ACTUAL_HASH=$(shasum -a 256 pdfium.zip | awk '{print $1}')
  if [[ "${ACTUAL_HASH}" != "${EXPECTED_HASH}" ]]; then
    echo "[ensure_pdfium] Hash mismatch (attempt ${attempt})."
    echo "  expected: ${EXPECTED_HASH}"
    echo "  actual:   ${ACTUAL_HASH}"
    rm -f pdfium.zip
    attempt=$((attempt + 1))
    sleep $((attempt * 5))
    continue
  fi

  echo "[ensure_pdfium] Hash OK, extracting..."
  unzip -q pdfium.zip
  rm -f pdfium.zip
  echo "${EXPECTED_HASH}" > "${HASH_FILE}"
  echo "[ensure_pdfium] PDFium.xcframework ready."
  exit 0
done

echo "[ensure_pdfium] Failed to download and verify PDFium after ${max_attempts} attempts." >&2
exit 1
