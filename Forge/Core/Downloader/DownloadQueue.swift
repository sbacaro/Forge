import Foundation

/// Serial FIFO queue of download tasks with cooperative cancellation and
/// human-like submission pacing via `RateThrottle`.
/// The queue itself is main-actor isolated; only subprocess work runs off
/// the main actor.
@MainActor
@Observable
final class DownloadQueue {
    private(set) var tasks: [DownloadTask] = []
    private let downloader: VideoDownloader
    private let throttle: RateThrottle
    private let historyStore: HistoryStore
    private var drainTask: Task<Void, Never>?

    init(
        downloader: VideoDownloader = YtDlpDownloader(),
        throttle: RateThrottle = RateThrottle(),
        historyStore: HistoryStore = JSONHistoryStore()
    ) {
        self.downloader = downloader
        self.throttle = throttle
        self.historyStore = historyStore
    }

    var activeTask: DownloadTask? {
        tasks.first { !$0.isTerminal && isActive($0.state) }
    }

    func enqueue(_ request: DownloadRequest) {
        tasks.append(DownloadTask(request: request))
        startIfIdle()
    }

    func cancel(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        task.update(state: .cancelled)
    }

    func clearFinished() {
        tasks.removeAll { $0.isTerminal }
    }

    func dismissUserActionMessages() {
        for task in tasks where task.userActionMessage != nil {
            task.userActionMessage = nil
        }
    }

    private func isActive(_ state: TaskState) -> Bool {
        switch state {
        case .queued, .fetchingMetadata, .downloading, .converting: true
        default: false
        }
    }

    private func startIfIdle() {
        guard drainTask == nil else { return }
        drainTask = Task { [weak self] in
            await self?.drain()
            await MainActor.run { self?.drainTask = nil }
        }
    }

    private func drain() async {
        while let next = firstQueued() {
            guard !Task.isCancelled else { break }
            await throttle.waitTurn()
            await run(next)
        }
    }

    private func firstQueued() -> DownloadTask? {
        tasks.first { !$0.isTerminal && $0.state == .queued }
    }

    private func run(_ task: DownloadTask) async {
        task.update(state: .fetchingMetadata)
        do {
            let profile = DefaultExtractionProfile(settings: ExtractionSettings())
            let metadata = try await downloader.fetchMetadata(for: task.request.url, using: profile)
            task.update(metadata: metadata)
            task.update(state: .downloading)

            let fileURL = try await downloader.download(task.request, using: profile) { progress in
                MainActor.assumeIsolated {
                    task.update(progress: progress)
                }
            }
            task.update(state: .completed)
            let entry = HistoryEntry(
                title: metadata.title ?? fileURL.lastPathComponent,
                sourceURL: task.request.url,
                fileURL: fileURL,
                format: task.request.audioFormat?.displayName ?? task.request.videoFormat?.displayName ?? "original",
                downloadedAt: Date()
            )
            try await historyStore.add(entry)
        } catch let error as DownloadError {
            switch error {
            case .botDetected:
                task.update(state: .pausedForUserAction(reason: error.localizedDescription))
            case .cancelled:
                task.update(state: .cancelled)
            default:
                task.update(state: .failed(reason: error.localizedDescription))
            }
        } catch is CancellationError {
            task.update(state: .cancelled)
        } catch {
            task.update(state: .failed(reason: error.localizedDescription))
        }
    }
}
