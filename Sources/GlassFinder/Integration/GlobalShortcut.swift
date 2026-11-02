import Carbon

/// A single registered Carbon hot key avoids monitoring or recording arbitrary keystrokes.
@MainActor
final class GlobalShortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var onToggle: (() -> Void)?
    private(set) var available = false

    func configure(enabled: Bool) {
        stop()
        guard enabled else { return }
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            // Application event handlers run on the main event loop.
            MainActor.assumeIsolated {
                Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue().onToggle?()
            }
            return noErr
        }, 1, &event, pointer, &handler)
        guard status == noErr else { return }
        let id = EventHotKeyID(signature: 0x474C5353, id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_ANSI_G), UInt32(cmdKey | optionKey | controlKey),
                                             id, GetApplicationEventTarget(), 0, &hotKey)
        available = registered == noErr
        if !available { stop() }
    }

    func stop() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
        hotKey = nil
        handler = nil
        available = false
    }
}
