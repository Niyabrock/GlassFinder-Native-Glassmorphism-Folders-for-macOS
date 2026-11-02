import Foundation

public struct PreviewFile: Identifiable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let modified: Date?
    public let isDirectory: Bool
}

public struct FolderSnapshot: Sendable {
    public let files: [PreviewFile]
    public let itemCount: Int
}

public actor FileCatalog {
    public init() {}

    /// Metadata only: never reads file contents, downloads ubiquitous items, or writes files.
    public func contents(of directory: URL, limit: Int) throws -> [PreviewFile] {
        try snapshot(of: directory, limit: limit).files
    }

    /// One directory listing feeds the independent count and the bounded preview list.
    /// Counts include hidden immediate children; previews retain Finder-style hidden-file filtering.
    public func snapshot(of directory: URL, limit: Int) throws -> FolderSnapshot {
        try Task.checkCancellation()
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .contentModificationDateKey, .isHiddenKey,
                                       .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]
        let children = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let count = children.count
        try Task.checkCancellation()
        let urls = children.filter { !$0.lastPathComponent.hasPrefix(".") }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        var result: [PreviewFile] = []
        for url in urls.prefix(max(0, limit)) {
            try Task.checkCancellation()
            let values = try? url.resourceValues(forKeys: keys)
            result.append(PreviewFile(url: url, modified: values?.contentModificationDate,
                                      isDirectory: values?.isDirectory ?? false))
        }
        return FolderSnapshot(files: result, itemCount: count)
    }
}
