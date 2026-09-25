import AppKit
import Foundation

/// Watches the system pasteboard for media URLs the user copies and
/// exposes the most recent one for one-click download.
@MainActor
@Observable
final class ClipboardMonitor {
    /// Most recent valid media URL copied anywhere in the system.
    private(set) var detectedURL: URL?

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private var isEnabled = false

    var isRunning: Bool { isEnabled }

    func start() {
        guard !isEnabled else { return }
        lastChangeCount = pasteboard.changeCount
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isEnabled = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isEnabled = false
    }

    /// Clears the pending suggestion after the user acts on it.
    func consume() {
        detectedURL = nil
    }

    private func poll() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        guard let raw = pasteboard.string(forType: .string) else { return }
        let candidate = trimmed(raw)
        guard let url = URL(string: candidate),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return }
        detectedURL = url
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
