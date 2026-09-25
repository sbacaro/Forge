import SwiftUI

/// Thin wrapper over ProgressView with consistent sizing and labeling
/// following HIG guidance for determinate progress.
struct ProgressBar: View {
    let fraction: Double
    var label: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(max(fraction, 0), 1))
                .progressViewStyle(.linear)
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}
