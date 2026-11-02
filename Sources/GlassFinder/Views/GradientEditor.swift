import SwiftUI
import AppKit
import GlassFinderCore

extension RGBColor {
    var swiftUIColor: Color { Color(red: red, green: green, blue: blue) }
    init(color: Color) {
        let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .gray
        self.init(Double(rgb.redComponent), Double(rgb.greenComponent), Double(rgb.blueComponent))
    }
}

extension KeylineGradient {
    var swiftUIGradient: LinearGradient {
        let radians = (angle.isFinite ? angle : 90) * .pi / 180
        let dx = cos(radians), dy = sin(radians)
        let extent = 0.5 / max(abs(dx), abs(dy))
        let renderedStops = self.stops.sorted { $0.position < $1.position }.map {
            Gradient.Stop(color: $0.color.swiftUIColor.opacity($0.opacity * intensity), location: $0.position)
        }
        return LinearGradient(stops: renderedStops,
                              startPoint: UnitPoint(x: 0.5 - dx * extent, y: 0.5 - dy * extent),
                              endPoint: UnitPoint(x: 0.5 + dx * extent, y: 0.5 + dy * extent))
    }
}

@MainActor
struct GradientEditor: View {
    @Binding var gradient: KeylineGradient
    let tone: BackgroundTone
    @State private var expanded = false
    @State private var selectedID: UUID?
    @State private var hex = ""
    private var selected: KeylineStop? { gradient.stops.first { $0.id == selectedID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { expanded.toggle() } label: {
                HStack {
                    RoundedRectangle(cornerRadius: 5).fill(gradient.swiftUIGradient).frame(height: 24)
                        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    Image(systemName: expanded ? "chevron.up" : "slider.horizontal.3")
                }
            }.buttonStyle(.plain).accessibilityLabel("Edit \(tone.rawValue) keyline gradient")
            if expanded {
                Text("Select a stop; drag it or enter its position. Add up to 12 stops.")
                    .font(.caption).foregroundStyle(.secondary)
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 4).fill(gradient.swiftUIGradient).frame(height: 20).padding(.horizontal, 10)
                        ForEach(gradient.stops) { stop in
                            Button { select(stop.id) } label: {
                                Circle().fill(stop.color.swiftUIColor.opacity(stop.opacity))
                                    .background(.regularMaterial, in: Circle())
                                    .overlay(Circle().stroke(stop.id == selectedID ? Color.accentColor : .secondary, lineWidth: 2))
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                            .position(x: 10 + stop.position * max(1, geometry.size.width - 20), y: 31)
                            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("keylineStops"))
                                .onChanged { value in
                                    select(stop.id)
                                    edit(stop.id) { $0.position = (value.location.x - 10) / max(1, geometry.size.width - 20) }
                                })
                            .accessibilityLabel("Gradient stop at \(Int(stop.position * 100)) percent")
                            .accessibilityAddTraits(stop.id == selectedID ? .isSelected : [])
                            .accessibilityAdjustableAction { direction in
                                select(stop.id)
                                edit(stop.id) { $0.position += direction == .increment ? 0.01 : -0.01 }
                            }
                        }
                    }.coordinateSpace(name: "keylineStops")
                }.frame(height: 45)
                HStack {
                    Button("Add Stop") {
                        if let id = gradient.addStop(at: 0.5) { select(id) }
                    }.disabled(gradient.stops.count >= 12)
                    Button("Remove Stop") {
                        if let id = selectedID { gradient.removeStop(id); select(gradient.stops[0].id) }
                    }.disabled(selectedID == nil || gradient.stops.count <= 2)
                    Spacer()
                    Button("Reset Gradient") { gradient = .defaults(for: tone); select(gradient.stops[0].id) }
                }
                if let stop = selected {
                    HStack {
                        Text("Position (%)")
                        TextField("Position percent", value: Binding(get: { selected?.position ?? 0 }, set: { value in edit(stop.id) { $0.position = value } }).percent,
                                  format: .number.precision(.fractionLength(1)))
                            .frame(width: 65)
                        ColorPicker("Stop Color", selection: Binding(get: { stop.color.swiftUIColor }, set: { color in edit(stop.id) { $0.color = RGBColor(color: color) } }), supportsOpacity: false)
                    }
                    HStack {
                        TextField("Hex #RRGGBB", text: $hex).textFieldStyle(.roundedBorder).frame(width: 115)
                            .accessibilityLabel("Stop hexadecimal color")
                            .onChange(of: hex) { _, value in
                                if let rgb = RGBColor(hex: value) { edit(stop.id) { $0.color = rgb } }
                            }
                        if RGBColor(hex: hex) == nil { Text("Use #RRGGBB").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Text("Opacity")
                        Slider(value: Binding(get: { stop.opacity }, set: { value in edit(stop.id) { $0.opacity = value } }), in: 0...1)
                            .accessibilityLabel("Stop opacity").frame(width: 110)
                        Text(stop.opacity, format: .percent.precision(.fractionLength(0))).monospacedDigit()
                    }
                }
                HStack {
                    Text("Angle (°)")
                    Slider(value: $gradient.angle, in: 0...360).accessibilityLabel("Gradient direction")
                    TextField("Angle degrees", value: $gradient.angle, format: .number.precision(.fractionLength(0))).frame(width: 55)
                        .onSubmit { gradient.normalize() }
                }
                HStack {
                    Text("Intensity")
                    Slider(value: $gradient.intensity, in: 0...1).accessibilityLabel("Gradient intensity")
                    Text(gradient.intensity, format: .percent.precision(.fractionLength(0)))
                }
                HStack {
                    Text("Thickness")
                    Slider(value: $gradient.width, in: 0.5...5).accessibilityLabel("Keyline thickness")
                    Text(gradient.width, format: .number.precision(.fractionLength(1)))
                }
            }
        }
        .onAppear { if selectedID == nil, let first = gradient.stops.first { select(first.id) } }
        .onChange(of: tone) { _, _ in if let first = gradient.stops.first { select(first.id) } }
        .onChange(of: selected?.color) { _, color in if let color { hex = color.hex } }
    }

    private func select(_ id: UUID) {
        guard selectedID != id else { return }
        selectedID = id
        hex = gradient.stops.first { $0.id == id }?.color.hex ?? ""
    }
    private func edit(_ id: UUID, _ change: (inout KeylineStop) -> Void) {
        var value = gradient
        guard let index = value.stops.firstIndex(where: { $0.id == id }) else { return }
        change(&value.stops[index]); value.normalize(); gradient = value
    }
}

private extension Binding where Value == Double {
    var percent: Binding<Double> { Binding(get: { wrappedValue * 100 }, set: { wrappedValue = $0 / 100 }) }
}
