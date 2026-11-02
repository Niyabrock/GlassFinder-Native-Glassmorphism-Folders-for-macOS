# Desktop and Finder integration

The shipped target is a standalone native folder browser. It draws in its own window and opens actual directories in Finder. It never changes Finder preferences, folder icons, extended attributes, wallpaper, or source content.

Master OFF cancels thumbnail requests, invalidates pending loads, releases scoped folder access, cancels directory watchers, clears the thumbnail cache and selection, and shows normal system icons. The optional toggle hot key remains registered so it can turn the effect back on. Launch at Login is independent. Quit tears down all in-process resources; there is no permanent visual change to undo.

## Desktop feasibility

AppKit can create transparent windows; Accessibility can expose some Finder UI after user consent. Neither API offers a stable contract binding every desktop icon's rendering/frame to its filesystem URL, nor a way to hide just its graphic while preserving Finder's label and hit testing. An overlay must handle icon rearrangement, z-order, Spaces, display scaling, wallpaper changes and event forwarding. A click-through window cannot also reliably receive the folder's native pointer events. Stale bounds risk covering unrelated content.

No desktop overlay is activated. No Accessibility permission is requested. Add Desktop folders to the prototype instead. A future opt-in experiment needs verified URL/frame mapping, multi-monitor/Space handling, event forwarding and immediate teardown. It must not modify icons or protected files to simulate success.

## Finder-window feasibility

[Finder Sync](https://developer.apple.com/documentation/findersync) supports badges, contextual menus, toolbar items and monitored directory status. It offers no arbitrary animated icon or hover render surface. [AXUIElement](https://developer.apple.com/documentation/applicationservices/axuielement) is an automation interface, not a rendering extension. Window overlays add scrolling, tabs, view modes, occlusion, focus and reused elements to the desktop problems. A Finder Sync extension would not deliver this requirement and is omitted.

Finder injection, SIP changes and patching protected files are excluded. The safe alternative is browsing chosen folders in GlassFinder and opening them in Finder. Both integration statuses are explicitly inactive in Settings. These conclusions describe public API boundaries, not a live macOS Accessibility experiment on this Linux host.
