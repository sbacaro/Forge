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
