import Foundation

public enum GlassAppearance: String, Codable, CaseIterable, Sendable {
    case automatic, light, dark
}

public enum BackgroundTone: String, CaseIterable, Hashable, Sendable { case light, dark }
public enum FolderBackground: String, Codable, CaseIterable, Hashable, Sendable {
    case none, custom, aurora, ember, dots
}

public struct Preferences: Codable, Equatable, Sendable {
    public var isEnabled = true
    public var appearance: GlassAppearance = .automatic
    public var animationSpeed = 1.0
    public var animationIntensity = 1.0
    public var hoverPreviews = true
    public var previewCount = 5
    public var transparency = 0.9
    public var lightBackground: FolderBackground = .none
    public var darkBackground: FolderBackground = .none
    public var reduceMotion = false
    public var globalShortcut = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case isEnabled, appearance, animationSpeed, animationIntensity, hoverPreviews, previewCount
        case transparency, reduceMotion, globalShortcut, lightBackground, darkBackground
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // Additive migration: retain v1 settings rather than discarding them when new keys are absent.
        isEnabled = try values.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        appearance = try values.decodeIfPresent(GlassAppearance.self, forKey: .appearance) ?? .automatic
        animationSpeed = try values.decodeIfPresent(Double.self, forKey: .animationSpeed) ?? 1
        animationIntensity = try values.decodeIfPresent(Double.self, forKey: .animationIntensity) ?? 1
        hoverPreviews = try values.decodeIfPresent(Bool.self, forKey: .hoverPreviews) ?? true
        previewCount = try values.decodeIfPresent(Int.self, forKey: .previewCount) ?? 5
        transparency = try values.decodeIfPresent(Double.self, forKey: .transparency) ?? 0.9
        reduceMotion = try values.decodeIfPresent(Bool.self, forKey: .reduceMotion) ?? false
        globalShortcut = try values.decodeIfPresent(Bool.self, forKey: .globalShortcut) ?? false
        lightBackground = try values.decodeIfPresent(FolderBackground.self, forKey: .lightBackground) ?? .none
        darkBackground = try values.decodeIfPresent(FolderBackground.self, forKey: .darkBackground) ?? .none
        normalize()
    }

    public func background(for tone: BackgroundTone) -> FolderBackground {
        tone == .light ? lightBackground : darkBackground
    }

    public mutating func setBackground(_ background: FolderBackground, for tone: BackgroundTone) {
        if tone == .light { lightBackground = background } else { darkBackground = background }
    }

    public mutating func normalize() {
        animationSpeed = animationSpeed.isFinite ? min(2, max(0.5, animationSpeed)) : 1
        animationIntensity = animationIntensity.isFinite ? min(1.5, max(0, animationIntensity)) : 1
        previewCount = min(5, max(3, previewCount))
        transparency = transparency.isFinite ? min(0.95, max(0.15, transparency)) : 0.9
    }
}

public enum FolderSelection {
    public static func click(current: UUID?, folder: UUID) -> UUID? { current == folder ? nil : folder }
}

/// A selected folder stays open after the pointer leaves; disabled rendering is always closed.
public enum FolderPresentation {
    public static func openness(enabled: Bool, selected: Bool, hovered: Bool, hoverEnabled: Bool) -> Double {
        guard enabled else { return 0 }
        if selected { return 1 }
        return hovered && hoverEnabled ? 0.65 : 0
    }
}
