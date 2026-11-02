import SwiftUI
import GlassFinderCore

/// Native adaptation of user-supplied Glass Folder Cards by kedhareswer (21st.dev).
/// User confirmed adaptation permission. Geometry/timing provenance: docs/REFERENCE.md.
private struct PanelPath: Shape {
    var front = false
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Cubic quarter circles preserve the reference SVG's 22-unit arc geometry.
        let c: CGFloat = 22 * 0.5522847498307936
        if front {
            p.move(to: CGPoint(x: 0, y: 22))
            p.addCurve(to: CGPoint(x: 22, y: 0), control1: CGPoint(x: 0, y: 22-c), control2: CGPoint(x: 22-c, y: 0))
            p.addLine(to: CGPoint(x: 118, y: 0))
            p.addCurve(to: CGPoint(x: 172, y: 32), control1: CGPoint(x: 144, y: 0), control2: CGPoint(x: 146, y: 32))
            p.addLine(to: CGPoint(x: 318, y: 32))
            p.addCurve(to: CGPoint(x: 340, y: 54), control1: CGPoint(x: 318+c, y: 32), control2: CGPoint(x: 340, y: 54-c))
            p.addLine(to: CGPoint(x: 340, y: 176))
            p.addCurve(to: CGPoint(x: 318, y: 198), control1: CGPoint(x: 340, y: 176+c), control2: CGPoint(x: 318+c, y: 198))
            p.addLine(to: CGPoint(x: 22, y: 198))
            p.addCurve(to: CGPoint(x: 0, y: 176), control1: CGPoint(x: 22-c, y: 198), control2: CGPoint(x: 0, y: 176+c))
        } else {
            p.move(to: CGPoint(x: 0, y: 56))
            p.addCurve(to: CGPoint(x: 22, y: 34), control1: CGPoint(x: 0, y: 56-c), control2: CGPoint(x: 22-c, y: 34))
            p.addLine(to: CGPoint(x: 146, y: 34))
            p.addCurve(to: CGPoint(x: 198, y: 0), control1: CGPoint(x: 170, y: 34), control2: CGPoint(x: 172, y: 0))
            p.addLine(to: CGPoint(x: 318, y: 0))
            p.addCurve(to: CGPoint(x: 340, y: 22), control1: CGPoint(x: 318+c, y: 0), control2: CGPoint(x: 340, y: 22-c))
            p.addLine(to: CGPoint(x: 340, y: 250))
            p.addCurve(to: CGPoint(x: 318, y: 272), control1: CGPoint(x: 340, y: 250+c), control2: CGPoint(x: 318+c, y: 272))
            p.addLine(to: CGPoint(x: 22, y: 272))
            p.addCurve(to: CGPoint(x: 0, y: 250), control1: CGPoint(x: 22-c, y: 272), control2: CGPoint(x: 0, y: 250+c))
        }
        p.closeSubpath()
        return p.applying(CGAffineTransform(scaleX: rect.width / 340, y: rect.height / (front ? 198 : 272)))
    }
}

