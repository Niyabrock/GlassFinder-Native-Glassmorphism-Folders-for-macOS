#!/usr/bin/env python3
"""Portable packaging checks; these do not substitute for a macOS build."""
import pathlib
import plistlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
with (root / "Resources/Info.plist").open("rb") as handle:
    info = plistlib.load(handle)
assert info["LSMinimumSystemVersion"] == "14.5"
assert info["CFBundleExecutable"] == "GlassFinder"
assert info["CFBundleIdentifier"] == "com.glassfinder.app"
sources = list((root / "Sources").rglob("*.swift"))
assert len(sources) >= 10
assert sum("@main" in source.read_text() for source in sources) == 1
package = (root / "Package.swift").read_text()
for target in ["GlassFinder", "GlassFinderCore", "GlassFinderCoreTests"]:
    assert re.search(r'name: "' + target + '"', package)
assert "14.5" in package
print(f"Packaging metadata valid; {len(sources)} Swift source files found.")
