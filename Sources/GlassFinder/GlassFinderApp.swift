import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: AppModel?
    func applicationWillTerminate(_ notification: Notification) { model?.shutdown() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@main
@MainActor
struct GlassFolderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Glass Folder", id: "browser") {
            BrowserView().environmentObject(model).environmentObject(model.backgrounds)
                .onAppear { delegate.model = model }
        }
        .defaultSize(width: 820, height: 580)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Glass Folder") { NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Glass Folder"]) }
            }
            CommandGroup(after: .newItem) {
                Button("Add Folders…") { model.chooseFolders() }.keyboardShortcut("o")
                Toggle("Enable Glass Folder", isOn: $model.preferences.isEnabled)
            }
        }
        Settings { SettingsView().environmentObject(model).environmentObject(model.backgrounds) }
        MenuBarExtra("Glass Folder", systemImage: model.preferences.isEnabled ? "folder.fill" : "folder") {
            MenuControls().environmentObject(model)
        }
    }
}

@MainActor
private struct MenuControls: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        Toggle("Enable Glass Folder", isOn: $model.preferences.isEnabled)
        Divider()
        Button("Show Glass Folder") { openWindow(id: "browser"); NSApp.activate(ignoringOtherApps: true) }
        Button("Add Folders…") { NSApp.activate(ignoringOtherApps: true); model.chooseFolders() }
        Button("Settings…") { NSApp.activate(ignoringOtherApps: true); openSettings() }
        Divider()
        Text("Desktop / Finder overlays: not active")
        Button("Quit Glass Folder") { model.shutdown(); NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
