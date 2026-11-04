import SwiftUI
import GlassFinderCore

@MainActor
struct AppearanceSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    private var editing: BackgroundTone { model.preferences.activeTone(systemIsDark: colorScheme == .dark) }
    private var editingSelection: Binding<BackgroundTone> {
        Binding(get: { editing }, set: { model.preferences.editAppearance($0) })
    }
    private var profile: Binding<AppearanceProfile> {
        Binding(get: { model.preferences.profile(for: editing) }, set: { model.preferences.setProfile($0, for: editing) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Appearance", selection: $model.preferences.appearance) {
                ForEach(GlassAppearance.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            Picker("Editing Profile", selection: editingSelection) {
                Text("Edit Light Appearance").tag(BackgroundTone.light)
                Text("Edit Dark Appearance").tag(BackgroundTone.dark)
            }.pickerStyle(.segmented)
            Text("Editing \(editing.rawValue.capitalized) — all controls below are saved only to this profile.")
                .font(.caption).foregroundStyle(.secondary)
            GlassFolderView(images: [], names: [], selected: false, hovered: false, preferences: model.preferences, displayWidth: 180)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            HStack {
                Text("Glass Transparency")
                Slider(value: profile.transparency, in: 0.15...0.95).accessibilityLabel("\(editing.rawValue) glass transparency")
                Text(profile.wrappedValue.transparency, format: .percent.precision(.fractionLength(0))).monospacedDigit()
            }
            FolderColorPicker(selection: profile.presetTint, defaultTitle: "No Preset (Use Glass Tint)")
            Button("Restore Default Folder Color") {
                profile.wrappedValue.presetTint = nil
                profile.wrappedValue.tint = AppearanceProfile.defaults(for: editing).tint
            }
            ColorPicker("Glass Tint", selection: Binding(get: { profile.wrappedValue.tint.swiftUIColor }, set: { color in
                profile.wrappedValue.tint = GlassFinderCore.RGBColor(color: color)
                profile.wrappedValue.presetTint = nil
            }), supportsOpacity: false)
            Toggle("Show Item Count", isOn: profile.showItemCount)
            Text("Counts immediate children, including hidden items; never counts inside subfolders.")
                .font(.caption).foregroundStyle(.secondary)
            Text("Keyline Gradient").font(.headline)
            GradientEditor(gradient: profile.keyline, tone: editing).id(editing)
            Divider()
            BackgroundSettingsView(tone: editing).id(editing)
        }
    }
}
