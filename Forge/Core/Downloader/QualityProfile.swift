import Foundation

/// Download quality preferences. Values are derived, never hardcoded
/// into call sites: consumers pick a profile and the implementation
/// translates it into yt-dlp format selectors.
enum QualityProfile: String, CaseIterable, Codable, Identifiable {
    case best
    case balanced
    case efficient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .best: "Best available"
        case .balanced: "Balanced"
        case .efficient: "Efficient"
        }
    }

    /// yt-dlp format selector. Audio-only profiles get bestaudio; video
    /// profiles prefer progressive MP4 then fall back to best merged.
    var formatSelector: String {
        switch self {
        case .best: "bestvideo+bestaudio/best"
        case .balanced: "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"
        case .efficient: "bestvideo[height<=720]+bestaudio/best[height<=720]/best"
        }
    }
}
