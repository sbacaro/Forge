import Foundation

/// Locates command-line tools bundled inside the Forge .app.
/// The app is self-contained: yt-dlp, ffmpeg and ffprobe live next to the
/// main executable, so the user never installs anything.
protocol ToolLocator: Sendable {
    func url(forTool tool: BundledTool) -> URL?
}

enum BundledTool: String, CaseIterable {
    case ytDlp = "yt-dlp"
    case ffmpeg = "ffmpeg"
    case ffprobe = "ffprobe"
}

struct BundleToolLocator: ToolLocator {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func url(forTool tool: BundledTool) -> URL? {
        let fileName = tool.rawValue
        // When running from an .app, tools sit next to the executable.
        if let executables = bundle.executableURL?.deletingLastPathComponent() {
            let candidate = executables.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        // Fallback for running from a development checkout: Tools/ folder
        // next to the project root.
        if let sourceRoot = bundle.resourceURL?.deletingLastPathComponent() {
            let candidate = sourceRoot.appendingPathComponent("Tools").appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
