import AppKit
import Foundation

final class OpenFileAppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        NotificationCenter.default.post(
            name: .justPlayOpenURLs,
            object: nil,
            userInfo: ["urls": urls]
        )
    }
}

extension Notification.Name {
    static let justPlayOpenURLs = Notification.Name("justPlayOpenURLs")
}
