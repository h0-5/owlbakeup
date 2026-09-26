import re, os, sys, collections

BASE = r"D:\nta\MTA\server\mods\deathmatch\resources"
MM = os.path.join(BASE, "main-menu", "c_main.lua")
SB = os.path.join(BASE, "scoreboard", "c_tab.lua")

def scan(path, label):
    if not os.path.exists(path):
        print("MISSING", path); return None
    src = open(path, encoding="utf-8", errors="replace").read()
    calls = re.findall(r"\b(?:eui|exports\.UIKit|exports\[.UIKit.\]):(\w+)", src)
    c = collections.Counter(calls)
    print("=== %s (%d lines) : %d distinct UIKit calls" % (label, src.count("\n")+1, len(c)))
    for k, v in sorted(c.items()):
        print("   %-34s %d" % (k, v))
    return c

a = scan(MM, "main-menu/c_main.lua")
b = scan(SB, "scoreboard/c_tab.lua")
allc = collections.Counter()
if a: allc.update(a)
if b: allc.update(b)
print("")
print("=== COMBINED UIKit API NEEDED (%d) ===" % len(allc))
for k, v in sorted(allc.items()):
    print("  %-34s %d" % (k, v))

p = os.path.join(BASE, "UIKit")
defined = set()
for root, d, fs in os.walk(p):
    for f in fs:
        if f.endswith(".lua"):
            src = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
            defined |= set(re.findall(r"^\s*function\s+([A-Za-z_]\w*)\s*\(", src, re.M))
            defined |= set(re.findall(r"^([A-Za-z_]\w*)\s*=\s*function", src, re.M))
missing = [k for k in allc if k not in defined]
print("")
print("=== DEFINED IN UIKit: %d ; NOT DEFINED: %d ===" % (len(defined), len(missing)))
for k in sorted(missing):
    print("   MISSING:", k)
