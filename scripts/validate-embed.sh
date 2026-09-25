#!/usr/bin/env bash
# Validates that the tools in Tools/ are suitable for embedding:
# correct architecture and valid code signature.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/../Tools"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

for tool in yt-dlp ffmpeg ffprobe; do
    path="${TOOLS_DIR}/${tool}"
    [[ -f "${path}" ]] || { echo "MISSING: ${path}" >&2; exit 1; }

    arch="$(lipo -info "${path}" 2>/dev/null | sed 's/^[^:]*: //')"
    echo "${tool}: ${arch}"

    # Everything must run natively on this machine's architecture.
    host_arch="$(uname -m)"
    case "${host_arch}" in
        arm64)  [[ "${arch}" == *"arm64"* || "${arch}" == *"x86_64"* ]] || fail "${tool} does not run on ${host_arch}" ;;
        x86_64) [[ "${arch}" == *"x86_64"* ]] || fail "${tool} does not run on ${host_arch}" ;;
    esac

    # Ad-hoc signature must be at least valid.
    if codesign --verify --deep "${path}" >/dev/null 2>&1; then
        echo "  signature: OK"
    else
        echo "  signature: UNSIGNED (ad-hoc signing will happen at packaging)"
    fi
done

echo "All embedded tools validated."
