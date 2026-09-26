import XCTest
@testable import ForgeKit

/// End-to-end test against a tiny public video. Skipped in CI by default
/// via environment; run explicitly when debugging download failures.
final class YtDlpDownloaderIntegrationTests: XCTestCase {
    func testRealDownloadProducesFile() async throws {
        let downloader = YtDlpDownloader()
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("forge-it-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outputDir) }

        let request = DownloadRequest(
            url: URL(string: "https://www.youtube.com/watch?v=jNQXAC9IVRw")!,
            audioFormat: .mp3,
            outputDirectory: outputDir
        )

        let fileURL = try await downloader.download(
            request,
            using: DefaultExtractionProfile(settings: ExtractionSettings()),
            onProgress: { _ in },
            onPostprocess: { _ in }
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
