import SwiftUI
import GlassFinderCore

struct FolderColorPicker: View {
    @Binding var selection: FolderTint?
    let defaultTitle: String
    var body: some View {
        Picker("Folder Color", selection: $selection) {
            Text(defaultTitle).tag(Optional<FolderTint>.none)
            ForEach(FolderTint.allCases, id: \.self) { tint in
                Label {
                    Text(tint.rawValue.capitalized)
                } icon: { Image(systemName: "circle.fill").foregroundStyle(tint.color.swiftUIColor) }
                .tag(Optional(tint))
            }
        }
    }
}
