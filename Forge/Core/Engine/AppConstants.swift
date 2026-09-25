import Foundation

/// Central place for app-level tunables. Nothing in Forge should hardcode
/// values that a maintainer might want to tweak: prefer adding entries here
/// or reading from user settings.
enum AppConstants {
    static let appName = "Forge"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    static let windowMinSize = CGSize(width: 720, height: 480)
    static let windowDefaultSize = CGSize(width: 1_080, height: 720)

    /// Subdirectory inside Application Support where Forge keeps its data.
    static let appSupportDirectoryName = "Forge"

    /// File name for the download history store.
    static let historyFileName = "history.json"

    /// Poll interval for reading incremental output from tool subprocesses.
    static let processReadInterval: TimeInterval = 0.1

    /// Conservative defaults for human-like extraction behaviour.
    /// All values are intentionally editable via Settings; these are only
    /// the initial defaults applied on first launch.
    enum ExtractionDefaults {
        static let sleepRequestsSeconds = 1.0
        static let sleepIntervalSeconds = 2.0
        static let maxSleepIntervalSeconds = 5.0
        static let concurrentFragments = 1
        static let limitRate: String? = nil
        static let acceptLanguage = "en-US,en;q=0.9"
    }
}
