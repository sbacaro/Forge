# Forge

A native macOS app for downloading videos and audio from YouTube and other
sites, converting to high-fidelity audio formats (WAV, FLAC, AIFF, MP3) and
popular video formats — powered by embedded yt-dlp and FFmpeg.

Fully self-contained: everything the app needs ships inside the `.app`
bundle. No Homebrew, no Python, no external dependencies.

![Platform](https://img.shields.io/badge/platform-macOS%2027-black)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)

## Features

- **Download** video and audio from YouTube and hundreds of other sites via
  yt-dlp running as an embedded subprocess.
- **High-fidelity audio conversion** to WAV, FLAC, AIFF and MP3 with the
  embedded FFmpeg (sample rate and bitrate are user-configurable).
- **Video formats**: MP4, MKV, WebM, MOV and AVI.
- **Queue** with live progress, cancellation and human-like pacing between
  requests.
- **History** of completed downloads, persisted locally as JSON.
- **Standalone extraction profile**: import your browser cookies so sites
  see a real, authenticated session instead of an anonymous script.

## Human-like extraction (bot-detection mitigation)

Many sites ask script clients to "confirm you're not a bot". Forge handles
this by reusing *your* real browser session instead of bypassing anything:

- Cookies imported from Safari, Chrome, Firefox, Edge or Brave
  (`--cookies-from-browser`), or a manually exported `cookies.txt`.
- Optional custom user agent, `Accept-Language` and custom headers.
- Conservative rate limiting: sleeps between requests, limited bandwidth
  and single-fragment downloads by default.
- YouTube extractor client fallback via `--extractor-args` when a client
  gets blocked.
- An in-app alert guides you through importing cookies when a site
  challenges the request — no CAPTCHA solvers, no proxy rotation.

## Building

Requirements:

- macOS 27 (Golden Gate)
- Xcode 27
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the project

```bash
# 1. Generate the Xcode project
xcodegen generate

# 2. Download the embedded tools (yt-dlp, ffmpeg, ffprobe)
./scripts/bootstrap-tools.sh

# 3. Validate architectures and signatures
./scripts/validate-embed.sh

# 4. Build + test
xcodebuild -project Forge.xcodeproj -scheme Forge test

# 5. Package a self-contained .app
./scripts/package.sh            # produces build/Forge.app

# Optional: sign + notarize (needs Developer ID and notarytool profile)
FORGE_SIGNING_IDENTITY="Developer ID Application: ..." ./scripts/sign.sh build/Forge.app
```

## Project layout

```
Forge/               SwiftUI app (App/, UI/)
Forge/Core/          ForgeKit framework: Engine, Extraction, Downloader,
                     Converter, History (protocol-oriented, unit-tested)
ForgeTests/          XCTest suite
Tools/               embedded binaries (yt-dlp, ffmpeg, ffprobe)
scripts/             bootstrap, validation, packaging and signing
```

## Design notes

- **Zero hardcoding**: formats, codecs, quality selectors and extraction
  defaults are all derived from enums and `AppConstants`; nothing is baked
  into call sites.
- **Self-contained by construction**: binaries live in
  `Forge.app/Contents/MacOS/`, located at runtime through
  `Bundle.main.executableURL`.
- **HIG macOS 27**: `NavigationSplitView` with edge-to-edge sidebar,
  uniform toolbars, system materials, semantic colors and standard alert
  patterns.
- **Swift 6 concurrency**: strict Sendable checking; UI state is
  main-actor isolated and subprocess streaming is `@Sendable`-clean.

## Legal

Forge is licensed under the **GPL-3.0**. It bundles yt-dlp (public domain)
and FFmpeg (LGPL/GPL depending on build configuration).

Downloading media from sites like YouTube may violate their Terms of
Service and can infringe copyright. Use Forge only with content you own or
that is legally downloadable. You are responsible for how you use it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the
[code of conduct](CODE_OF_CONDUCT.md). PRs welcome — keep changes tested
and formatted.

## License

GPL-3.0 — see [LICENSE](LICENSE).
