import SwiftUI

/// Top-level observable model shared across the app via the environment.
@Observable
final class AppModel {
    let downloadQueue: DownloadQueue
    let historyStore: HistoryStore
    let extractionSettings: ExtractionSettings

    @ObservationIgnored var lastSelectedAudioFormat: AudioFormat {
        get { stored(AudioFormat.self, key: "lastSelectedAudioFormat") ?? .flac }
        set { store(newValue, key: "lastSelectedAudioFormat") }
    }

    @ObservationIgnored var lastSelectedVideoFormat: VideoFormat {
        get { stored(VideoFormat.self, key: "lastSelectedVideoFormat") ?? .mp4 }
        set { store(newValue, key: "lastSelectedVideoFormat") }
    }

    @ObservationIgnored var lastSelectedQuality: QualityProfile {
        get { stored(QualityProfile.self, key: "lastSelectedQuality") ?? .best }
        set { store(newValue, key: "lastSelectedQuality") }
    }

    @ObservationIgnored var lastSelectedPlaylistScope: PlaylistScope {
        get { stored(PlaylistScope.self, key: "lastSelectedPlaylistScope") ?? .single }
        set { store(newValue, key: "lastSelectedPlaylistScope") }
    }

    var downloadSubtitles = false

    /// Watches the pasteboard for copied media URLs.
    let clipboardMonitor: ClipboardMonitor

    var outputDirectory: URL {
        get {
            if let raw = UserDefaults.standard.string(forKey: "outputDirectory"),
               let url = URL(string: raw) {
                return url
            }
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: "outputDirectory") }
    }

    /// Set to true when some view should present the Settings scene.
    var shouldPresentSettings = false

    /// Subtitle language tags used when the user enables subtitles.
    var subtitleLanguages: String {
        get { UserDefaults.standard.string(forKey: "subtitleLanguages") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "subtitleLanguages") }
    }

    var embedThumbnail = true
    var embedMetadata = true

    @MainActor
    init(
        downloadQueue: DownloadQueue? = nil,
        historyStore: HistoryStore = JSONHistoryStore(),
        extractionSettings: ExtractionSettings = ExtractionSettings()
    ) {
        self.extractionSettings = extractionSettings
        self.historyStore = historyStore
        self.clipboardMonitor = ClipboardMonitor()
        self.downloadQueue = downloadQueue ?? DownloadQueue(
            downloader: YtDlpDownloader(),
            throttle: RateThrottle(),
            historyStore: historyStore
        )
    }

    func requestSettingsPresentation() {
        shouldPresentSettings = true
    }

    private func stored<T: RawRepresentable>(_ type: T.Type, key: String) -> T? where T.RawValue == String {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return T(rawValue: raw)
    }

    private func store<T: RawRepresentable>(_ value: T, key: String) where T.RawValue == String {
        UserDefaults.standard.set(value.rawValue, forKey: key)
    }
}
