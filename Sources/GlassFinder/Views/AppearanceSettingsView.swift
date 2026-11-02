import SwiftUI
import GlassFinderCore

@MainActor
struct AppearanceSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var editing: BackgroundTone = .light
    private var profile: Binding<AppearanceProfile> {
        Binding(get: { model.preferences.profile(for: editing) }, set: { model.preferences.setProfile($0, for: editing) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Appearance", selection: $model.preferences.appearance) {
                ForEach(GlassAppearance.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            Picker("Editing Profile", selection: $editing) {
                Text("Edit Light Appearance").tag(BackgroundTone.light)
                Text("Edit Dark Appearance").tag(BackgroundTone.dark)
            }.pickerStyle(.segmented)
            Text("Editing \(editing.rawValue.capitalized) — all controls below are saved only to this profile.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("Glass Transparency")
                Slider(value: profile.transparency, in: 0.15...0.95).accessibilityLabel("\(editing.rawValue) glass transparency")
                Text(profile.wrappedValue.transparency, format: .percent.precision(.fractionLength(0))).monospacedDigit()
            }
            ColorPicker("Glass Tint", selection: Binding(get: { profile.wrappedValue.tint.swiftUIColor }, set: { color in
                profile.wrappedValue.tint = GlassFinderCore.RGBColor(color: color)
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
