"""Report the decompiler damage in a UIKit-like resource.

The Owl decompiler turned every local into `varN` and every table literal into
`({})[...]`. Where a `varN` is *called* it was a function that the decompiler
could not name, so the port has to give that function a real name back.
This script lists those call sites so they can be mapped deliberately.
"""
import os
import re
import sys

IDENT = re.compile(r"\b[A-Za-z_]\w*\b")
CALL = re.compile(r"\b([A-Za-z_]\w*)\s*\(")


def strip_noise(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith("--[[", i):
            j = src.find("]]", i)
            i = n if j < 0 else j + 2
            continue
        if src.startswith("--", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            i = n if j < 0 else j + len(close)
            continue
        c = src[i]
        if c in "\"'":
            q, j = c, i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == q:
                    break
                j += 1
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def scan_file(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    src = strip_noise(raw)

    # names the file itself defines
    defined = set()
    for m in re.finditer(r"\bfunction\s+([A-Za-z_][\w.:]*)", src):
        defined.add(m.group(1).split(".")[-1].split(":")[-1])
    for m in re.finditer(r"\blocal\s+([A-Za-z_]\w*)", src):
        defined.add(m.group(1))
    for m in re.finditer(r"([A-Za-z_]\w*)\s*=", src):
        defined.add(m.group(1))
    for m in re.finditer(r"\bfor\s+([A-Za-z_]\w*)", src):
        defined.add(m.group(1))

    problems = []

    # 1. undefined varN used as a function  -> lost function name
    for i, line in enumerate(src.split("\n"), 1):
        for name in CALL.findall(line):
            if re.fullmatch(r"var\d+", name) and name not in defined:
                problems.append((i, f"call to lost function `{name}`"))

    # 2. decompiler table-literal artifacts
    for i, line in enumerate(src.split("\n"), 1):
        if re.search(r"\(\{\}\)\s*\[", line) or re.search(r"^\s*;\(\{\}\)", line):
            problems.append((i, "table-literal artifact `({})`"))

    # 3. leftover decompiler loop variables
    for i, line in enumerate(src.split("\n"), 1):
        if re.search(r"\bforvar\d+\b", line):
            problems.append((i, "leftover `forvar` loop variable"))

    return problems, len(src.split("\n"))


if __name__ == "__main__":
    root = sys.argv[1]
    total = 0
    files = 0
    for dirpath, _, names in os.walk(root):
        for name in sorted(names):
            if not name.endswith(".lua"):
                continue
            path = os.path.join(dirpath, name)
            probs, lines = scan_file(path)
            if probs:
                files += 1
                total += len(probs)
                rel = os.path.relpath(path, root)
                print(f"\n{rel}  ({lines} lines, {len(probs)} issues)")
                for line_no, msg in probs[:12]:
                    print(f"   L{line_no}: {msg}")
                if len(probs) > 12:
                    print(f"   ... and {len(probs) - 12} more")
    print(f"\n=== {files} file(s) with issues, {total} issues total ===")
