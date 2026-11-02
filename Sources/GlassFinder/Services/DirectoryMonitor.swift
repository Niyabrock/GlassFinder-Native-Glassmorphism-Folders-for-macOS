import Foundation
import Darwin

final class DirectoryMonitor {
    private var source: DispatchSourceFileSystemObject?

    init?(url: URL, onChange: @escaping @Sendable () -> Void) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write, .delete, .rename, .attrib, .extend], queue: .main)
        source.setEventHandler(handler: onChange)
        source.setCancelHandler { close(descriptor) }
        self.source = source
        source.resume()
    }

    func stop() { source?.cancel(); source = nil }
    deinit { source?.cancel() }
}
