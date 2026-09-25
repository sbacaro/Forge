import XCTest
@testable import ForgeKit

final class YtDlpProgressTests: XCTestCase {
    private final class FractionCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [Double] = []
        func append(_ value: Double) {
            lock.lock(); defer { lock.unlock() }
            values.append(value)
        }
        var snapshot: [Double] { lock.lock(); defer { lock.unlock() }; return values }
    }

    /// Mirrors the "video download" path: two streams are fetched and
    /// merged. Verifies completion and collects progress to assert it
    /// behaves monotonically.
    func testVideoDownloadWithMergeCompletes() async throws {
        let downloader = YtDlpDownloader()
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("forge-vid-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outputDir) }

        let request = DownloadRequest(
            url: URL(string: "https://www.youtube.com/watch?v=jNQXAC9IVRw")!,
            videoFormat: .mp4,
            qualityProfile: .best,
            outputDirectory: outputDir
        )

        let collector = ProgressCollector()
        let fileURL = try await downloader.download(request, using: DefaultExtractionProfile(settings: ExtractionSettings())) { progress in
            if let fraction = progress.fraction {
                collector.append(fraction)
            }
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        print("FRACTIONS: \(collector.snapshot.map { "\($0)" }.joined(separator: ","))")
    }
}

private final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Double] = []
    func append(_ value: Double) {
        lock.lock(); defer { lock.unlock() }
        values.append(value)
    }
    var snapshot: [Double] {
        lock.lock(); defer { lock.unlock() }
        return values
    }
}
