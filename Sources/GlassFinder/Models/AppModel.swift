import AppKit
import SwiftUI
import ServiceManagement
import GlassFinderCore
import UniformTypeIdentifiers

@MainActor
final class FolderItem: ObservableObject, Identifiable {
    let id: UUID
    var url: URL
    var bookmark: Data?
    var scoped = false
    @Published var files: [PreviewFile] = []
    @Published var images: [NSImage] = []
    @Published var message: String?
    @Published var itemCount: Int?
    @Published var customization: FolderCustomization
    var task: Task<Void, Never>?
    var monitor: DirectoryMonitor?
    var revision = UUID()

    init(id: UUID = UUID(), url: URL, bookmark: Data?, customization: FolderCustomization = .init()) {
        self.id = id; self.url = url; self.bookmark = bookmark; self.customization = customization
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var preferences: Preferences {
        didSet {
            if let data = try? JSONEncoder().encode(preferences) { defaults.set(data, forKey: "preferences.v1") }
            if oldValue.isEnabled != preferences.isEnabled { applyEnabled() }
            if oldValue.previewCount != preferences.previewCount { refreshAll() }
            if oldValue.globalShortcut != preferences.globalShortcut { configureShortcut() }
        }
    }
    @Published var folders: [FolderItem] = []
    @Published var selection: UUID?
    @Published var interactionGeneration = 0
    @Published var error: String?
    @Published var shortcutStatus = "Disabled"
    @Published var loginStatus = ""
    @Published var launchAtLogin = false
    @Published var customizingFolder: FolderItem?
    let thumbnails = ThumbnailService()
    let backgrounds = BackgroundStore()
    private let catalog = FileCatalog()
    private let defaults: UserDefaults
    private let shortcut = GlobalShortcut()
    private var observers: [NSObjectProtocol] = []
    private var stopped = false
    private var unresolvedFolders: [SavedFolder] = []
    private var canPersistFolders = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var saved = defaults.data(forKey: "preferences.v1").flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) } ?? Preferences()
        saved.normalize()
        preferences = saved
        restoreFolders()
        shortcut.onToggle = { [weak self] in self?.preferences.isEnabled.toggle() }
        configureShortcut()
        updateLoginStatus()
        applyEnabled()
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification, NSWorkspace.didWakeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refreshAll() }
            })
        }
    }

    func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add Folders"
        panel.message = "Glass Folder only reads previews. Your folders and icons remain unchanged."
        if panel.runModal() == .OK { add(panel.urls) }
    }

    func select(_ id: UUID) { selection = FolderSelection.click(current: selection, folder: id) }

    func setFolderTint(_ tint: FolderTint?, for folder: FolderItem) {
        folder.customization.tint = tint; persistFolders()
    }

    func setFolderPlacement(_ placement: ImagePlacement?, for folder: FolderItem, tone: BackgroundTone) {
        folder.customization.setPlacement(placement, for: tone); persistFolders()
    }

    func exportStaticIcon(for folder: FolderItem, tone: BackgroundTone) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = folder.url.lastPathComponent + "-glass-icon.png"
        panel.title = "Export Static Folder Icon"
        panel.message = "Exports an image only. It does not apply an icon or change Finder or Desktop folders."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try StaticIconExporter.png(preferences: folder.customization.applying(to: preferences), backgrounds: backgrounds, tone: tone)
            try data.write(to: url, options: .atomic)
        } catch { self.error = "Could not export icon: \(error.localizedDescription)" }
    }

    func dismissSelection() {
        selection = nil
        interactionGeneration += 1 // Also clear hover when a mouse-exit event was lost to a window transition.
    }

    func chooseBackground(for tone: BackgroundTone) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Background"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try backgrounds.importImage(url, for: tone)
                preferences.setBackground(.custom, for: tone)
            } catch { self.error = "Could not import background: \(error.localizedDescription)" }
        }
    }

    func removeBackground(for tone: BackgroundTone) {
        do {
            try backgrounds.remove(tone)
            preferences.setBackground(.none, for: tone)
        } catch { self.error = "Could not remove background: \(error.localizedDescription)" }
    }

    func add(_ urls: [URL]) {
        for url in urls {
            guard url.isFileURL, (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  !folders.contains(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) else { continue }
            let access = url.startAccessingSecurityScopedResource()
            let bookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            if bookmark == nil { error = "This folder could not be bookmarked. It can be used during this session, but its settings cannot be saved." }
            if access { url.stopAccessingSecurityScopedResource() }
            let folder = FolderItem(url: url, bookmark: bookmark)
            folders.append(folder)
            if preferences.isEnabled { activate(folder) }
        }
        persistFolders()
    }

    func remove(_ folder: FolderItem) {
        stop(folder)
        folders.removeAll { $0.id == folder.id }
        if selection == folder.id { selection = nil }
        persistFolders()
    }

    func open(_ folder: FolderItem) {
        if !NSWorkspace.shared.open(folder.url) { error = "Finder could not open \(folder.url.lastPathComponent). The folder may be unavailable." }
    }

    func moveSelection(_ delta: Int) {
        guard !folders.isEmpty else { return }
        let index = selection.flatMap { id in folders.firstIndex { $0.id == id } }
        let next = index.map { min(folders.count - 1, max(0, $0 + delta)) } ?? (delta < 0 ? folders.count - 1 : 0)
        selection = folders[next].id
    }

    func refreshAll() {
        guard preferences.isEnabled, !stopped else { return }
        for folder in folders { activate(folder) }
    }

    private func applyEnabled() {
        dismissSelection()
        if preferences.isEnabled { refreshAll() }
        else {
            for folder in folders { stop(folder) }
            thumbnails.stop()
        }
    }

    private func activate(_ folder: FolderItem) {
        if !folder.scoped { folder.scoped = folder.url.startAccessingSecurityScopedResource() }
        folder.monitor?.stop()
        folder.monitor = DirectoryMonitor(url: folder.url) { [weak self, weak folder] in
            Task { @MainActor in
                guard let self, let folder, self.preferences.isEnabled else { return }
                self.load(folder, debounce: true)
            }
        }
        load(folder)
    }

    private func load(_ folder: FolderItem, debounce: Bool = false) {
        folder.task?.cancel()
        let revision = UUID()
        folder.revision = revision
        let limit = preferences.previewCount
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        folder.task = Task { [weak self, weak folder] in
            guard let self, let folder else { return }
            do {
                if debounce { try await Task.sleep(for: .milliseconds(200)) }
                let snapshot = try await self.catalog.snapshot(of: folder.url, limit: limit)
                try Task.checkCancellation()
                guard self.preferences.isEnabled, folder.revision == revision else { return }
                let files = snapshot.files
                folder.files = files
                folder.itemCount = snapshot.itemCount
                folder.images = []
                folder.message = snapshot.itemCount == 0 ? "Empty folder" : (files.isEmpty ? "Only hidden items" : nil)
                for file in files {
                    if let image = await self.thumbnails.image(for: file, scale: scale) {
                        try Task.checkCancellation()
                        guard self.preferences.isEnabled, folder.revision == revision else { return }
                        folder.images.append(image)
                    }
                }
            } catch is CancellationError { }
            catch {
                guard self.preferences.isEnabled, folder.revision == revision else { return }
                folder.files = []; folder.images = []
                folder.itemCount = nil
                folder.message = "Unavailable: \(error.localizedDescription)"
            }
        }
    }

    private func stop(_ folder: FolderItem) {
        folder.revision = UUID()
        folder.task?.cancel(); folder.task = nil
        folder.monitor?.stop(); folder.monitor = nil
        folder.files = []; folder.images = []; folder.message = nil
        folder.itemCount = nil
        if folder.scoped { folder.url.stopAccessingSecurityScopedResource(); folder.scoped = false }
    }

    private func persistFolders() {
        guard canPersistFolders else { return }
        let records = folders.compactMap { folder in
            folder.bookmark.map { SavedFolder(id: folder.id, bookmark: $0, customization: folder.customization) }
        } + unresolvedFolders
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: "folderRecords.v1") }
        // Keep the old bookmark key available for compatibility; no folder listing is persisted.
        defaults.set(records.map(\.bookmark), forKey: "folderBookmarks.v1")
    }

    private func restoreFolders() {
        let records: [SavedFolder]
        if let data = defaults.data(forKey: "folderRecords.v1") {
            guard let saved = try? JSONDecoder().decode([SavedFolder].self, from: data) else {
                canPersistFolders = false
                error = "Saved folder settings could not be read. They were preserved without overwriting them."
                return
            }
            records = saved
        } else {
            records = (defaults.array(forKey: "folderBookmarks.v1") as? [Data] ?? []).map { SavedFolder(id: UUID(), bookmark: $0) }
        }
        for record in records {
            let data = record.bookmark
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                                  relativeTo: nil, bookmarkDataIsStale: &stale) {
                var bookmark = data
                if stale {
                    let access = url.startAccessingSecurityScopedResource()
                    bookmark = (try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)) ?? data
                    if access { url.stopAccessingSecurityScopedResource() }
                }
                folders.append(FolderItem(id: record.id, url: url, bookmark: bookmark, customization: record.customization))
            } else {
                unresolvedFolders.append(record)
                error = "A saved folder is unavailable. Reconnect its drive and relaunch. Its custom settings were retained."
            }
        }
        persistFolders()
    }

    private func configureShortcut() {
        shortcut.configure(enabled: preferences.globalShortcut)
        shortcutStatus = !preferences.globalShortcut ? "Disabled" : (shortcut.available ? "Control–Option–Command–G" : "Unavailable: shortcut may already be in use")
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch { self.error = "Launch at Login: \(error.localizedDescription)" }
        updateLoginStatus()
    }

    func updateLoginStatus() {
        let status = SMAppService.mainApp.status
        launchAtLogin = status == .enabled || status == .requiresApproval
        switch status {
        case .enabled: loginStatus = "Enabled"
        case .requiresApproval: loginStatus = "Approval required in System Settings → General → Login Items"
        case .notRegistered: loginStatus = "Disabled"
        case .notFound: loginStatus = "Install the bundled app in Applications first"
        @unknown default: loginStatus = "Unknown status"
        }
    }

    func resetPreferences() { preferences = Preferences() } // Login registration is deliberately independent.

    func shutdown() {
        stopped = true
        for folder in folders { stop(folder) }
        thumbnails.stop()
        shortcut.stop()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observers.removeAll()
    }
}
