import Foundation

/// Observable state for a single download task, suitable for direct
/// binding from SwiftUI views.
@MainActor
@Observable
final class DownloadTask: Identifiable {
    nonisolated let id: UUID
    let request: DownloadRequest
    private(set) var state: TaskState
    private(set) var progress: OutputParser.Progress?
    private(set) var metadata: OutputParser.Metadata?

    /// True between the user pressing Cancel and the subprocess actually
    /// terminating; lets the UI show a "Cancelling…" state on the button.
    var isCancelling = false

    /// Alert to show when the task needs the user to act (e.g. bot check).
    var userActionMessage: String?

    init(request: DownloadRequest) {
        self.request = request
        id = request.id
        state = .queued
    }

    var isTerminal: Bool {
        switch state {
        case .completed, .failed, .cancelled: true
        default: false
        }
    }

    func update(state newState: TaskState) {
        state = newState
        if !newState.isActive {
            isCancelling = false
        }
        switch newState {
        case let .pausedForUserAction(reason):
            userActionMessage = reason
        case .completed, .failed, .cancelled:
            if case .failed = newState {} else { userActionMessage = nil }
        default:
            break
        }
    }

    func update(progress newProgress: OutputParser.Progress) {
        // Byte counts stay exact; the displayed fraction is clamped so the
        // bar never regresses when the overall total grows (video stream
        // finishing makes the total jump when the audio size becomes known).
        if let fraction = newProgress.fraction {
            highestDisplayedFraction = max(highestDisplayedFraction, fraction)
        }
        progress = newProgress
    }

    /// Called when yt-dlp enters or leaves a postprocessing step
    /// (ExtractAudio, EmbedThumbnail, MoveFiles…).
    func update(postprocess event: OutputParser.PostprocessEvent) {
        if event.isFinished {
            state = .converting(processor: nil)
        } else {
            state = .converting(processor: event.postprocessor)
        }
    }

    /// Display fraction: byte-exact but clamped to never regress.
    var displayFraction: Double? {
        guard let fraction = progress?.fraction else { return nil }
        return max(highestDisplayedFraction, fraction)
    }

    @ObservationIgnored private var highestDisplayedFraction: Double = 0

    func update(metadata newMetadata: OutputParser.Metadata) {
        metadata = newMetadata
    }
}
