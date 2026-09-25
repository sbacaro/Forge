import Foundation

/// Aggregates byte-exact per-stream progress into one overall snapshot.
///
/// With "best" quality, yt-dlp downloads video and audio as separate
/// streams; each restarts at 0, which made the UI bar bounce. This
/// accumulator banks each finished stream's bytes so the reported byte
/// counts cover the whole job.
///
/// The overall total grows as stream sizes become known (video first, then
/// audio), so the fraction can legitimately dip — 100% of video-only is
/// about 47% of video+audio. `DownloadTask` clamps for display so the bar
/// stays visually monotonic while the bytes underneath stay exact.
final class ProgressAggregator: @unchecked Sendable {
    private let lock = NSLock()
    private var completedBytes: Double = 0
    private var currentStreamDownloadedBytes: Double = 0
    private var currentStreamTotalBytes: Double?

    /// Call when a new `[download] Destination:` line appears: banks the
    /// finished stream's bytes and starts counting the next stream.
    func beginNextStream() {
        lock.lock(); defer { lock.unlock() }
        completedBytes += currentStreamDownloadedBytes
        currentStreamDownloadedBytes = 0
        currentStreamTotalBytes = nil
    }

    /// Feed one parsed progress event; returns the aggregated snapshot.
    func update(with progress: OutputParser.Progress) -> OutputParser.Progress {
        lock.lock(); defer { lock.unlock() }
        if let downloaded = progress.downloadedBytes {
            currentStreamDownloadedBytes = downloaded
        }
        if let total = progress.totalBytes {
            currentStreamTotalBytes = total
        }

        let total = completedBytes + (currentStreamTotalBytes ?? 0)
        let downloaded = completedBytes + currentStreamDownloadedBytes

        guard total > 0 || downloaded > 0 else { return progress }
        return OutputParser.Progress(
            downloadedBytes: downloaded,
            totalBytes: total > 0 ? total : nil,
            speedBytesPerSecond: progress.speedBytesPerSecond
        )
    }
}
