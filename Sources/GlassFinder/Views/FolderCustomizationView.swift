import SwiftUI
import GlassFinderCore

@MainActor
struct FolderCustomizationView: View {
    @ObservedObject var folder: FolderItem
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    private var tone: BackgroundTone { model.preferences.activeTone(systemIsDark: colorScheme == .dark) }
    private var effective: Preferences { folder.customization.applying(to: model.preferences) }
    private var placement: Binding<ImagePlacement> {
        Binding(get: { folder.customization.placement(for: tone) ?? model.preferences.profile(for: tone).imagePlacement },
                set: { model.setFolderPlacement($0, for: folder, tone: tone) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(folder.url.lastPathComponent).font(.title2)
            Text("Overrides affect this folder in Glass Folder only. Finder tags and source files are not changed.")
                .font(.caption).foregroundStyle(.secondary)
            FolderColorPicker(selection: Binding(get: { folder.customization.tint }, set: { model.setFolderTint($0, for: folder) }), defaultTitle: "Default (Use Appearance Color)")
            if effective.profile(for: tone).background == .custom {
                Text("\(tone.rawValue.capitalized) Image Placement").font(.headline)
                ImagePlacementEditor(placement: placement, preferences: effective)
                Button("Use Appearance Image Placement") { model.setFolderPlacement(nil, for: folder, tone: tone) }
            } else {
                GlassFolderView(images: [], names: [], selected: false, hovered: false, preferences: effective, displayWidth: 180)
                    .frame(maxWidth: .infinity)
                Text("Choose a Custom Image in Appearance settings to adjust this folder’s placement independently.").font(.caption).foregroundStyle(.secondary)
            }
            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 580)
    }
}
