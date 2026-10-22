import SwiftUI

@main
struct ProjectFlipApp: App {
    @UIApplicationDelegateAdaptor(ProjectFlipAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--uitest-large-type") {
                    RootView().dynamicTypeSize(.accessibility3)
                } else { RootView() }
                #else
                RootView()
                #endif
            }.modifier(GameTheme())
        }
    }
}
