#!/usr/bin/env bash
# Builds Forge and packages a fully self-contained .app:
# yt-dlp, ffmpeg and ffprobe are copied into Contents/MacOS next to the
# main executable, so the user needs nothing else installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
APP_NAME="Forge"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
CONFIGURATION="${1:-Release}"

# Build with Xcode.
cd "${PROJECT_ROOT}"
xcodebuild -project Forge.xcodeproj \
    -scheme Forge \
    -configuration "${CONFIGURATION}" \
    -destination 'platform=macOS' \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    build

BUILT_APP="$(find "${BUILD_DIR}/DerivedData" -type d -name "${APP_NAME}.app" -path '*Build/Products*' | head -1)"
[[ -n "${BUILT_APP}" ]] || { echo "Built app not found." >&2; exit 1; }

rm -rf "${APP_PATH}"
mkdir -p "${BUILD_DIR}"
cp -R "${BUILT_APP}" "${APP_PATH}"

# Embed the tools next to the main executable.
for tool in yt-dlp ffmpeg ffprobe; do
    src="${PROJECT_ROOT}/Tools/${tool}"
    [[ -f "${src}" ]] || { echo "Missing tool: ${path}. Run scripts/bootstrap-tools.sh first." >&2; exit 1; }
    cp "${TOOLS_DIR}/${tool}" "${APP_PATH}/Contents/MacOS/${tool}"
done

# Re-sign everything ad-hoc so the embedded tools and the app validate.
codesign --force --deep --sign - "${APP_PATH}"

echo
echo "Packaged: ${APP_PATH}"
du -sh "${APP_PATH}"
