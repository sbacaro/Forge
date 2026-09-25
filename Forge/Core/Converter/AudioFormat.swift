import Foundation

/// Audio output formats supported by Forge. Codecs and encoder options are
/// derived properties of the enum, so adding a format never means touching
/// converter logic.
enum AudioFormat: String, CaseIterable, Codable, Identifiable {
    case wav
    case flac
    case aiff
    case mp3

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wav: "WAV"
        case .flac: "FLAC"
        case .aiff: "AIFF"
        case .mp3: "MP3"
        }
    }

    var fileExtension: String { rawValue }

    var isLossless: Bool {
        switch self {
        case .wav, .flac, .aiff: true
        case .mp3: false
        }
    }

    /// ffmpeg codec name for the output container.
    var codecName: String {
        switch self {
        case .wav: "pcm_s16le"
        case .flac: "flac"
        case .aiff: "pcm_s16be"
        case .mp3: "libmp3lame"
        }
    }

    /// File extension produced by the converter.
    var outputExtension: String { rawValue }
}
