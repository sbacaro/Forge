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
            GeneralSettingsForm()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 480, height: 360)
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
