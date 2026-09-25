import Foundation

/// Video output formats. Like `AudioFormat`, everything is derived so the
/// converter stays generic.
enum VideoFormat: String, CaseIterable, Codable, Identifiable {
    case mp4
    case mkv
    case webm
    case mov
    case avi

    var id: String { rawValue }

    var displayName: String { rawValue.uppercased() }

    var fileExtension: String { rawValue }

    /// ffmpeg muxer/format name for the output container.
    var muxerName: String {
        switch self {
        case .mp4: "mp4"
        case .mov: "mov"
        case .mkv: "matroska"
        case .webm: "webm"
        case .avi: "avi"
        }
    }

    /// Preferred video codec when re-encoding is requested.
    var preferredVideoCodec: String {
        switch self {
        case .mp4, .mov: "libx264"
        case .mkv: "libx264"
        case .webm: "libvpx-vp9"
        case .avi: "mpeg4"
        }
    }

    /// Preferred audio codec inside the video container.
    var preferredAudioCodec: String {
        switch self {
        case .webm: "libopus"
        default: "aac"
        }
    }
}
