import Foundation

/// A request to download media from a URL.
struct DownloadRequest: Identifiable, Equatable {
    let id: UUID
    var url: URL
    var audioFormat: AudioFormat?
    var videoFormat: VideoFormat?
    var qualityProfile: QualityProfile
    var outputDirectory: URL
    var playlistScope: PlaylistScope
    var subtitleOptions: SubtitleOptions
    var embedThumbnail: Bool
    var embedMetadata: Bool
    var conversionSettings: ConversionSettings?

    init(
        id: UUID = UUID(),
        url: URL,
        audioFormat: AudioFormat? = nil,
        videoFormat: VideoFormat? = nil,
        qualityProfile: QualityProfile = .balanced,
        outputDirectory: URL,
        playlistScope: PlaylistScope = .single,
        subtitleOptions: SubtitleOptions = .disabled,
        embedThumbnail: Bool = false,
        embedMetadata: Bool = false,
        conversionSettings: ConversionSettings = .losslessDefaults
    ) {
        self.id = id
        self.url = url
        self.audioFormat = audioFormat
        self.videoFormat = videoFormat
        self.qualityProfile = qualityProfile
        self.outputDirectory = outputDirectory
        self.playlistScope = playlistScope
        self.subtitleOptions = subtitleOptions
        self.embedThumbnail = embedThumbnail
        self.embedMetadata = embedMetadata
        self.conversionSettings = conversionSettings
    }
}

/// Subtitle download preferences.
struct SubtitleOptions: Equatable {
    /// Download subtitles if available.
    var enabled: Bool
    /// Language tags (e.g. ["en", "pt-BR"]). Empty means all.
    var languages: [String]
    /// Embed into the output container.
    var embed: Bool

    static let disabled = SubtitleOptions(enabled: false, languages: [], embed: false)

    /// yt-dlp flags derived from the options.
    var ytDlpArguments: [String] {
        guard enabled else { return [] }
        var args: [String] = ["--write-subs"]
        if !languages.isEmpty {
            args += ["--sub-langs", languages.joined(separator: ",")]
        }
        if embed {
            args += ["--embed-subs"]
        }
        return args
    }
}

/// Lifecycle of a download or conversion task.
enum TaskState: Equatable {
    case queued
    case fetchingMetadata
    case downloading
    case converting(processor: String?)
    case completed
    case failed(reason: String)
    case pausedForUserAction(reason: String)
    case cancelled

    var isActive: Bool {
        switch self {
        case .queued, .fetchingMetadata, .downloading, .converting: true
        default: false
        }
    }
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
    /// The metadata fetch runs inside `operation`, so cancelling that task
    /// also terminates the underlying yt-dlp subprocess.
    func fetchMetadata(for url: URL, using profile: ExtractionProfile) async throws -> OutputParser.Metadata

    /// Downloads the media described by `request`, reporting progress.
    /// Progress events fire on a background queue; `DownloadQueue` hops
    /// them to the main actor. Cancelling the surrounding task terminates
    /// the yt-dlp subprocess.
    func download(
        _ request: DownloadRequest,
        using profile: ExtractionProfile,
        onProgress: @escaping @Sendable (OutputParser.Progress) -> Void,
        onPostprocess: @escaping @Sendable (OutputParser.PostprocessEvent) -> Void
    ) async throws -> URL
}
