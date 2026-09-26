import XCTest
@testable import ForgeKit

/// Regression test for a pipe-handling deadlock: `run` used to read stdout
/// to EOF before draining stderr. A child writing more than the 64 KiB OS
/// pipe buffer to stderr while stdout was still open blocked forever, and
/// `fetchMetadata` hung on "Fetching" indefinitely.
final class ProcessEngineDeadlockTests: XCTestCase {
    func testRunCompletesWhenChildWritesLargeOutputToBothPipes() async throws {
        guard let sh = URL(string: "file:///bin/sh") else {
            throw XCTSkip("no /bin/sh")
        }
        let engine = ProcessEngine()
        // 200 KiB on each stream: far above the 64 KiB pipe buffer, on both
        // sides, so only a concurrent drain finishes.
        let script = "python3 -c \"import sys; sys.stderr.write('E'*200000); sys.stdout.write('O'*200000)\""
        let result = try await engine.run(tool: sh, arguments: ["-c", script], environment: [:])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput.count, 200_000)
        XCTAssertEqual(result.standardError.count, 200_000)
    }

    func testRunCompletesWhenChildWritesLargeStderrOnly() async throws {
        let engine = ProcessEngine()
        let script = "python3 -c \"import sys; sys.stderr.write('E'*200000)\""
        let result = try await engine.run(
            tool: URL(string: "file:///bin/sh")!,
            arguments: ["-c", script],
            environment: [:]
        )
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardError.count, 200_000)
    }
}
