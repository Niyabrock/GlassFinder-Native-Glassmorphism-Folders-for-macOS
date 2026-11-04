import Foundation

public struct RGBColor: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red; self.green = green; self.blue = blue
    }
    public init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard text.count == 6, text.allSatisfy({ $0.isHexDigit }), let value = UInt32(text, radix: 16) else { return nil }
        self.init(Double((value >> 16) & 255) / 255, Double((value >> 8) & 255) / 255, Double(value & 255) / 255)
    }
    public var hex: String {
        String(format: "#%02X%02X%02X", Int((unit(red) * 255).rounded()), Int((unit(green) * 255).rounded()), Int((unit(blue) * 255).rounded()))
    }
    public mutating func normalize() { red = unit(red); green = unit(green); blue = unit(blue) }
}

private func unit(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0 }

public struct KeylineStop: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var position: Double
    public var color: RGBColor
    public var opacity: Double
    public init(position: Double, color: RGBColor, opacity: Double = 1) {
        id = UUID(); self.position = position; self.color = color; self.opacity = opacity
    }
}

public struct KeylineGradient: Codable, Equatable, Sendable {
    public var stops: [KeylineStop]
    /// Clockwise degrees from rightward; 90° runs top to bottom.
    public var angle = 90.0
    public var intensity = 1.0
    public var width = 2.4

    public static func defaults(for tone: BackgroundTone) -> Self {
        if tone == .dark {
            return Self(stops: [
                KeylineStop(position: 0, color: RGBColor(0.54, 0.56, 0.59), opacity: 0.72),
                KeylineStop(position: 0.4, color: RGBColor(0.32, 0.34, 0.37), opacity: 0.65),
                KeylineStop(position: 1, color: RGBColor(0.12, 0.13, 0.15), opacity: 0.65)
            ])
        }
        return Self(stops: [
            KeylineStop(position: 0, color: RGBColor(0.76, 0.8, 0.84), opacity: 0.9),
            KeylineStop(position: 0.4, color: RGBColor(0.43, 0.48, 0.54), opacity: 0.65),
            KeylineStop(position: 1, color: RGBColor(0.28, 0.33, 0.39), opacity: 0.55)
        ])
    }
    public mutating func normalize() {
        if stops.count < 2 { stops = Self.defaults(for: .light).stops }
        stops = Array(stops.prefix(12))
        var seen = Set<UUID>()
        for index in stops.indices {
            if !seen.insert(stops[index].id).inserted { stops[index].id = UUID() }
            stops[index].position = unit(stops[index].position)
            stops[index].opacity = unit(stops[index].opacity)
            stops[index].color.normalize()
        }
        stops.sort { $0.position < $1.position }
        angle = angle.isFinite ? (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) : 90
        intensity = unit(intensity)
        width = width.isFinite ? min(5, max(0.5, width)) : 2.4
    }
    @discardableResult public mutating func addStop(at position: Double) -> UUID? {
        normalize()
        guard stops.count < 12 else { return nil }
        let sorted = stops.sorted { $0.position < $1.position }
        let point = unit(position)
        let lower = sorted.last { $0.position <= point } ?? sorted[0]
        let upper = sorted.first { $0.position >= point } ?? sorted[sorted.count - 1]
        let fraction = upper.position == lower.position ? 0 : (point - lower.position) / (upper.position - lower.position)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * fraction }
        let stop = KeylineStop(position: point,
                               color: RGBColor(mix(lower.color.red, upper.color.red), mix(lower.color.green, upper.color.green), mix(lower.color.blue, upper.color.blue)),
                               opacity: mix(lower.opacity, upper.opacity))
        stops.append(stop); normalize(); return stop.id
    }
    public mutating func removeStop(_ id: UUID) { if stops.count > 2 { stops.removeAll { $0.id == id } } }
}

public struct AppearanceProfile: Codable, Equatable, Sendable {
    public var transparency = 0.9
    public var tint: RGBColor
    public var keyline: KeylineGradient
    public var background: FolderBackground = .none
    public var showItemCount = false
    public var presetTint: FolderTint?
    public var imagePlacement = ImagePlacement()
    public var effectiveTint: RGBColor { presetTint?.color ?? tint }
    private enum CodingKeys: String, CodingKey {
        case transparency, tint, keyline, background, showItemCount, presetTint, imagePlacement
    }
    public init(tint: RGBColor, keyline: KeylineGradient) { self.tint = tint; self.keyline = keyline }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tint = try values.decode(RGBColor.self, forKey: .tint)
        keyline = try values.decode(KeylineGradient.self, forKey: .keyline)
        transparency = try values.decodeIfPresent(Double.self, forKey: .transparency) ?? 0.9
        background = try values.decodeIfPresent(FolderBackground.self, forKey: .background) ?? .none
        showItemCount = try values.decodeIfPresent(Bool.self, forKey: .showItemCount) ?? false
        presetTint = try values.decodeIfPresent(FolderTint.self, forKey: .presetTint)
        imagePlacement = try values.decodeIfPresent(ImagePlacement.self, forKey: .imagePlacement) ?? .init()
        normalize()
    }
    public static func defaults(for tone: BackgroundTone) -> Self {
        Self(tint: tone == .light ? RGBColor(0.9, 0.93, 0.96) : RGBColor(0.1, 0.12, 0.15), keyline: .defaults(for: tone))
    }
    public mutating func normalize() {
        transparency = transparency.isFinite ? min(0.95, max(0.15, transparency)) : 0.9
        tint.normalize(); keyline.normalize(); imagePlacement.normalize()
    }
}

public enum FolderSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large
    public var iconWidth: Double { self == .small ? 48 : (self == .medium ? 64 : 96) }
    public var labelFont: Double { self == .small ? 11 : (self == .medium ? 12 : 13) }
    public var labelGap: Double { self == .small ? 5 : (self == .medium ? 7 : 10) }
    public var cellWidth: Double { iconWidth + 48 }
    public var cellHeight: Double { iconWidth * 326 / 340 + labelGap + labelFont * 3 + 16 }
}
