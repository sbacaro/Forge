import Foundation

/// Lists browsers available for cookie import. Kept in the Extraction layer
/// because it pairs cookie availability with the extraction settings UI.
struct BrowserProfileImporter {
    /// Browsers yt-dlp supports via `--cookies-from-browser` on macOS.
    static let supportedBrowsers: [CookieSource] = [
        .safari, .chrome, .firefox, .edge, .brave,
    ]

    /// Rough check for whether the given browser seems installed. Safari is
    /// always present on macOS.
    func isBrowserAvailable(_ source: CookieSource) -> Bool {
        switch source {
        case .none: true
        case .safari: true
        case .chrome: appExists("Google Chrome")
        case .firefox: appExists("Firefox")
        case .edge: appExists("Microsoft Edge")
        case .brave: appExists("Brave Browser")
        }
    }

    private func appExists(_ name: String) -> Bool {
        let paths = [
            "/Applications/\(name).app",
            "\(NSHomeDirectory())/Applications/\(name).app",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
