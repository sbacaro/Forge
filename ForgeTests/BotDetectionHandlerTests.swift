import XCTest
@testable import ForgeKit

final class BotDetectionHandlerTests: XCTestCase {
    let handler = BotDetectionHandler()

    func testDetectsBotChallenge() {
        let output = "ERROR: [youtube] abc: Sign in to confirm you're not a bot."
        XCTAssertEqual(handler.classify(output: output), .botChallenge)
    }

    func testDetectsRateLimit() {
        let output = "ERROR: HTTP Error 429: Too Many Requests"
        XCTAssertEqual(handler.classify(output: output), .rateLimited)
    }

    func testDetectsAccessDenied() {
        let output = "ERROR: unable to download video data: HTTP Error 403: Forbidden"
        XCTAssertEqual(handler.classify(output: output), .accessDenied)
    }

    func testNormalOutputIsNotFlagged() {
        XCTAssertNil(handler.classify(output: "[download] 100% of 10MiB"))
    }
}
