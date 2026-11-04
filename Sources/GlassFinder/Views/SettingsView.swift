import SwiftUI
import GlassFinderCore

@MainActor
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable Glass Folder", isOn: $model.preferences.isEnabled)
                Picker("Folder Size", selection: $model.preferences.folderSize) {
                    ForEach(FolderSize.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show previews on hover", isOn: $model.preferences.hoverPreviews)
                Stepper("Maximum Preview Items: \(model.preferences.previewCount)", value: $model.preferences.previewCount, in: 1...10)
                slider("Animation speed", value: $model.preferences.animationSpeed, range: 0.5...2)
                slider("Animation intensity", value: $model.preferences.animationIntensity, range: 0...1.5)
                Toggle("Reduce motion", isOn: $model.preferences.reduceMotion)
                Text("System Reduce Motion and Reduce Transparency are always respected.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Appearance") { AppearanceSettingsView() }
            Section("System") {
                Toggle("Launch at Login", isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                Text(model.loginStatus).font(.caption).foregroundStyle(.secondary)
                Toggle("Global toggle shortcut", isOn: $model.preferences.globalShortcut)
                Text(model.shortcutStatus).font(.caption).foregroundStyle(.secondary)
            }
            Section("Integration status") {
                LabeledContent("Desktop") { Text(IntegrationStatus.desktop).frame(maxWidth: 330, alignment: .leading) }
                LabeledContent("Finder") { Text(IntegrationStatus.finder).frame(maxWidth: 330, alignment: .leading) }
            }
            Section {
                Button("Reset Appearance and Shortcut Preferences") { model.resetPreferences() }
                Text("Saved folders and Launch at Login are retained.").font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).frame(width: 660, height: 800)
            .onAppear { model.updateLoginStatus() }
            .alert("Glass Folder", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
                Button("OK") { model.error = nil }
            } message: { Text(model.error ?? "") }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        LabeledContent(title) {
            Slider(value: value, in: range).frame(width: 200)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit().frame(width: 40)
        }
    }
}
