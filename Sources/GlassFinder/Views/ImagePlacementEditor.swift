import SwiftUI
import GlassFinderCore

@MainActor
struct ImagePlacementEditor: View {
    @Binding var placement: ImagePlacement
    let preferences: Preferences
    @State private var dragOrigin: ImagePlacement?
    private let width: CGFloat = 240

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drag the artwork to position it. Dimensions and offsets are percentages, so placement stays consistent at every folder size.")
                .font(.caption).foregroundStyle(.secondary)
            GlassFolderView(images: [], names: [], selected: false, hovered: false, preferences: previewPreferences, displayWidth: width)
                .contentShape(Rectangle())
                .gesture(DragGesture().onChanged { value in
                    if dragOrigin == nil { dragOrigin = placement }
                    guard let origin = dragOrigin else { return }
                    var next = origin
                    next.x += Double(value.translation.width / width)
                    next.y += Double(value.translation.height / (width * 272 / 340))
                    next.normalize(); placement = next
                }.onEnded { _ in dragOrigin = nil })
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Image placement preview; use the position controls below for precise adjustments")
            control("Horizontal (%)", value: component(\.x), range: -150...150)
            control("Vertical (%)", value: component(\.y), range: -150...150)
            control("Width (%)", value: dimension(width: true), range: 25...400)
            control("Height (%)", value: dimension(width: false), range: 25...400)
            control("Scale (%)", value: component(\.scale), range: 25...300)
            Toggle("Lock aspect ratio", isOn: Binding(get: { placement.lockAspectRatio }, set: { value in placement.setAspectLocked(value) }))
            Button("Reset Image Position and Size") { placement = .init() }
        }
    }

    private var previewPreferences: Preferences {
        var value = preferences
        value.hoverPreviews = false
        value.lightProfile.imagePlacement = placement
        value.darkProfile.imagePlacement = placement
        return value
    }
    private func component(_ key: WritableKeyPath<ImagePlacement, Double>) -> Binding<Double> {
        Binding(get: { placement[keyPath: key] * 100 }, set: { value in
            var next = placement; next[keyPath: key] = value / 100; next.normalize(); placement = next
        })
    }
    private func dimension(width: Bool) -> Binding<Double> {
        Binding(get: { (width ? placement.width : placement.height) * 100 }, set: { value in
            var next = placement
            if width { next.resizeWidth(value / 100) } else { next.resizeHeight(value / 100) }
            placement = next
        })
    }
    private func control(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title).frame(width: 105, alignment: .leading)
            Slider(value: value, in: range).accessibilityLabel(title)
            TextField(title, value: value, format: .number.precision(.fractionLength(1))).frame(width: 65)
        }
    }
}
