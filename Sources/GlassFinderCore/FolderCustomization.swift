import Foundation

public enum FolderTint: String, CaseIterable, Codable, Sendable {
    case red, orange, yellow, green, blue, purple, gray
    public var hex: String {
        switch self {
        case .red: return "#F07D71"
        case .orange: return "#F5BD67"
        case .yellow: return "#FBE772"
        case .green: return "#8FE586"
        case .blue: return "#67A3F9"
        case .purple: return "#CC88F9"
        case .gray: return "#B5B5B8"
        }
    }
    public var color: RGBColor { RGBColor(hex: hex)! }
}

public struct ImagePlacement: Codable, Equatable, Sendable {
    public var x = 0.0
    public var y = 0.0
    public var width = 1.0
    public var height = 1.0
    public var scale = 1.0
    public var lockAspectRatio = true
    public init() {}
    public func frame(aspectRatio: Double) -> FittedImageFrame {
        let aspect = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1
        let fittedWidth = max(340, 272 * aspect)
        return FittedImageFrame(width: fittedWidth * width * scale, height: fittedWidth / aspect * height * scale,
                                centerX: 170 + x * 340, centerY: 136 + y * 272)
    }
    public mutating func resizeWidth(_ value: Double) {
        width = value; if lockAspectRatio { height = value }; normalize()
    }
    public mutating func resizeHeight(_ value: Double) {
        height = value; if lockAspectRatio { width = value }; normalize()
    }
    public mutating func setAspectLocked(_ locked: Bool) {
        lockAspectRatio = locked
        if locked { height = width }
    }
    public mutating func normalize() {
        func clamp(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
            value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
        }
        x = clamp(x, -1.5...1.5, fallback: 0); y = clamp(y, -1.5...1.5, fallback: 0)
        width = clamp(width, 0.25...4, fallback: 1); height = clamp(height, 0.25...4, fallback: 1)
        scale = clamp(scale, 0.25...3, fallback: 1)
        if lockAspectRatio { height = width }
    }
}

public struct FittedImageFrame: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let centerX: Double
    public let centerY: Double
}

public struct FolderCustomization: Codable, Equatable, Sendable {
    public var tint: FolderTint?
    public var lightPlacement: ImagePlacement?
    public var darkPlacement: ImagePlacement?
    public init() {}
    public func placement(for tone: BackgroundTone) -> ImagePlacement? { tone == .light ? lightPlacement : darkPlacement }
    public mutating func setPlacement(_ value: ImagePlacement?, for tone: BackgroundTone) {
        if tone == .light { lightPlacement = value } else { darkPlacement = value }
    }
    public func applying(to preferences: Preferences) -> Preferences {
        var result = preferences
        for tone in BackgroundTone.allCases {
            var profile = preferences.profile(for: tone)
            if let tint { profile.presetTint = tint }
            if let placement = placement(for: tone) { profile.imagePlacement = placement }
            result.setProfile(profile, for: tone)
        }
        return result
    }
}

/// A persisted UUID follows the existing security-scoped bookmark through folder renames.
public struct SavedFolder: Codable, Equatable, Sendable {
    public var id: UUID
    public var bookmark: Data
    public var customization: FolderCustomization
    public init(id: UUID, bookmark: Data, customization: FolderCustomization = .init()) {
        self.id = id; self.bookmark = bookmark; self.customization = customization
    }
}
