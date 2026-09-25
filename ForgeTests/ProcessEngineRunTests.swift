import XCTest
@testable import ForgeKit

final class ProcessEngineRunTests: XCTestCase {
    /// `run` must capture full stdout even for large payloads like
    /// `yt-dlp -J`, and surface stderr on failure — the real
    /// metadata-fetch path.
    func testRunCapturesLargeStdoutAndStderr() async throws {
        guard let ytDlp = BundleToolLocator().url(forTool: .ytDlp) else {
            throw XCTSkip("yt-dlp not available")
        }
        let engine = ProcessEngine()
        let result = try await engine.run(
            tool: ytDlp,
            arguments: ["-J", "--no-warnings", "https://www.youtube.com/watch?v=jNQXAC9IVRw"],
            environment: [:]
        )
        XCTAssertEqual(result.exitCode, 0, "stderr was: \(result.standardError.prefix(500))")
        XCTAssertTrue(result.standardOutput.contains("\"title\""), "stdout had no metadata JSON")
    }

    /// The extraction profile must only emit flags yt-dlp actually accepts;
    /// an unknown flag aborts every download with exit code 2.
    func testProfileArgumentsAreAcceptedByYtDlp() async throws {
        guard let ytDlp = BundleToolLocator().url(forTool: .ytDlp) else {
            throw XCTSkip("yt-dlp not available")
        }
        let profile = DefaultExtractionProfile(settings: ExtractionSettings())
        let engine = ProcessEngine()
        let result = try await engine.run(
            tool: ytDlp,
            arguments: ["--version"] + profile.arguments(),
            environment: [:]
        )
        XCTAssertEqual(result.exitCode, 0, "profile emitted an invalid flag. stderr: \(result.standardError)")
    }
}
