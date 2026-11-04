import SwiftUI
import AppKit
import GlassFinderCore

@MainActor
struct FolderCard: View {
    @ObservedObject var folder: FolderItem
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var hovered = false
    private var selected: Bool { model.selection == folder.id }
    private var size: FolderSize { model.preferences.folderSize }
    private var accessibilitySummary: String {
        let profile = model.preferences.profile(for: model.preferences.activeTone(systemIsDark: colorScheme == .dark))
        let state = selected ? "Selected folder" : "Folder"
        guard model.preferences.isEnabled, profile.showItemCount, let count = folder.itemCount else { return state }
        return state + ", " + (count == 1 ? "1 item" : "\(count) items")
    }

    var body: some View {
        VStack(spacing: size.labelGap) {
            if model.preferences.isEnabled {
                GlassFolderView(images: folder.images, names: folder.files.map { $0.url.lastPathComponent },
                                selected: selected, hovered: hovered,
                                preferences: folder.customization.applying(to: model.preferences), itemCount: folder.itemCount)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: folder.url.path))
                    .resizable().scaledToFit().frame(width: size.iconWidth, height: size.iconWidth * 272 / 340)
                    .frame(width: size.iconWidth, height: size.iconWidth * 326 / 340)
            }
            Text(folder.url.lastPathComponent)
                .font(.system(size: size.labelFont)).lineLimit(2).multilineTextAlignment(.center)
                .padding(.horizontal, size.labelFont / 3).padding(.vertical, size.labelFont / 8)
                .foregroundStyle(selected ? Color.white : .primary)
                .background(selected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 4))
                .frame(maxWidth: size.cellWidth - 12)
            Text(folder.message ?? " ")
                .font(.system(size: max(9, size.labelFont - 2))).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: size.cellWidth - 12)
        }
        .frame(width: size.cellWidth, height: size.cellHeight, alignment: .top)
        .zIndex(selected ? 1 : 0)
        .contentShape(Rectangle())
        .overlay {
            FolderClickSurface(single: { model.select(folder.id) }, double: { model.selection = folder.id; model.open(folder) }, key: { code in
                switch code {
                case 123, 126: model.moveSelection(-1)
                case 124, 125: model.moveSelection(1)
                case 53: model.dismissSelection()
                case 36, 49:
                    if let selected = model.folders.first(where: { $0.id == model.selection }) { model.open(selected) }
                default: return false
                }
                return true
            }, url: folder.url)
                .accessibilityHidden(true)
        }
        .onHover { hovered = $0 }
        .onChange(of: model.preferences.isEnabled) { _, enabled in if !enabled { hovered = false } }
        .onChange(of: model.interactionGeneration) { _, _ in hovered = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(folder.url.lastPathComponent)
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint("Activate to open in Finder")
        .accessibilityAction { model.open(folder) }
        .contextMenu {
            Menu("Folder Color") {
                Button("Default (Use Appearance Color)") { model.setFolderTint(nil, for: folder) }
                ForEach(FolderTint.allCases, id: \.self) { tint in
                    Button(tint.rawValue.capitalized) { model.setFolderTint(tint, for: folder) }
                }
            }
            Button("Customize Color and Image…") { model.customizingFolder = folder }
            Button("Export Static Icon PNG…") {
                model.exportStaticIcon(for: folder, tone: model.preferences.activeTone(systemIsDark: colorScheme == .dark))
            }
            Button("Open in Finder") { model.open(folder) }
            Button("Remove from Glass Folder") { model.remove(folder) }
        }
        .help(folder.message ?? folder.url.path)
    }
}

/// NSEvent.clickCount uses the user's double-click interval; the first click selects immediately.
@MainActor
private struct FolderClickSurface: NSViewRepresentable {
    var single: () -> Void
    var double: () -> Void
    var key: (UInt16) -> Bool
    var url: URL
    func makeNSView(context: Context) -> ClickView { ClickView() }
    func updateNSView(_ view: ClickView, context: Context) {
        view.single = single; view.double = double; view.key = key; view.url = url
    }

    final class ClickView: NSView, NSDraggingSource, FolderInteractionRegion {
        var single: (() -> Void)?
        var double: (() -> Void)?
        var key: ((UInt16) -> Bool)?
        var url: URL?
        private var down: NSPoint?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            if key?(event.keyCode) != true { super.keyDown(with: event) }
        }
        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            down = event.locationInWindow
            if event.clickCount == 1 { single?() }
            else if event.clickCount == 2 { double?() }
        }
        override func mouseDragged(with event: NSEvent) {
            guard let down, hypot(event.locationInWindow.x - down.x, event.locationInWindow.y - down.y) > 5,
                  let url else { return }
            self.down = nil
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let point = convert(event.locationInWindow, from: nil)
            item.setDraggingFrame(NSRect(x: point.x - 24, y: point.y - 24, width: 48, height: 48),
                                  contents: NSWorkspace.shared.icon(forFile: url.path))
            beginDraggingSession(with: [item], event: event, source: self)
        }
        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
    }
}
