import Foundation

/// yt-dlp based downloader. Runs the bundled yt-dlp binary as a subprocess,
/// applying the user's extraction profile so requests reuse their real
/// browser session.
final class YtDlpDownloader: VideoDownloader {
    private let toolEngine: ToolEngine
    private let toolLocator: ToolLocator
    private let parser = OutputParser()
    private let botDetector = BotDetectionHandler()

    init(toolEngine: ToolEngine = ProcessEngine(), toolLocator: ToolLocator = BundleToolLocator()) {
        self.toolEngine = toolEngine
        self.toolLocator = toolLocator
    }

    func fetchMetadata(
        for url: URL,
        using profile: ExtractionProfile
    ) async throws -> OutputParser.Metadata {
        guard let tool = toolLocator.url(forTool: .ytDlp) else {
            throw DownloadError.toolMissing(name: BundledTool.ytDlp.rawValue)
        }
        guard Self.isWebURL(url) else { throw DownloadError.invalidURL }

        let args = profile.arguments() + ["-J", "--no-warnings", url.absoluteString]
        let result = try await toolEngine.run(tool: tool, arguments: args, environment: [:])
        guard result.exitCode == 0 else {
            if let detection = botDetector.classify(output: result.standardError) {
                throw DownloadError.botDetected(detection)
            }
            throw YtDlpError.executionFailed(
                message: lastMeaningfulLine(result.standardError)
                    ?? "yt-dlp exited with code \(result.exitCode)."
            )
        }
        guard let data = result.standardOutput.data(using: .utf8) else {
            throw YtDlpError.executionFailed(message: "Empty metadata response.")
        }
        return try parser.parseMetadata(fromJSON: data)
    }

    func download(
        _ request: DownloadRequest,
        using profile: ExtractionProfile,
        onProgress: @escaping @Sendable (OutputParser.Progress) -> Void
    ) async throws -> URL {
        guard let tool = toolLocator.url(forTool: .ytDlp) else {
            throw DownloadError.toolMissing(name: BundledTool.ytDlp.rawValue)
        }
        guard Self.isWebURL(request.url) else { throw DownloadError.invalidURL }

        var args = profile.arguments()
        args += ["--no-playlist", "-f", request.qualityProfile.formatSelector]
        args += ["-P", request.outputDirectory.path]
        // Apps launched from Finder don't inherit the shell PATH; point
        // yt-dlp at the ffmpeg/ffprobe embedded next to the executable.
        if let ffmpegURL = toolLocator.url(forTool: .ffmpeg) {
            args += ["--ffmpeg-location", ffmpegURL.deletingLastPathComponent().path]
        }
        if let audio = request.audioFormat {
            args += ["-x", "--audio-format", audio.rawValue]
        }
        if let video = request.videoFormat {
            args += ["--merge-output-format", video.rawValue]
        }
        args += request.playlistScope.ytDlpArguments
        args += request.subtitleOptions.ytDlpArguments
        if request.embedThumbnail {
            args += ["--embed-thumbnail"]
        }
        if request.embedMetadata {
            args += ["--embed-metadata"]
        }
        args += ["--newline", request.url.absoluteString]

        let suspiciousCollector = SuspiciousOutputCollector()
        let result = try await toolEngine.runStreaming(
            tool: tool,
            arguments: args,
            environment: [:]
        ) { chunk in
            for line in chunk.split(separator: "\n") {
                let line = String(line)
                if let progress = Self.staticParser.parseProgress(line: line) {
                    onProgress(progress)
                } else if Self.staticDetector.classify(output: line) != nil {
                    suspiciousCollector.append(line)
                } else if line.hasPrefix("ERROR") {
                    // Keep real failures around for the error report even
                    // when they don't match a bot-detection pattern.
                    suspiciousCollector.append(line)
                }
            }
        }

        guard result.exitCode == 0 else {
            let combined = result.standardError + suspiciousCollector.text
            if let detection = Self.staticDetector.classify(output: combined) {
                throw DownloadError.botDetected(detection)
            }
            let message = lastMeaningfulLine(combined)
                ?? lastMeaningfulLine(result.standardError)
                ?? "yt-dlp exited with code \(result.exitCode)."
            throw YtDlpError.executionFailed(
                message: "\(message) [exit \(result.exitCode); args: \(args.joined(separator: " "))]"
            )
        }

        return try Self.latestMediaFile(in: request.outputDirectory)
    }

    private static let staticParser = OutputParser()
    private static let staticDetector = BotDetectionHandler()

    /// Thread-safe sink for output lines that look like bot-blocking errors.
    private final class SuspiciousOutputCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var storage = ""

        var text: String { lock.lock(); defer { lock.unlock() }; return storage }

        func append(_ line: String) {
            lock.lock()
            defer { lock.unlock() }
            storage += line + "\n"
        }
    }

    private func lastMeaningfulLine(_ text: String) -> String? {
        text.split(separator: "\n")
            .map(String.init)
            .reversed()
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && url.host() != nil
    }

    private static func latestMediaFile(in directory: URL) throws -> URL {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )
        let mediaExtensions: Set<String> = ["mp4", "mkv", "webm", "m4a", "wav", "flac", "aiff", "mp3", "mov", "avi"]
        let mediaFiles = contents.filter { mediaExtensions.contains($0.pathExtension.lowercased()) }
        guard let latest = mediaFiles.sorted(by: { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return lhsDate > rhsDate
        }).first else {
            throw YtDlpError.executionFailed(message: "Download finished but no media file was found in \(directory.path).")
        }
        return latest
    }
}

enum YtDlpError: Error, LocalizedError {
    case executionFailed(message: String)

    var errorDescription: String? {
        switch self {
        case let .executionFailed(message):
            message
        }
    }
}
