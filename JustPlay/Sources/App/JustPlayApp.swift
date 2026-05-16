import SwiftUI

@main
struct JustPlayApp: App {
    @NSApplicationDelegateAdaptor(OpenFileAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("JustPlay", systemImage: "play.rectangle.on.rectangle") {
            MenuBarRootView(model: model)
        }

        Settings {
            EmptyView()
        }
    }
}
