import Foundation

/// Quality knobs for conversion. All values are user-visible defaults that
/// can be overridden in Settings; nothing is baked into call sites.
struct ConversionSettings: Codable, Equatable {
    /// Sample rate in Hz. `nil` keeps the source rate.
    var sampleRateHz: Int?

    /// Audio bitrate in kbps (only meaningful for lossy formats).
    var audioBitrateKbps: Int?

    /// Number of channels; `nil` keeps the source layout.
    var channelCount: Int?

    /// Video CRF (0–51, lower is better). `nil` keeps the source quality.
    var videoCRF: Int?

    static let standard = ConversionSettings(
        sampleRateHz: nil,
        audioBitrateKbps: 320,
        channelCount: nil,
        videoCRF: nil
    )

    static let losslessDefaults = ConversionSettings(
        sampleRateHz: nil,
        audioBitrateKbps: nil,
        channelCount: nil,
        videoCRF: nil
    )
}

/// A single conversion job.
struct ConversionJob: Identifiable {
    let id: UUID
    let sourceURL: URL
    let destinationURL: URL
    let settings: ConversionSettings

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        destinationURL: URL,
        settings: ConversionSettings = .losslessDefaults
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.settings = settings
    }
}
