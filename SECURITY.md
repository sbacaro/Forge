# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |

## Reporting a vulnerability

Please report security issues privately using GitHub's "Report a
vulnerability" in the Security tab. Do not open a public issue for
exploitable problems.

## Scope notes

- Forge executes bundled binaries (yt-dlp, ffmpeg) as subprocesses. Issues
  involving argument injection from URLs or settings are in scope.
- The app requests network access and user-selected file access only.
