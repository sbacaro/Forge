import Foundation

/// Scope of what should be downloaded when a URL points at a playlist
/// or channel.
enum PlaylistScope: String, CaseIterable, Codable, Identifiable {
    /// Download only the item at the URL itself (original behavior).
    case single
    /// Download the entire playlist or channel.
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single item"
        case .all: "Entire playlist"
        }
    }

    /// yt-dlp flag for limiting extraction to the URL itself.
    var ytDlpArguments: [String] {
        switch self {
        case .single: ["--no-playlist"]
        case .all: ["--yes-playlist"]
        }
    }
}