@MainActor
private enum ArtworkAssets {
    #if SWIFT_PACKAGE
    private static let bundle: Bundle = {
        // Packaged apps expose flat resources; swift run uses SwiftPM's resource bundle.
        if Bundle.main.url(forResource: "aurora", withExtension: "png") != nil { return Bundle.main }
        return Bundle.module
    }()
    #else
    private static let bundle = Bundle.main
    #endif
    static let light = bundle.url(forResource: "aurora", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    static let dark = bundle.url(forResource: "ember", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
}

@MainActor
struct GlassFolderView: View {
    let images: [NSImage]
    let names: [String]
    let selected: Bool
    let hovered: Bool
    let preferences: Preferences
    var itemCount: Int? = nil
    var displayWidth: CGFloat? = nil
    @EnvironmentObject private var backgrounds: BackgroundStore
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var pointer = CGPoint.zero
    private var iconWidth: CGFloat { displayWidth ?? CGFloat(preferences.folderSize.iconWidth) }
    private var scale: CGFloat { iconWidth / 340 }
    private var dark: Bool {
        preferences.activeTone(systemIsDark: systemScheme == .dark) == .dark
    }
    private var motionReduced: Bool { systemReduceMotion || preferences.reduceMotion }
    private var pose: FolderPose { .resolve(selected: selected, hovered: hovered, hoverEnabled: preferences.hoverPreviews) }
    private var tone: BackgroundTone { dark ? .dark : .light }
    private var profile: AppearanceProfile { preferences.profile(for: tone) }
    private var background: FolderBackground { preferences.background(for: tone) }
    private var artwork: NSImage? {
        switch background {
        case .aurora: return ArtworkAssets.light
        case .ember: return ArtworkAssets.dark
        case .custom: return backgrounds.image(for: tone)
        default: return nil
        }
    }
    private var tintOpacity: Double { 1 - profile.transparency }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(.black.opacity(dark ? 0.24 : 0.12))
                .frame(width: 304, height: 60).blur(radius: 22).offset(x: 18, y: 218)
            ZStack(alignment: .topLeading) {
                rear
                sheets
                    // Like the source's gf-files clip: prevent sheets leaking below the pocket.
                    .mask(alignment: .topLeading) { Rectangle().frame(width: 1140, height: 662).offset(x: -400, y: -400) }
                front
            }
            .frame(width: 340, height: 272)
            .rotation3DEffect(.degrees(motionReduced ? 0 : -Double(pointer.y) * 3), axis: (x: 1, y: 0, z: 0), perspective: 340 / 1400)
            .rotation3DEffect(.degrees(motionReduced ? 0 : Double(pointer.x) * 4), axis: (x: 0, y: 1, z: 0), perspective: 340 / 1400)
        }
        .frame(width: 340, height: 272)
        .offset(y: 54)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: iconWidth, height: 326 * scale, alignment: .topLeading)
        .onContinuousHover { phase in
            guard !motionReduced else { pointer = .zero; return }
            switch phase {
            case .active(let point):
                pointer = CGPoint(x: min(1, max(-1, point.x / iconWidth * 2 - 1)),
                                  y: min(1, max(-1, point.y / (326 * scale) * 2 - 1)))
            case .ended: pointer = .zero
            }
        }
        .animation(motionReduced ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9 / preferences.animationSpeed), value: pointer)
        .onChange(of: hovered) { _, active in if !active { pointer = .zero } }
        .environment(\.colorScheme, dark ? .dark : .light)
        .accessibilityHidden(true)
    }

    private var rear: some View {
        ZStack {
            if reduceTransparency {
                Color(white: dark ? 0.16 : 0.9)
            } else {
                Rectangle().fill(.ultraThinMaterial).opacity(tintOpacity * 0.4)
                profile.tint.swiftUIColor.opacity(tintOpacity * 0.6)
            }
            if let artwork {
                Image(nsImage: artwork).resizable().scaledToFill().frame(width: 364, height: 296)
                    .offset(x: -pointer.x * 7, y: -pointer.y * 6)
            }
            if background == .dots {
                Canvas { context, size in
                    for x in stride(from: 8.0, to: size.width, by: 18) {
                        for y in stride(from: 8.0, to: size.height, by: 18) {
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color((dark ? Color.white : .black).opacity(0.18)))
                        }
                    }
                }
            }
            LinearGradient(stops: [.init(color: .white.opacity(0.10), location: 0), .init(color: .clear, location: 0.22)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.white.opacity(0.08), .clear], center: UnitPoint(x: 0.8, y: 0), startRadius: 0, endRadius: 200)
        }
        .frame(width: 340, height: 272).clipShape(PanelPath())
        .overlay(PanelPath().stroke(profile.keyline.swiftUIGradient, lineWidth: profile.keyline.width))
    }

    private var sheets: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(images.prefix(preferences.previewCount).enumerated()), id: \.offset) { index, image in
                let count = min(images.count, preferences.previewCount)
                let depth = Double(count - 1 - index)
                let depthOffset = pose.depthOffset(index: index, count: count)
                let slot = FolderPose.fanSlot(index: index, count: count)
                let jitter = FolderPose.jitter(name: names.indices.contains(index) ? names[index] : "", index: index)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16).fill(dark ? Color(white: 0.14) : Color(white: 0.98))
                    Image(nsImage: image).resizable().scaledToFit().padding(10)
                    if names.indices.contains(index) {
                        Text(names[index]).font(.system(size: 12.5, weight: .medium)).lineLimit(1)
                            .padding(5).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4)).padding(11)
                    }
                }
                .frame(width: 272, height: 184).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(dark ? 0.14 : 0.9), lineWidth: 1))
                .shadow(color: .black.opacity(dark ? 0.5 : 0.2), radius: 9, y: 10)
                .rotationEffect(.degrees(jitter.rotation + slot * pose.fan * preferences.animationIntensity), anchor: .bottom)
                .offset(x: 34 + jitter.x + slot * pose.spread * min(1.5, max(1, Double(count) / 5)) * preferences.animationIntensity,
                        y: 96 + 42 + (pose.lift - 42 - depthOffset) * preferences.animationIntensity)
                .animation(motionReduced ? nil : .timingCurve(0.34, 1.36, 0.5, 1, duration: 0.75 / preferences.animationSpeed)
                    .delay(depth * 0.04 / preferences.animationSpeed), value: pose)
            }
        }.frame(width: 340, height: 272, alignment: .topLeading)
    }

    private var front: some View {
        ZStack(alignment: .topLeading) {
            if reduceTransparency {
                Color(white: dark ? 0.07 : 0.95)
            } else {
                // Explicitly sample the same artwork/sheets so real previews frost through the glass.
                // Native materials alone do not guarantee sibling-content backdrop sampling.
                ZStack(alignment: .topLeading) { rear; sheets }
                    .frame(width: 340, height: 272, alignment: .topLeading)
                    .blur(radius: 22).saturation(1.5).offset(y: -74)
            }
            LinearGradient(stops: [
                .init(color: profile.tint.swiftUIColor.opacity(tintOpacity * 0.7), location: 0),
                .init(color: profile.tint.swiftUIColor.opacity(tintOpacity), location: 0.44),
                .init(color: profile.tint.swiftUIColor.opacity(min(1, tintOpacity * 1.3)), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.white.opacity(0.22), .clear],
                           center: UnitPoint(x: 0.5 + pointer.x * 0.46, y: 0.3 + pointer.y * 0.4), startRadius: 0, endRadius: 182)
                .blendMode(dark ? .screen : .softLight).opacity(dark ? 0.16 : 0.9)
            if profile.showItemCount, let itemCount {
                Text(itemCount == 1 ? "1 item" : "\(itemCount) items")
                    .font(.system(size: 48, weight: .medium)).lineLimit(1).minimumScaleFactor(0.65)
                    .frame(maxWidth: 270, alignment: .leading)
                    .foregroundStyle((dark ? Color.white : Color(white: 0.12)).opacity(0.8))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
                    .offset(x: 28, y: 122)
            }
        }
        .frame(width: 340, height: 198, alignment: .topLeading).clipShape(PanelPath(front: true))
        .overlay(PanelPath(front: true).stroke(profile.keyline.swiftUIGradient, lineWidth: profile.keyline.width))
        .rotation3DEffect(.degrees(pose.hinge * preferences.animationIntensity), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 340 / 760)
        .offset(y: 74)
        .animation(motionReduced ? nil : .timingCurve(0.34, 1.36, 0.5, 1, duration: 0.8 / preferences.animationSpeed), value: pose)
    }
}
