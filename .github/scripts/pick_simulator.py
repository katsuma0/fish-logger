"""Prints the UDID of an available iPhone simulator on the newest iOS runtime."""
import json
import sys

devices = json.load(sys.stdin)["devices"]
best = None
for runtime, entries in devices.items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in runtime.split(".iOS-")[-1].split("-"))
    for device in entries:
        if not device.get("isAvailable", True) or not device["name"].startswith("iPhone"):
            continue
        # Prefer the newest runtime, then plain models over Plus/Pro Max for speed.
        key = (version, -len(device["name"]))
        if best is None or key > best[0]:
            best = (key, device["udid"], device["name"])

if best is None:
    sys.exit("No iPhone simulator available")
print(f"Using {best[2]} on iOS {'.'.join(map(str, best[0][0]))}", file=sys.stderr)
print(best[1])
