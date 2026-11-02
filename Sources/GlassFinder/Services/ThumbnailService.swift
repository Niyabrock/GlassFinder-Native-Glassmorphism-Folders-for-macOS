import AppKit
import QuickLookThumbnailing
import GlassFinderCore

@MainActor
final class ThumbnailService {
    private let cache = NSCache<NSString, NSImage>()
    private var requests: [UUID: QLThumbnailGenerator.Request] = [:]
    private var continuations: [UUID: CheckedContinuation<NSImage?, Never>] = [:]
    private var epoch = 0

    init() {
        cache.totalCostLimit = 32 * 1024 * 1024
        cache.countLimit = 250
    }

    func image(for file: PreviewFile, scale: CGFloat) async -> NSImage? {
        guard !Task.isCancelled else { return nil }
        // Avoid materializing cloud placeholders. Native icons still cover every file type.
        let values = try? file.url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
        if file.isDirectory || (values?.isUbiquitousItem == true && values?.ubiquitousItemDownloadingStatus != .current) {
            return NSWorkspace.shared.icon(forFile: file.url.path)
        }
        let key = "\(file.url.path)|\(file.modified?.timeIntervalSince1970 ?? 0)|\(scale)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let id = UUID()
        let generation = epoch
        let request = QLThumbnailGenerator.Request(fileAt: file.url, size: CGSize(width: 140, height: 160),
                                                  scale: scale, representationTypes: .all)
        let image: NSImage? = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else { continuation.resume(returning: nil); return }
                requests[id] = request
                continuations[id] = continuation
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                    Task { @MainActor in self.finish(id, image: representation?.nsImage) }
                }
            }
        } onCancel: {
            Task { @MainActor in self.finish(id, image: nil, cancel: true) }
        }
        guard !Task.isCancelled, generation == epoch else { return nil }
        let result = image ?? NSWorkspace.shared.icon(forFile: file.url.path)
        cache.setObject(result, forKey: key, cost: Int(140 * 160 * scale * scale * 4))
        return result
    }

    func stop() {
        epoch += 1
        for id in Array(requests.keys) { finish(id, image: nil, cancel: true) }
        cache.removeAllObjects()
    }

    private func finish(_ id: UUID, image: NSImage?, cancel: Bool = false) {
        if let request = requests.removeValue(forKey: id), cancel { QLThumbnailGenerator.shared.cancel(request) }
        continuations.removeValue(forKey: id)?.resume(returning: image)
    }
}
