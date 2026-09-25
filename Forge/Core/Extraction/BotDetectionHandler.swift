import Foundation

/// Detects gatekeeper bot-blocking signals in yt-dlp output.
/// When triggered, the app pauses the task and guides the user toward
/// reusing their real browser session (cookies) instead of bypassing
/// protections.
struct BotDetectionHandler {
    /// Patterns that indicate the site refused the request as bot traffic.
    static let detectionPatterns: [String] = [
        "Sign in to confirm you're not a bot",
        "Sign in to confirm your age",
        "This request was blocked",
        "HTTP Error 403",
        "HTTP Error 429",
        "rate limit reached",
        "unable to download video data",
        "nsig extraction failed",
    ]

    enum Detection: Equatable {
        case botChallenge
        case rateLimited
        case accessDenied
    }

    /// Classifies a chunk of yt-dlp stderr/stdout output.
    /// Returns nil when nothing suspicious is found.
    func classify(output: String) -> Detection? {
        let lowered = output.lowercased()
        for pattern in Self.detectionPatterns {
            if lowered.contains(pattern.lowercased()) {
                if pattern.contains("429") || pattern.contains("rate limit") {
                    return .rateLimited
                }
                if pattern.contains("403") || pattern.contains("blocked") {
                    return .accessDenied
                }
                return .botChallenge
            }
        }
        return nil
    }
}
