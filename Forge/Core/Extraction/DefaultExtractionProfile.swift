import Foundation

/// Concrete profile that derives yt-dlp arguments from the live user
/// settings. Kept separate from `ExtractionSettings` so argument building
/// can be unit-tested independently of UI state.
struct DefaultExtractionProfile: ExtractionProfile {
    private let provider: () -> [String]

    init(settings: ExtractionSettings) {
        provider = { settings.extractionArguments() }
    }

    func arguments() -> [String] {
        provider()
    }
}

/// Value-based profile holding an already-resolved list of yt-dlp flags.
/// Sendable, so it can cross concurrency boundaries: build it on the main
/// actor from live settings, then hand it to background download work.
struct ResolvedExtractionProfile: ExtractionProfile, Sendable {
    private let args: [String]

    init(arguments: [String]) {
        args = arguments
    }

    func arguments() -> [String] {
        args
    }
}
