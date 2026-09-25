#!/usr/bin/env bash
# Signs and optionally notarizes the packaged .app.
# Requires:
#   FORGE_SIGNING_IDENTITY  e.g. "Developer ID Application: Your Name (TEAMID)"
#   FORGE_NOTARY_PROFILE    keychain profile created with `xcrun notarytool store-credentials`
# Set FORGE_NOTARY_PROFILE only when notarization is desired.
set -euo pipefail

APP_PATH="${1:-build/Forge.app}"

if [[ -z "${FORGE_SIGNING_IDENTITY:-}" ]]; then
    echo "FORGE_SIGNING_IDENTITY is not set; falling back to ad-hoc signing."
    codesign --force --deep --sign - "${APP_PATH}"
    echo "Signed (ad-hoc): ${APP_PATH}"
    exit 0
fi

echo "Signing embedded binaries first..."
for tool in yt-dlp ffmpeg ffprobe; do
    tool_path="${APP_PATH}/Contents/MacOS/${tool}"
    [[ -f "${tool_path}" ]] && codesign --force --options runtime --timestamp \
        --sign "${FORGE_SIGNING_IDENTITY}" "${tool_path}"
done

echo "Signing app bundle..."
codesign --force --options runtime --timestamp \
    --entitlements "$(dirname "${BASH_SOURCE[0]}")/../Forge/Forge.entitlements" \
    --sign "${FORGE_SIGNING_IDENTITY}" "${APP_PATH}"

codesign --verify --strict --verbose=2 "${APP_PATH}"

if [[ -n "${FORGE_NOTARY_PROFILE:-}" ]]; then
    echo "Submitting for notarization..."
    zip -q -r "${APP_PATH}.zip" "${APP_PATH}"
    xcrun notarytool submit "${APP_PATH}.zip" \
        --keychain-profile "${FORGE_NOTARY_PROFILE}" --wait
    xcrun stapler staple "${APP_PATH}"
    rm "${APP_PATH}.zip"
    echo "Notarized: ${APP_PATH}"
fi

echo "Done."
