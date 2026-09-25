import XCTest
@testable import ForgeKit

final class OutputParserTests: XCTestCase {
    let parser = OutputParser()

    func testParseProgressFromStandardLine() throws {
        let line = "[download]  42.5% of ~ 10.00MiB at 1.50MiB/s ETA 00:03"
        let progress = try XCTUnwrap(parser.parseProgress(line: line))
        XCTAssertEqual(progress.fraction, 0.425, accuracy: 0.001)
        XCTAssertEqual(progress.totalBytes ?? 0, 1_024 * 1_024 * 10, accuracy: 2)
        XCTAssertEqual(progress.speedBytesPerSecond ?? 0, 1_024 * 1_024 * 1.5, accuracy: 200)
    }

    func testParseProgressIgnoresNonProgressLines() {
        XCTAssertNil(parser.parseProgress(line: "[youtube] Extracting URL"))
        XCTAssertNil(parser.parseProgress(line: "ERROR: something went wrong"))
    }

    func testParseMetadataDecodesTitle() throws {
        let json = #"{"id":"abc","title":"Test Video","duration":123.5,"webpage_url":"https://example.com/watch?v=abc"}"#
        let metadata = try parser.parseMetadata(fromJSON: Data(json.utf8))
        XCTAssertEqual(metadata.title, "Test Video")
        XCTAssertEqual(metadata.duration, 123.5)
        XCTAssertEqual(metadata.webpageURL, "https://example.com/watch?v=abc")
    }
}
