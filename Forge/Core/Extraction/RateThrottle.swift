import Foundation

/// Applies human-like pacing between requests. Actual sleeps happen inside
/// yt-dlp via the flags in `ExtractionSettings`; this helper additionally
/// spaces out successive task submissions in the queue so we never burst.
actor RateThrottle {
    private let minimumGap: TimeInterval
    private var lastSubmission: Date?

    init(minimumGap: TimeInterval = AppConstants.ExtractionDefaults.sleepRequestsSeconds) {
        self.minimumGap = minimumGap
    }

    /// Waits as long as needed so that consecutive submissions are spaced out.
    func waitTurn() async {
        if let last = lastSubmission {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < minimumGap {
                let remaining = minimumGap - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }
        lastSubmission = Date()
    }
}
