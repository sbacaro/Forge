import Foundation

/// A request to download media from a URL.
struct DownloadRequest: Identifiable, Equatable {
    let id: UUID
    var url: URL
    var audioFormat: AudioFormat?
    var videoFormat: VideoFormat?
    var qualityProfile: QualityProfile
    var outputDirectory: URL

    init(
        id: UUID = UUID(),
        url: URL,
        audioFormat: AudioFormat? = nil,
        videoFormat: VideoFormat? = nil,
        qualityProfile: QualityProfile = .balanced,
        outputDirectory: URL
    ) {
        self.id = id
        self.url = url
        self.audioFormat = audioFormat
        self.videoFormat = videoFormat
        self.qualityProfile = qualityProfile
        self.outputDirectory = outputDirectory
    }
}

/// Lifecycle of a download or conversion task.
enum TaskState: Equatable {
    case queued
    case fetchingMetadata
    case downloading
    case converting
    case completed
    case failed(reason: String)
    case pausedForUserAction(reason: String)
    case cancelled
}

/// Errors thrown by downloader implementations.
enum DownloadError: Error, LocalizedError {
    case invalidURL
    case toolMissing(name: String)
    case cancelled
    case botDetected(BotDetectionHandler.Detection)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The provided URL is not valid."
        case let .toolMissing(name):
            "Required tool '\(name)' is missing."
        case .cancelled:
            "The download was cancelled."
        case let .botDetected(detection):
            switch detection {
            case .botChallenge:
                "The site is asking to verify you are not a bot. Import your browser cookies in Settings → Extraction."
            case .rateLimited:
                "The site is rate limiting requests. Forge paused this task; try again shortly."
            case .accessDenied:
                "Access was denied. Make sure you can open this media in your browser, then try again."
            }
        }
    }
}

/// Abstraction for anything that can download media, so implementations
/// (yt-dlp today, others tomorrow) can be swapped and mocked in tests.
protocol VideoDownloader: AnyObject, Sendable {
    /// Fetches metadata for a URL without downloading anything.
    func fetchMetadata(for url: URL, using profile: ExtractionProfile) async throws -> OutputParser.Metadata

    /// Downloads the media described by `request`, reporting progress.
    func download(
        _ request: DownloadRequest,
        using profile: ExtractionProfile,
        onProgress: @escaping @Sendable (OutputParser.Progress) -> Void
    ) async throws -> URL
}
