import SwiftUI

/// Queue view: URL entry, format pickers and live task list with progress
/// and bot-detection alerts.
struct DownloadView: View {
    @Environment(AppModel.self) private var appModel

    @State private var urlString = ""
    @State private var isAudioOutput = true

    var body: some View {
        VStack(spacing: 0) {
            urlEntrySection
            Divider()
            queueHeader
            Divider()
            taskList
        }
        .navigationTitle("Downloads")
        .onAppear { appModel.clipboardMonitor.start() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "arrow.down.to.line") {
                    submit()
                }
                .disabled(!isValidURL)
                .keyboardShortcut(.defaultAction)
            }
        }
        .alert(
            "Action needed",
            isPresented: Binding(
                get: { appModel.downloadQueue.tasks.contains { $0.userActionMessage != nil } },
                set: { if !$0 { appModel.downloadQueue.dismissUserActionMessages() } }
            ),
            presenting: appModel.downloadQueue.tasks.first { $0.userActionMessage != nil }
        ) { task in
            Button("Open Settings") {
                appModel.requestSettingsPresentation()
            }
            Button("OK", role: .cancel) {}
        } message: { task in
            Text(task.userActionMessage ?? "")
        }
    }

    private var isValidURL: Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else { return false }
        return url.scheme?.hasPrefix("http") == true && url.host != nil
    }

    private var urlEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(text: $urlString) {
                Text("Paste a video or audio URL")
            }
            .textFieldStyle(.roundedBorder)

            Picker("Output", selection: $isAudioOutput) {
                Text("Audio").tag(true)
                Text("Video").tag(false)
            }
            .pickerStyle(.segmented)

            if isAudioOutput {
                Picker("Audio format", selection: Binding(
                    get: { appModel.lastSelectedAudioFormat },
                    set: { appModel.lastSelectedAudioFormat = $0 }
                )) {
                    ForEach(AudioFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            } else {
                Picker("Video format", selection: Binding(
                    get: { appModel.lastSelectedVideoFormat },
                    set: { appModel.lastSelectedVideoFormat = $0 }
                )) {
                    ForEach(VideoFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }

            Picker("Quality", selection: Binding(
                get: { appModel.lastSelectedQuality },
                set: { appModel.lastSelectedQuality = $0 }
            )) {
                ForEach(QualityProfile.allCases) { profile in
                    Text(profile.displayName).tag(profile)
                }
            }

            Picker("Playlist", selection: Binding(
                get: { appModel.lastSelectedPlaylistScope },
                set: { appModel.lastSelectedPlaylistScope = $0 }
            )) {
                ForEach(PlaylistScope.allCases) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }

            Toggle("Embed thumbnail and metadata", isOn: Binding(
                get: { appModel.embedMetadata },
                set: { appModel.embedMetadata = $0 }
            ))
            Toggle("Download subtitles", isOn: Binding(
                get: { appModel.downloadSubtitles },
                set: { appModel.downloadSubtitles = $0 }
            ))

            HStack {
                Image(systemName: "folder")
                Text(self.appModel.outputDirectory.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Choose…") { chooseOutputDirectory() }
            }
            .font(.callout)
        }
        .padding()
    }

    private var queueHeader: some View {
        HStack {
            Text("Queue")
                .font(.headline)
            Spacer()
            Button("Clear finished") {
                appModel.downloadQueue.clearFinished()
            }
            .disabled(!appModel.downloadQueue.tasks.contains { $0.isTerminal })
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var taskList: some View {
        List(appModel.downloadQueue.tasks) { task in
            TaskRow(task: task)
        }
        .listStyle(.inset)
        .overlay {
            if appModel.downloadQueue.tasks.isEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let url = appModel.clipboardMonitor.detectedURL {
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Found a URL in your clipboard")
                    .font(.headline)
                Button("Download from \(url.host() ?? "link")") {
                    urlString = url.absoluteString
                    submit()
                    appModel.clipboardMonitor.consume()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                "No downloads",
                systemImage: "arrow.down.circle",
                description: Text("Paste a URL above and press Add to get started.")
            )
        }
    }

    private func submit() {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else { return }
        let subtitleOptions: SubtitleOptions = appModel.downloadSubtitles
            ? SubtitleOptions(
                enabled: true,
                languages: appModel.subtitleLanguages
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty },
                embed: true
            )
            : .disabled
        let request = DownloadRequest(
            url: url,
            audioFormat: isAudioOutput ? appModel.lastSelectedAudioFormat : nil,
            videoFormat: isAudioOutput ? nil : appModel.lastSelectedVideoFormat,
            qualityProfile: appModel.lastSelectedQuality,
            outputDirectory: appModel.outputDirectory,
            playlistScope: appModel.lastSelectedPlaylistScope,
            subtitleOptions: subtitleOptions,
            embedThumbnail: appModel.embedMetadata,
            embedMetadata: appModel.embedMetadata
        )
        appModel.downloadQueue.enqueue(request)
        urlString = ""
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = appModel.outputDirectory
        panel.begin { response in
            if response == .OK, let url = panel.url {
                appModel.outputDirectory = url
            }
        }
    }
}

private struct TaskRow: View {
    let task: DownloadTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.metadata?.title ?? task.request.url.absoluteString)
                        .font(.body)
                        .lineLimit(1)
                    Text(task.request.url.host() ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(state: task.state)
            }
            if let progress = task.progress {
                ProgressBar(fraction: progress.fraction, label: label(for: progress))
            }
        }
        .padding(.vertical, 4)
    }

    private func label(for progress: OutputParser.Progress) -> String? {
        guard progress.fraction > 0 else { return nil }
        return "\(Int((progress.fraction * 100).rounded()))%"
    }
}
