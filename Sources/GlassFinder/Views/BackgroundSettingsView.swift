import SwiftUI
import GlassFinderCore

@MainActor
struct BackgroundSettingsView: View {
    let tone: BackgroundTone
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var backgrounds: BackgroundStore
    @State private var preview = false

    private var selection: Binding<FolderBackground> {
        Binding(get: { model.preferences.background(for: tone) }, set: { model.preferences.setBackground($0, for: tone) })
    }
    private var previewPreferences: Preferences {
        var preferences = model.preferences
        preferences.appearance = tone == .light ? .light : .dark
        return preferences
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tone.rawValue.capitalized + " Appearance").font(.headline)
            Picker("Background", selection: selection) {
                Text("None (plain glass)").tag(FolderBackground.none)
                Text("Aurora preset").tag(FolderBackground.aurora)
                Text("Ember preset").tag(FolderBackground.ember)
                Text("Dot pattern").tag(FolderBackground.dots)
                if backgrounds.image(for: tone) != nil { Text("Custom image").tag(FolderBackground.custom) }
                else if selection.wrappedValue == .custom { Text("Custom image unavailable").tag(FolderBackground.custom) }
            }
            HStack {
                Button("Choose Custom Image…") { model.chooseBackground(for: tone) }
                Button("Remove / Reset") { model.removeBackground(for: tone) }
                Spacer()
            }
            DisclosureGroup("Preview Background", isExpanded: $preview) {
                GlassFolderView(images: [], names: [], selected: false, hovered: false, preferences: previewPreferences, displayWidth: 180)
                    .frame(maxWidth: .infinity).padding(12)
                    .background(tone == .light ? Color(white: 0.91) : Color(white: 0.16), in: RoundedRectangle(cornerRadius: 8))
            }
        }.padding(.vertical, 4)
    }
}
