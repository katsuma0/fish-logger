"""Prints each failed test with its failure messages, from `xcresulttool get test-results tests` JSON on stdin.

The raw log only says a test failed; the result bundle says why, including crash messages.
"""
import json
import sys


def walk(node, path):
    name = node.get("name", "")
    kind = node.get("nodeType", "")
    children = node.get("children", [])
    if kind == "Test Case" and node.get("result") == "Failed":
        print(f"FAILED {'/'.join(path + [name])}")
        for child in children:
            if child.get("nodeType") != "Test Case":
                print(f"    {child.get('nodeType')}: {child.get('name')}")
    for child in children:
        walk(child, path + [name] if kind in ("Test Suite", "Test Case") else path)


data = json.load(sys.stdin)
for node in data.get("testNodes", []):
    walk(node, [])
