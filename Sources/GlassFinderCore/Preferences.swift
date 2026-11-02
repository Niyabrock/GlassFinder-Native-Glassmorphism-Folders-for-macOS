import Foundation

public enum GlassAppearance: String, Codable, CaseIterable, Sendable {
    case automatic, light, dark
}

public struct Preferences: Codable, Equatable, Sendable {
    public var isEnabled = true
    public var appearance: GlassAppearance = .automatic
    public var animationSpeed = 1.0
    public var animationIntensity = 1.0
    public var hoverPreviews = true
    public var previewCount = 5
    public var transparency = 0.55
    public var reduceMotion = false
    public var globalShortcut = false

    public init() {}

    public mutating func normalize() {
        animationSpeed = animationSpeed.isFinite ? min(2, max(0.5, animationSpeed)) : 1
        animationIntensity = animationIntensity.isFinite ? min(1.5, max(0, animationIntensity)) : 1
        previewCount = min(5, max(3, previewCount))
        transparency = transparency.isFinite ? min(0.85, max(0.15, transparency)) : 0.55
    }
}

/// A selected folder stays open after the pointer leaves; disabled rendering is always closed.
public enum FolderPresentation {
    public static func openness(enabled: Bool, selected: Bool, hovered: Bool, hoverEnabled: Bool) -> Double {
        guard enabled else { return 0 }
        if selected { return 1 }
        return hovered && hoverEnabled ? 0.65 : 0
    }
}
