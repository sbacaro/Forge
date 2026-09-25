import SwiftUI

/// History of completed downloads, backed by `HistoryStore`.
struct HistoryView: View {
    @Environment(AppModel.self) private var appModel

    @State private var entries: [HistoryEntry] = []
    @State private var loadError: String?

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed downloads will appear here.")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        HistoryRow(entry: entry)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear All") {
                    clearAll()
                }
                .disabled(entries.isEmpty)
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
        .alert("Could not load history", isPresented: Binding(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    private func reload() async {
        do {
            entries = try await appModel.historyStore.entries()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        let removed = offsets.map { entries[$0] }
        entries.remove(atOffsets: offsets)
        Task {
            for entry in removed {
                try? await appModel.historyStore.remove(entry)
            }
        }
    }

    private func clearAll() {
        entries.removeAll()
        Task {
            try? await appModel.historyStore.clear()
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body)
                    .lineLimit(1)
                Text(entry.downloadedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.format)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(.quaternary))
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([entry.fileURL])
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help("Reveal in Finder")
        }
    }
}
