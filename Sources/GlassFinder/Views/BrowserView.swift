import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct BrowserView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings
    @FocusState private var focused: Bool
    private let columns = [GridItem(.adaptive(minimum: 218), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill").foregroundStyle(.cyan)
                Text("GlassFinder").font(.title2.weight(.semibold))
                Spacer()
                Toggle("Glass effects", isOn: $model.preferences.isEnabled).toggleStyle(.switch)
            }.padding(20)
            Divider()
            ScrollView {
                if model.folders.isEmpty {
                    ContentUnavailableView {
                        Label("Your folders, through glass", systemImage: "folder")
                    } description: {
                        Text("Add folders or drop them here. Hover to preview their contents; double-click to open in Finder.")
                    } actions: { Button("Add Folders…") { model.chooseFolders() }.buttonStyle(.borderedProminent) }
                    .frame(maxWidth: .infinity, minHeight: 350)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(model.folders) { FolderCard(folder: $0) }
                    }.padding(24)
                }
            }
            .background {
                Color(nsColor: .windowBackgroundColor)
            }
            .focusable().focusEffectDisabled().focused($focused)
            .onKeyPress(.escape) { model.dismissSelection(); return .handled }
            .onKeyPress(.leftArrow) { model.moveSelection(-1); return .handled }
            .onKeyPress(.rightArrow) { model.moveSelection(1); return .handled }
            .onKeyPress(.upArrow) { model.moveSelection(-1); return .handled }
            .onKeyPress(.downArrow) { model.moveSelection(1); return .handled }
            .onKeyPress(.return) { openSelected(); return .handled }
            .onKeyPress(.space) { openSelected(); return .handled }
            Divider()
            HStack {
                Text(model.preferences.isEnabled ? "Standalone prototype · Desktop and Finder overlays are not active" : "GlassFinder is off · Previews and folder monitoring stopped")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Settings…") { openSettings() }
            }.padding(12)
        }
        .frame(minWidth: 540, minHeight: 450)
        .background(BrowserDismissalMonitor { model.dismissSelection() })
        .toolbar {
            Button { model.chooseFolders() } label: { Label("Add Folders", systemImage: "folder.badge.plus") }
            Button { model.refreshAll() } label: { Label("Refresh Previews", systemImage: "arrow.clockwise") }
                .disabled(!model.preferences.isEnabled)
        }
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls); return urls.contains { $0.hasDirectoryPath || (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        }
        .alert("GlassFinder", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .onAppear { focused = true }
    }

    private func openSelected() {
        if let folder = model.folders.first(where: { $0.id == model.selection }) { model.open(folder) }
    }
}
