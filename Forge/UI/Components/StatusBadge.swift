import SwiftUI

/// Small pill showing the state of a download task, using semantic system
/// colors per HIG.
struct StatusBadge: View {
    let state: TaskState

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundStyle(color)
    }

    private var text: String {
        switch state {
        case .queued: "Queued"
        case .fetchingMetadata: "Fetching"
        case .downloading: "Downloading"
        case .converting: "Converting"
        case .completed: "Done"
        case .failed: "Failed"
        case .pausedForUserAction: "Action needed"
        case .cancelled: "Cancelled"
        }
    }

    private var color: Color {
        switch state {
        case .queued: .secondary
        case .fetchingMetadata, .downloading, .converting: .blue
        case .completed: .green
        case .failed: .red
        case .pausedForUserAction: .orange
        case .cancelled: .secondary
        }
    }
}
