# Contributing to Forge

Thanks for your interest in improving Forge!

## Development setup

1. Install Xcode 27 and macOS 27 SDK.
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   `brew install xcodegen`
3. Generate the project: `xcodegen generate`
4. Fetch embedded tools: `./scripts/bootstrap-tools.sh`
5. Run tests: `xcodebuild -project Forge.xcodeproj -scheme Forge test`

## Ground rules

- **No hardcoded values.** Add tunables to `AppConstants` or derive them
  from the format/quality enums. PRs introducing magic numbers in call
  sites will be asked to refactor.
- **Protocol-oriented core.** Engine, downloader, converter and history
  logic lives behind protocols in `Forge/Core`; UI code never talks to
  concrete tools directly.
- **Strict concurrency.** Code must build cleanly under Swift 6 language
  mode. Prefer main-actor isolation for UI state and `@Sendable` closures
  for process streaming.
- **Tests for behavior changes.** Parsers, argument builders and stores
  all have unit tests — extend them when you change behavior.
- **HIG compliance.** UI changes should follow Apple's macOS 27 Human
  Interface Guidelines (Liquid Glass, semantic colors, standard controls).

## Commit style

Short imperative subject, optional body explaining the *why*:

```
Fix percent capture in progress parser
```

## Pull requests

- Keep PRs focused; one feature or fix per PR.
- Make sure `xcodebuild test` passes locally.
- Update `README.md` if you add user-facing behavior.

## Reporting issues

Include your macOS version, Xcode version, the URL pattern involved (no
need for the exact media) and the relevant yt-dlp output from the app log.
