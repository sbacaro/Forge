import SwiftUI

/// Root split view following macOS 27 HIG: edge-to-edge sidebar, uniform
/// toolbar, Liquid Glass materials.
struct MainView: View {
    @Environment(AppModel.self) private var appModel

    enum Section: String, CaseIterable, Identifiable {
        case downloads
        case history

        var id: Self { self }

        var title: String {
            switch self {
            case .downloads: "Downloads"
            case .history: "History"
            }
        }

        var systemImage: String {
            switch self {
            case .downloads: "arrow.down.circle"
            case .history: "clock.arrow.circlepath"
            }
        }
    }

    @State private var selection: Section = .downloads

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Section.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
        } detail: {
            switch selection {
            case .downloads: DownloadView()
            case .history: HistoryView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    selection = .downloads
                } label: {
                    Label("New Download", systemImage: "plus")
                }
                .keyboardShortcut("n")
            }
        }
    }
}
