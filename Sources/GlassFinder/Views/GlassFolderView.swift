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
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var pointer = CGPoint.zero
    private let scale: CGFloat = 210 / 340
    private var dark: Bool {
        preferences.appearance == .dark || (preferences.appearance == .automatic && systemScheme == .dark)
    }
    private var motionReduced: Bool { systemReduceMotion || preferences.reduceMotion }
    private var pose: FolderPose { .resolve(selected: selected, hovered: hovered, hoverEnabled: preferences.hoverPreviews) }
    private var artwork: NSImage? { dark ? ArtworkAssets.dark : ArtworkAssets.light }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(.black.opacity(dark ? 0.62 : 0.34))
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
        .frame(width: 210, height: 326 * scale, alignment: .topLeading)
        .onContinuousHover { phase in
            guard !motionReduced else { pointer = .zero; return }
            switch phase {
            case .active(let point):
                pointer = CGPoint(x: min(1, max(-1, point.x / 210 * 2 - 1)),
                                  y: min(1, max(-1, point.y / (326 * scale) * 2 - 1)))
            case .ended: pointer = .zero
            }
        }
        .animation(motionReduced ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9 / preferences.animationSpeed), value: pointer)
        .environment(\.colorScheme, dark ? .dark : .light)
        .accessibilityHidden(true)
    }

    private var rear: some View {
        ZStack {
            LinearGradient(colors: dark ? [Color(white: 0.165), Color(white: 0.071)] : [Color(white: 0.953), Color(white: 0.89)], startPoint: .top, endPoint: .bottom)
            if let artwork {
                Image(nsImage: artwork).resizable().scaledToFill().frame(width: 364, height: 296)
                    .offset(x: -pointer.x * 7, y: -pointer.y * 6)
            }
            LinearGradient(stops: [.init(color: .white.opacity(0.22), location: 0), .init(color: .clear, location: 0.22)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.white.opacity(0.16), .clear], center: UnitPoint(x: 0.8, y: 0), startRadius: 0, endRadius: 200)
        }
        .frame(width: 340, height: 272).clipShape(PanelPath())
        .overlay(PanelPath().stroke(.white.opacity(dark ? 0.16 : 0.45), lineWidth: 1))
    }

    private var sheets: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(images.prefix(preferences.previewCount).enumerated()), id: \.offset) { index, image in
                let count = min(images.count, preferences.previewCount)
                let depth = Double(count - 1 - index)
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
                .offset(x: 34 + jitter.x + slot * pose.spread * preferences.animationIntensity,
                        y: 96 + 42 + (pose.lift - 42 - depth * pose.stack) * preferences.animationIntensity)
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
            LinearGradient(stops: dark ? [
                .init(color: Color(red: 18/255, green: 18/255, blue: 20/255).opacity(0.18), location: 0),
                .init(color: Color(red: 14/255, green: 14/255, blue: 16/255).opacity(0.62), location: 0.46),
                .init(color: Color(red: 8/255, green: 8/255, blue: 10/255).opacity(0.94), location: 1)
            ] : [
                .init(color: .white.opacity(0.16), location: 0),
                .init(color: .white.opacity(0.5), location: 0.42),
                .init(color: Color(white: 252/255).opacity(0.93), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .opacity(min(1, max(0.2, 1.55 - preferences.transparency)))
            RadialGradient(colors: [.white.opacity(0.5), .clear],
                           center: UnitPoint(x: 0.5 + pointer.x * 0.46, y: 0.3 + pointer.y * 0.4), startRadius: 0, endRadius: 182)
                .blendMode(dark ? .screen : .softLight).opacity(dark ? 0.16 : 0.9)
        }
        .frame(width: 340, height: 198, alignment: .topLeading).clipShape(PanelPath(front: true))
        .overlay(PanelPath(front: true).stroke(LinearGradient(stops: [
            .init(color: .white.opacity(0.95), location: 0),
            .init(color: .white.opacity(0.35), location: 0.35),
            .init(color: .white.opacity(0.12), location: 1)
        ], startPoint: .top, endPoint: .bottom), lineWidth: 2.4).opacity(dark ? 0.55 : 1))
        .rotation3DEffect(.degrees(pose.hinge * preferences.animationIntensity), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 340 / 760)
        .offset(y: 74)
        .animation(motionReduced ? nil : .timingCurve(0.34, 1.36, 0.5, 1, duration: 0.8 / preferences.animationSpeed), value: pose)
    }
}
