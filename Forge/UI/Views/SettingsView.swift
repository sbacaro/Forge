import SwiftUI

/// Settings window with an Extraction tab for gatekeeper avoidance options
/// (cookies, identity, rate limiting) — all editable, no hardcoded values.
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView {
            ExtractionSettingsForm()
                .tabItem {
                    Label("Extraction", systemImage: "shield.lefthalf.filled")
                }
            AudioQualityForm()
                .tabItem {
                    Label("Audio Quality", systemImage: "waveform")
                }
            GeneralSettingsForm()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 480, height: 420)
    }
}

private struct ExtractionSettingsForm: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var settings = appModel.extractionSettings

        Form {
            Picker("Cookies from browser", selection: $settings.cookieSource) {
                ForEach(CookieSource.allCases) { source in
                    Text(source.displayName).tag(source)
                }
            }

            TextField("Custom cookies.txt path", text: Binding(
                get: { settings.customCookieFilePath ?? "" },
                set: { settings.customCookieFilePath = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Custom user agent", text: Binding(
                get: { settings.customUserAgent ?? "" },
                set: { settings.customUserAgent = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Accept language", text: $settings.acceptLanguage)
                .textFieldStyle(.roundedBorder)

            TextField(
                "Sleep between requests (s)",
                value: $settings.sleepRequestsSeconds,
                format: .number
            )

            TextField("Rate limit (e.g. 2M, blank = none)", text: Binding(
                get: { settings.limitRate ?? "" },
                set: { settings.limitRate = $0.isEmpty ? nil : $0 }
            ))

            TextField("Proxy (e.g. socks5://host:port, blank = none)", text: Binding(
                get: { settings.proxyURL ?? "" },
                set: { settings.proxyURL = $0.isEmpty ? nil : $0 }
            ))
        }
        .padding()
    }
}

private struct AudioQualityForm: View {
    @Environment(AppModel.self) private var appModel

    @State private var audioBitrateKbps: Int
    @State private var sampleRateHz: Int

    private let bitrateOptions = [128, 192, 256, 320]
    private let sampleRates = [
        (44_100, "44.1 kHz (CD)"),
        (48_000, "48 kHz"),
        (88_200, "88.2 kHz"),
        (96_000, "96 kHz"),
        (192_000, "192 kHz"),
    ]

    init() {
        let storedBitrate = UserDefaults.standard.integer(forKey: "audioBitrateKbps")
        audioBitrateKbps = storedBitrate == 0 ? 320 : storedBitrate
        let storedRate = UserDefaults.standard.integer(forKey: "sampleRateHz")
        sampleRateHz = storedRate == 0 ? 48_000 : storedRate
    }

    var body: some View {
        Form {
            Picker("MP3 bitrate", selection: $audioBitrateKbps) {
                ForEach(bitrateOptions, id: \.self) { option in
                    Text("\(option) kbps").tag(option)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sample rate", selection: $sampleRateHz) {
                ForEach(sampleRates, id: \.0) { rate, label in
                    Text(label).tag(rate)
                }
            }

            Text("Applies to lossy formats (MP3) and resampling. Lossless formats keep the source quality.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .onDisappear {
            UserDefaults.standard.set(audioBitrateKbps, forKey: "audioBitrateKbps")
            UserDefaults.standard.set(sampleRateHz, forKey: "sampleRateHz")
        }
    }
}

private struct GeneralSettingsForm: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Form {
            LabeledContent("Output folder") {
                Text(appModel.outputDirectory.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            appModel.outputDirectory = url
                        }
                    }
                }
            }
        }
        .padding()
    }
}
