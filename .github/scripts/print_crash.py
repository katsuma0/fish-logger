"""Prints the exception, the app's crash message and the crashed thread from .ips crash reports.

Usage: python3 print_crash.py report.ips [...]
"""
import json
import sys


def show(path):
    with open(path, encoding="utf-8", errors="replace") as handle:
        text = handle.read()
    # An .ips file is a one-line JSON header followed by the JSON report.
    _, _, body = text.partition("\n")
    try:
        report = json.loads(body)
    except json.JSONDecodeError:
        print(text[:4000])
        return
    print(f"== {path}")
    for key in ("exception", "termination", "asi"):
        if key in report:
            print(f"{key}: {json.dumps(report[key])[:1500]}")
    images = report.get("usedImages", [])
    for thread in report.get("threads", []):
        if not thread.get("triggered"):
            continue
        print(f"crashed thread: {thread.get('name') or thread.get('queue') or thread.get('id')}")
        for frame in thread.get("frames", [])[:30]:
            index = frame.get("imageIndex")
            image = images[index].get("name", "?") if isinstance(index, int) and index < len(images) else "?"
            symbol = frame.get("symbol", "?")
            where = f" {frame['sourceFile']}:{frame.get('sourceLine')}" if "sourceFile" in frame else ""
            print(f"    {image}  {symbol}{where}")


for argument in sys.argv[1:]:
    show(argument)
