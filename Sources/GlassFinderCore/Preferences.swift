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
    public var lightProfile = AppearanceProfile.defaults(for: .light)
    public var darkProfile = AppearanceProfile.defaults(for: .dark)
    public var folderSize: FolderSize = .medium
    // Compatibility accessors for the v1.1 settings API; all new UI edits an explicit profile.
    public var transparency: Double { get { lightProfile.transparency } set { lightProfile.transparency = newValue } }
    public var lightBackground: FolderBackground { get { lightProfile.background } set { lightProfile.background = newValue } }
    public var darkBackground: FolderBackground { get { darkProfile.background } set { darkProfile.background = newValue } }
    public var reduceMotion = false
    public var globalShortcut = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case isEnabled, appearance, animationSpeed, animationIntensity, hoverPreviews, previewCount
        case transparency, reduceMotion, globalShortcut, lightBackground, darkBackground
        case lightProfile, darkProfile, folderSize
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
        reduceMotion = try values.decodeIfPresent(Bool.self, forKey: .reduceMotion) ?? false
        globalShortcut = try values.decodeIfPresent(Bool.self, forKey: .globalShortcut) ?? false
        let legacyTransparency = try values.decodeIfPresent(Double.self, forKey: .transparency) ?? 0.9
        lightProfile = try values.decodeIfPresent(AppearanceProfile.self, forKey: .lightProfile) ?? .defaults(for: .light)
        darkProfile = try values.decodeIfPresent(AppearanceProfile.self, forKey: .darkProfile) ?? .defaults(for: .dark)
        if !values.contains(.lightProfile) {
            lightProfile.transparency = legacyTransparency
            lightProfile.background = try values.decodeIfPresent(FolderBackground.self, forKey: .lightBackground) ?? .none
        }
        if !values.contains(.darkProfile) {
            darkProfile.transparency = legacyTransparency
            darkProfile.background = try values.decodeIfPresent(FolderBackground.self, forKey: .darkBackground) ?? .none
        }
        folderSize = try values.decodeIfPresent(FolderSize.self, forKey: .folderSize) ?? .medium
        normalize()
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(isEnabled, forKey: .isEnabled)
        try values.encode(appearance, forKey: .appearance)
        try values.encode(animationSpeed, forKey: .animationSpeed)
        try values.encode(animationIntensity, forKey: .animationIntensity)
        try values.encode(hoverPreviews, forKey: .hoverPreviews)
        try values.encode(previewCount, forKey: .previewCount)
        try values.encode(reduceMotion, forKey: .reduceMotion)
        try values.encode(globalShortcut, forKey: .globalShortcut)
        try values.encode(lightProfile, forKey: .lightProfile)
        try values.encode(darkProfile, forKey: .darkProfile)
        try values.encode(folderSize, forKey: .folderSize)
    }

    public func profile(for tone: BackgroundTone) -> AppearanceProfile { tone == .light ? lightProfile : darkProfile }
    public mutating func setProfile(_ profile: AppearanceProfile, for tone: BackgroundTone) {
        if tone == .light { lightProfile = profile } else { darkProfile = profile }
    }
    public func activeTone(systemIsDark: Bool) -> BackgroundTone {
        appearance == .dark || (appearance == .automatic && systemIsDark) ? .dark : .light
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
        previewCount = min(10, max(1, previewCount))
        lightProfile.normalize(); darkProfile.normalize()
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
