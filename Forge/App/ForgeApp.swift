import SwiftUI

@main
struct ForgeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appModel)
                .frame(
                    minWidth: AppConstants.windowMinSize.width,
                    minHeight: AppConstants.windowMinSize.height
                )
        }
        .windowStyle(.automatic)
        .defaultSize(
            width: AppConstants.windowDefaultSize.width,
            height: AppConstants.windowDefaultSize.height
        )

        Settings {
            SettingsView()
                .environment(appModel)
        }
    }
}
