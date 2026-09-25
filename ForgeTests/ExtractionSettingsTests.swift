import XCTest
@testable import ForgeKit

final class ExtractionSettingsTests: XCTestCase {
    func testBrowserCookiesProduceFlag() {
        var settings = ExtractionSettings()
        settings.cookieSource = .firefox
        let args = settings.extractionArguments()
        XCTAssertTrue(args.contains("--cookies-from-browser"))
        XCTAssertTrue(args.contains("firefox"))
    }

    func testNoneProducesNoCookieFlag() {
        let settings = ExtractionSettings(cookieSource: .none)
        let args = settings.extractionArguments()
        XCTAssertFalse(args.contains("--cookies-from-browser"))
        XCTAssertFalse(args.contains("--cookies"))
    }

    func testManualCookiesOverrideBrowser() {
        var settings = ExtractionSettings(cookieSource: .chrome)
        settings.customCookieFilePath = "/tmp/cookies.txt"
        let args = settings.extractionArguments()
        XCTAssertTrue(args.contains("--cookies"))
        XCTAssertTrue(args.contains("/tmp/cookies.txt"))
        XCTAssertFalse(args.contains("--cookies-from-browser"))
    }

    func testRateLimitFlagsPresent() {
        let settings = ExtractionSettings()
        let args = settings.extractionArguments()
        XCTAssertTrue(args.contains("--sleep-requests"))
        XCTAssertTrue(args.contains("--sleep-interval"))
        XCTAssertTrue(args.contains("--concurrent-fragments"))
    }

    func testProxyPassthrough() {
        var settings = ExtractionSettings()
        settings.proxyURL = "socks5://127.0.0.1:9050"
        let args = settings.extractionArguments()
        XCTAssertTrue(args.contains("--proxy"))
        XCTAssertTrue(args.contains("socks5://127.0.0.1:9050"))
    }
}
