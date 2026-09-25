import Foundation

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
        progress = newProgress
    }

    func update(metadata newMetadata: OutputParser.Metadata) {
        metadata = newMetadata
    }
}
