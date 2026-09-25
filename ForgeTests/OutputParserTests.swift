import XCTest
@testable import ForgeKit

final class OutputParserTests: XCTestCase {
    let parser = OutputParser()

    func testParseStructuredProgressLine() throws {
        let line = "PROG|1024|223779|223779|5518496.89"
        let progress = try XCTUnwrap(parser.parseStructuredProgress(line: line))
        XCTAssertEqual(progress.downloadedBytes, 1_024)
        XCTAssertEqual(progress.totalBytes, 223_779)
        XCTAssertEqual(progress.speedBytesPerSecond ?? 0, 5_518_496, accuracy: 1)
        XCTAssertEqual(progress.fraction ?? 0, 0.00457, accuracy: 0.0005)
    }

    func testParseStructuredProgressTreatsNAAsAbsent() throws {
        let line = "PROG|3072|252182|NA|NA"
        let progress = try XCTUnwrap(parser.parseStructuredProgress(line: line))
        XCTAssertEqual(progress.downloadedBytes, 3_072)
        XCTAssertEqual(progress.totalBytes, 252_182)
        XCTAssertNil(progress.speedBytesPerSecond)
        XCTAssertEqual(progress.fraction ?? 0, 3_072.0 / 252_182.0, accuracy: 0.0001)
    }

    func testParseLegacyProgressFromStandardLine() throws {
        let line = "[download]  42.5% of ~ 10.00MiB at 1.50MiB/s ETA 00:03"
        let progress = try XCTUnwrap(parser.parseLegacyProgress(line: line))
        XCTAssertEqual(progress.fraction ?? 0, 0.425, accuracy: 0.001)
        XCTAssertEqual(progress.totalBytes ?? 0, 1_024 * 1_024 * 10, accuracy: 2)
    }

    func testParseProgressIgnoresNonProgressLines() {
        XCTAssertNil(parser.parseStructuredProgress(line: "[youtube] Extracting URL"))
        XCTAssertNil(parser.parseStructuredProgress(line: "ERROR: something went wrong"))
    }

    func testParseMetadataDecodesTitle() throws {
        let json = #"{"id":"abc","title":"Test Video","duration":123.5,"webpage_url":"https://example.com/watch?v=abc"}"#
        let metadata = try parser.parseMetadata(fromJSON: Data(json.utf8))
        XCTAssertEqual(metadata.title, "Test Video")
        XCTAssertEqual(metadata.duration, 123.5)
        XCTAssertEqual(metadata.webpageURL, "https://example.com/watch?v=abc")
    }
}
