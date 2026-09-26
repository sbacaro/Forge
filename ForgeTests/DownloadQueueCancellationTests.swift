import XCTest
@testable import ForgeKit

/// Cancellation behaviour of the serial download queue.
final class DownloadQueueCancellationTests: XCTestCase {
    /// Cancelling a queued task before the drain loop reaches it must mark
    /// it cancelled without running any subprocess.
    @MainActor
    func testCancelQueuedTaskMarksItCancelled() async {
        let queue = DownloadQueue(
            downloader: StubDownloader(),
            throttle: RateThrottle(minimumGap: 60)
        )
        queue.enqueue(Self.makeRequest())
        queue.enqueue(Self.makeRequest())

        guard let second = queue.tasks.last else {
            return XCTFail("expected two queued tasks")
        }
        queue.cancel(second.id)

        // The running task occupies the queue; the queued one is cancelled.
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(second.state, .cancelled)
        XCTAssertFalse(second.state.isActive)
    }

    /// Cancelling the active task must terminate the subprocess and flip the
    /// task to .cancelled (not .failed) once the downloader unwinds.
    @MainActor
    func testCancelRunningTaskTerminatesAndMarksCancelled() async {
        let queue = DownloadQueue(
            downloader: StubDownloader(delay: .seconds(30)),
            throttle: RateThrottle(minimumGap: 0)
        )
        queue.enqueue(Self.makeRequest())

        let task = try! XCTUnwrap(queue.tasks.first)
        // Give the drain loop a moment to pick the task up and start it.
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard task.state.isActive else {
            return XCTFail("task should be active before cancellation, was \(task.state)")
        }

        queue.cancel(task.id)
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(task.state, .cancelled, "cancelled download must end as .cancelled")
    }

    private static func makeRequest() -> DownloadRequest {
        DownloadRequest(
            url: URL(string: "https://example.com/video")!,
            audioFormat: .mp3,
            outputDirectory: FileManager.default.temporaryDirectory
        )
    }
}

/// Minimal downloader stub: never touches the network, just blocks for
/// `delay` inside download() and reacts to task cancellation like the real
/// ProcessEngine path does (throws CancellationError).
private final class StubDownloader: VideoDownloader, @unchecked Sendable {
    let delay: Duration

    init(delay: Duration = .seconds(5)) {
        self.delay = delay
    }

    func fetchMetadata(
        for url: URL,
        using profile: ExtractionProfile
    ) async throws -> OutputParser.Metadata {
        try await Task.sleep(for: delay)
        return OutputParser.Metadata(
            id: "stub",
            title: "Stub video",
            duration: nil,
            thumbnail: nil,
            uploader: nil,
            webpageURL: url.absoluteString
        )
    }

    func download(
        _ request: DownloadRequest,
        using profile: ExtractionProfile,
        onProgress: @escaping @Sendable (OutputParser.Progress) -> Void,
        onPostprocess: @escaping @Sendable (OutputParser.PostprocessEvent) -> Void
    ) async throws -> URL {
        try await Task.sleep(for: delay)
        return request.outputDirectory.appendingPathComponent("stub.mp3")
    }
}
