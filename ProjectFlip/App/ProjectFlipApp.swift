import SwiftUI

@main
struct ProjectFlipApp: App {
    @UIApplicationDelegateAdaptor(ProjectFlipAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--uitest-large-type") {
                RootView().dynamicTypeSize(.accessibility3).modifier(TestPresentation())
            } else {
                RootView().modifier(TestPresentation())
            }
            #else
            RootView()
            #endif
        }
    }
}

#if DEBUG
/// Presentation overrides for simulator QA; production always uses platform settings.
private struct TestPresentation: ViewModifier {
    func body(content: Content) -> some View {
        content.preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--uitest-dark") ? .dark : nil)
    }
}
#endif
