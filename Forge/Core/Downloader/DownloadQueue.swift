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
    private let extractionSettings: ExtractionSettings
    private var drainTask: Task<Void, Never>?
    /// Swift task running each active download, keyed by task id. Cancelling
    /// it propagates into `ProcessEngine`, which terminates the subprocess.
    private var runningTasks: [UUID: Task<Void, Never>] = [:]

    init(
        downloader: VideoDownloader = YtDlpDownloader(),
        throttle: RateThrottle = RateThrottle(),
        historyStore: HistoryStore = JSONHistoryStore(),
        extractionSettings: ExtractionSettings = ExtractionSettings()
    ) {
        self.downloader = downloader
        self.throttle = throttle
        self.historyStore = historyStore
        self.extractionSettings = extractionSettings
    }

    var activeTask: DownloadTask? {
        tasks.first { $0.state.isActive }
    }

    func enqueue(_ request: DownloadRequest) {
        tasks.append(DownloadTask(request: request))
        startIfIdle()
    }

    /// Cancels a task. For queued tasks this marks them immediately; for the
    /// running task it cancels the Swift task, which terminates the yt-dlp
    /// subprocess and flows back through the error handling below.
    func cancel(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        switch task.state {
        case .queued:
            task.update(state: .cancelled)
        case .fetchingMetadata, .downloading, .converting:
            task.isCancelling = true
            runningTasks[id]?.cancel()
        default:
            break
        }
    }

    func cancelAll() {
        for task in tasks where task.state.isActive {
            cancel(task.id)
        }
    }

    func clearFinished() {
        tasks.removeAll { $0.isTerminal }
    }

    func dismissUserActionMessages() {
        for task in tasks where task.userActionMessage != nil {
            task.userActionMessage = nil
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
            guard !next.isTerminal else { continue }
            await run(next)
        }
    }

    private func firstQueued() -> DownloadTask? {
        tasks.first { !$0.isTerminal && $0.state == .queued }
    }

    private func run(_ task: DownloadTask) async {
        let work = Task<Void, Never> { [weak self] in
            await self?.perform(task)
        }
        runningTasks[task.id] = work
        await work.value
        runningTasks[task.id] = nil
    }

    private func perform(_ task: DownloadTask) async {
        task.update(state: .fetchingMetadata)
        do {
            // Resolve the user's extraction settings on the main actor and
            // snapshot the flags into a Sendable profile for background work.
            let profile = ResolvedExtractionProfile(arguments: extractionSettings.extractionArguments())
            let metadata = try await downloader.fetchMetadata(for: task.request.url, using: profile)
            task.update(metadata: metadata)
            task.update(state: .downloading)

            let fileURL = try await downloader.download(
                task.request,
                using: profile,
                onProgress: { progress in
                    // The streaming callback runs on a background queue; hop
                    // to the main actor instead of assuming we're already there.
                    Task { @MainActor in
                        task.update(progress: progress)
                    }
                },
                onPostprocess: { event in
                    Task { @MainActor in
                        task.update(postprocess: event)
                    }
                }
            )
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
            if task.isCancelling || Task.isCancelled {
                task.update(state: .cancelled)
            } else {
                task.update(state: .failed(reason: error.localizedDescription))
            }
        }
    }
}
