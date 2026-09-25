import Foundation

/// User-editable extraction settings that together define how Forge
/// presents itself to sites. Persisted via `UserDefaults`.
@Observable
final class ExtractionSettings {
    var cookieSource: CookieSource
    var customCookieFilePath: String?
    var customUserAgent: String?
    var acceptLanguage: String
    var sleepRequestsSeconds: Double
    var sleepIntervalSeconds: Double
    var maxSleepIntervalSeconds: Double
    var concurrentFragments: Int
    var limitRate: String?
    var customHeaders: [String]
    var proxyURL: String?

    init(
        cookieSource: CookieSource = .none,
        customCookieFilePath: String? = nil,
        customUserAgent: String? = nil,
        acceptLanguage: String = AppConstants.ExtractionDefaults.acceptLanguage,
        sleepRequestsSeconds: Double = AppConstants.ExtractionDefaults.sleepRequestsSeconds,
        sleepIntervalSeconds: Double = AppConstants.ExtractionDefaults.sleepIntervalSeconds,
        maxSleepIntervalSeconds: Double = AppConstants.ExtractionDefaults.maxSleepIntervalSeconds,
        concurrentFragments: Int = AppConstants.ExtractionDefaults.concurrentFragments,
        limitRate: String? = AppConstants.ExtractionDefaults.limitRate,
        customHeaders: [String] = [],
        proxyURL: String? = nil
    ) {
        self.cookieSource = cookieSource
        self.customCookieFilePath = customCookieFilePath
        self.customUserAgent = customUserAgent
        self.acceptLanguage = acceptLanguage
        self.sleepRequestsSeconds = sleepRequestsSeconds
        self.sleepIntervalSeconds = sleepIntervalSeconds
        self.maxSleepIntervalSeconds = maxSleepIntervalSeconds
        self.concurrentFragments = concurrentFragments
        self.limitRate = limitRate
        self.customHeaders = customHeaders
        self.proxyURL = proxyURL
    }

    func extractionArguments() -> [String] {
        var args: [String] = []

        if let manualCookies = customCookieFilePath, !manualCookies.isEmpty {
            args += ["--cookies", manualCookies]
        } else if let browserCookies = cookieSource.ytDlpName {
            args += ["--cookies-from-browser", browserCookies]
        }

        if let userAgent = customUserAgent, !userAgent.isEmpty {
            args += ["--user-agent", userAgent]
        }

        if !acceptLanguage.isEmpty {
            args += ["--accept-language", acceptLanguage]
        }

        for header in customHeaders where !header.isEmpty {
            args += ["--add-headers", header]
        }

        args += [
            "--sleep-requests", String(sleepRequestsSeconds),
            "--sleep-interval", String(sleepIntervalSeconds),
            "--max-sleep-interval", String(maxSleepIntervalSeconds),
            "--concurrent-fragments", String(concurrentFragments),
        ]

        if let rate = limitRate, !limitRate!.isEmpty {
            args += ["--limit-rate", limitRate!]
        }

        if let proxy = proxyURL, !proxy.isEmpty {
            args += ["--proxy", proxy]
        }

        return args
    }
}
