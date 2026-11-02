import Foundation

/// Measurements from the supplied Glass Folder Cards reference, in its 340-unit coordinate system.
public struct FolderPose: Equatable, Sendable {
    public let hinge: Double
    public let lift: Double
    public let spread: Double
    public let fan: Double
    public let stack: Double

    public static let closed = FolderPose(hinge: 0, lift: 42, spread: 0, fan: 0, stack: 15)
    public static let hover = FolderPose(hinge: -11, lift: -34, spread: 8, fan: 1.4, stack: 10)
    public static let open = FolderPose(hinge: -24, lift: -96, spread: 40, fan: 5, stack: 30)

    public static func resolve(selected: Bool, hovered: Bool, hoverEnabled: Bool) -> FolderPose {
        selected ? .open : (hovered && hoverEnabled ? .hover : .closed)
    }

    public static func fanSlot(index: Int, count: Int) -> Double {
        count <= 1 ? 0 : Double(index) / Double(count - 1) * 2 - 1
    }

    public func depthOffset(index: Int, count: Int) -> Double {
        let depth = Double(max(0, count - 1 - index))
        return depth * stack * min(1, 3 / Double(max(1, count - 1)))
    }

    /// Stable per-filename jitter; independent of Swift's randomized Hasher.
    public static func jitter(name: String, index: Int) -> (x: Double, rotation: Double) {
        var hash: UInt32 = 2_166_136_261
        for code in name.utf16 { hash = (hash ^ UInt32(code)) &* 16_777_619 }
        var seed = hash &+ UInt32(index)
        func random() -> Double {
            seed = seed &+ 0x6d2b79f5
            var value = (seed ^ (seed >> 15)) &* (seed | 1)
            value ^= value &+ ((value ^ (value >> 7)) &* (value | 61))
            return Double(value ^ (value >> 14)) / 4_294_967_296
        }
        return ((random() - 0.5) * 10, (random() - 0.5) * 3.2)
    }
}
