import XCTest
@testable import ForgeKit

final class OutputParserPostprocessTests: XCTestCase {
    let parser = OutputParser()

    func testParsePostprocessStartedEvent() throws {
        let event = try XCTUnwrap(parser.parsePostprocessEvent(line: "POST|started|ExtractAudio"))
        XCTAssertEqual(event.status, "started")
        XCTAssertEqual(event.postprocessor, "ExtractAudio")
        XCTAssertFalse(event.isFinished)
    }

    func testParsePostprocessFinishedEventWithoutProcessor() throws {
        let event = try XCTUnwrap(parser.parsePostprocessEvent(line: "POST|finished|NA"))
        XCTAssertTrue(event.isFinished)
        XCTAssertNil(event.postprocessor)
    }

    func testParsePostprocessIgnoresOtherLines() {
        XCTAssertNil(parser.parsePostprocessEvent(line: "PROG|1024|223779|NA|5518496.89"))
        XCTAssertNil(parser.parsePostprocessEvent(line: "[ExtractAudio] Destination: /tmp/x.mp3"))
        XCTAssertNil(parser.parsePostprocessEvent(line: "POST|bogus|ExtractAudio"))
    }

    func testProgressTemplateArgumentsCoverBothStages() {
        // Both templates must be passed as separate --progress-template
        // flags; a single combined value would be treated as the URL.
        let args = OutputParser.progressTemplateArguments + OutputParser.postprocessTemplateArguments
        XCTAssertEqual(args.filter { $0 == "--progress-template" }.count, 2)
        XCTAssertTrue(OutputParser.postprocessTemplate.hasPrefix("postprocess:"))
    }
}
