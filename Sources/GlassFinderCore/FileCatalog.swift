import Foundation

public struct PreviewFile: Identifiable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let modified: Date?
    public let isDirectory: Bool
}

public actor FileCatalog {
    public init() {}

    /// Metadata only: never reads file contents, downloads ubiquitous items, or writes files.
    public func contents(of directory: URL, limit: Int) throws -> [PreviewFile] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .contentModificationDateKey, .isHiddenKey,
                                       .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]
        ).sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        var result: [PreviewFile] = []
        for url in urls {
            try Task.checkCancellation()
            let values = try? url.resourceValues(forKeys: keys)
            result.append(PreviewFile(url: url, modified: values?.contentModificationDate,
                                      isDirectory: values?.isDirectory ?? false))
            if result.count >= max(0, limit) { break }
        }
        return limit > 0 ? result : []
    }
}
