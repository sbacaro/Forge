import SwiftUI

/// Conversion-only view: pick local media files and convert them with the
/// bundled FFmpeg into any supported audio or video format.
struct ConvertView: View {
    @Environment(AppModel.self) private var appModel

    @State private var sourceURL: URL?
    @State private var selectedAudioFormat: AudioFormat = .flac
    @State private var isConverting = false
    @State private var resultMessage: String?
    @State private var isError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sourceRow
            Picker("Format", selection: $selectedFormat) {
                ForEach(AudioFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Convert") { convert() }
                    .disabled(sourceURL == nil || isConverting)
                if isConverting {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
            }
            if let resultMessage {
                Text(resultMessage)
                    .font(.callout)
                    .foregroundStyle(isError ? .red : .green)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Convert")
    }

    @State private var selectedFormat: AudioFormat = .flac

    private var sourceRow: some View {
        HStack {
            Button("Choose file…") { chooseSource() }
            Text(sourceURL?.lastPathComponent ?? "No file selected")
                .foregroundStyle(sourceURL == nil ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func chooseSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio, .movie]
        panel.begin { response in
            if response == .OK {
                sourceURL = panel.url
            }
        }
    }

    private func convert() {
        guard let source = sourceURL else { return }
        isConverting = true
        resultMessage = nil
        Task {
            let converter = FFmpegConverter()
            let job = ConversionJob(
                sourceURL: source,
                destinationURL: source.deletingLastPathComponent().appendingPathComponent(
                    source.deletingPathExtension().lastPathComponent
                ),
                settings: .losslessDefaults
            )
            do {
                let output = try await converter.convert(job, to: selectedFormat)
                resultMessage = "Saved to \(output.lastPathComponent)"
                isError = false
            } catch {
                resultMessage = error.localizedDescription
                isError = true
            }
            isConverting = false
        }
    }
}
