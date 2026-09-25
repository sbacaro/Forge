import Foundation

/// Describes how Forge presents itself to sites when extracting media.
/// The goal is to reuse the user's real browser session as much as possible,
/// so requests look like they come from a person, not a script.
protocol ExtractionProfile {
    /// yt-dlp CLI flags derived from this profile.
    func arguments() -> [String]
}

/// Which browser cookies should be imported for the extraction session.
enum CookieSource: String, CaseIterable, Codable, Identifiable {
    case none
    case safari
    case chrome
    case firefox
    case edge
    case brave

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "None"
        case .safari: "Safari"
        case .chrome: "Chrome"
        case .firefox: "Firefox"
        case .edge: "Edge"
        case .brave: "Brave"
        }
    }

    /// yt-dlp expects lowercase browser names for `--cookies-from-browser`.
    var ytDlpName: String? {
        switch self {
        case .none: nil
        default: rawValue
        }
    }
}
