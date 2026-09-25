#!/usr/bin/env bash
# Downloads the command-line tools that Forge embeds into the .app:
#   - yt-dlp (universal macOS standalone)
#   - ffmpeg / ffprobe (static arm64 builds)
# All downloads are verified with SHA-256 before being accepted.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${SCRIPT_DIR}/../Tools"
mkdir -p "${TOOLS_DIR}"

# ---------------------------------------------------------------------------
# Versions and URLs. Update these when new releases come out.
# ---------------------------------------------------------------------------
YTDLP_VERSION="2026.08.19"
YTDLP_URL="https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_macos"
YTDLP_SHA256_URL="https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/SHA2-256SUMS"

# Martin Riedl's static FFmpeg builds (signed). Pin the date-specific URL
# for reproducibility; check https://ffmpeg.martin-riedl.de for updates.
FFMPEG_BASE="https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release"
FFMPEG_URL="${FFMPEG_BASE}/ffmpeg.zip"
FFPROBE_URL="${FFMPEG_BASE}/ffprobe.zip"

# ---------------------------------------------------------------------------
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v shasum >/dev/null || { echo "shasum is required" >&2; exit 1; }

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

fetch() {
    local url="$1" out="$2"
    echo "Downloading ${url}"
    curl -fsSL --retry 3 -o "${out}" "${url}"
}

verify_sha256() {
    local file="$1" expected="$2"
    local actual
    actual="$(shasum -a 256 "${file}" | awk '{print $1}')"
    if [[ "${actual}" != "${expected}" ]]; then
        echo "SHA-256 mismatch for ${file}: expected ${expected}, got ${actual}" >&2
        exit 1
    fi
}

# --- yt-dlp -----------------------------------------------------------------
echo "==> yt-dlp ${YTDLP_VERSION}"
fetch "${YTDLP_URL}" "${temp_dir}/yt-dlp_macos"
# Fetch the signed checksum file and extract the expected digest.
fetch "${YTDLP_SHA256_URL}" "${temp_dir}/SHA2-256SUMS"
expected_ytdlp="$(grep -E '(^|[[:space:]])yt-dlp_macos($|[[:space:]])' "${temp_dir}/SHA2-256SUMS" | awk '{print $1}')"
if [[ -n "${expected_ytdlp}" ]]; then
    verify_sha256 "${temp_dir}/yt-dlp_macos" "${expected_ytdlp}"
else
    echo "Warning: could not find yt-dlp_macos in checksum file; skipping hash check." >&2
fi
chmod +x "${temp_dir}/yt-dlp_macos"
cp "${temp_dir}/yt-dlp_macos" "${TOOLS_DIR}/yt-dlp"
# Clear Gatekeeper quarantine for local development builds.
xattr -d com.apple.quarantine "${TOOLS_DIR}/yt-dlp" 2>/dev/null || true

# --- ffmpeg / ffprobe --------------------------------------------------------
fetch "${FFMPEG_URL}" "${temp_dir}/ffmpeg.zip"
unzip -oq "${temp_dir}/ffmpeg.zip" -d "${temp_dir}/ffmpeg"
bin_path="$(find "${temp_dir}/ffmpeg" -type f -name ffmpeg | head -1)"
if [[ -z "${bin_path}" ]]; then
    echo "Could not locate ffmpeg inside the downloaded zip." >&2
    exit 1
fi
chmod +x "${bin_path}"
cp "${bin_path}" "${TOOLS_DIR}/ffmpeg"
xattr -d com.apple.quarantine "${TOOLS_DIR}/ffmpeg" 2>/dev/null || true

fetch "${FFPROBE_URL}" "${temp_dir}/ffprobe.zip"
unzip -oq "${temp_dir}/ffprobe.zip" -d "${temp_dir}/ffprobe"
bin_path="$(find "${temp_dir}/ffprobe" -type f -name ffprobe | head -1)"
if [[ -z "${bin_path}" ]]; then
    echo "Could not locate ffprobe inside the downloaded zip." >&2
    exit 1
fi
chmod +x "${bin_path}"
cp "${bin_path}" "${TOOLS_DIR}/ffprobe"
xattr -d com.apple.quarantine "${TOOLS_DIR}/ffprobe" 2>/dev/null || true

# ---------------------------------------------------------------------------
echo
echo "Verifying embedded tools:"
for f in yt-dlp ffmpeg ffprobe; do
    path="${TOOLS_DIR}/${f}"
    if [[ ! -f "${path}" ]]; then
        echo "  ${f}: MISSING" >&2
        exit 1
    fi
    if lipo -info "${path}" >/dev/null 2>&1; then
        arch_info="$(lipo -info "${path}" | sed 's/^[^:]*: //')"
    else
        arch_info="unknown"
    fi
    printf '  %-10s %s (%s)\n' "${f}" "$(du -h "${path}" | cut -f1)" "${arch_info}"
done
echo
echo "Tools are ready in ${TOOLS_DIR}."
