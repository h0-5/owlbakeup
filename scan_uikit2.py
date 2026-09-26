import os, re, io, sys

ROOT = r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"

pat_varfn   = re.compile(r"\bvar(\d+)\s*\(")
pat_barevar = re.compile(r"(?<![\w.])var(\d+)(?![\w(])")
pat_table   = re.compile(r"\(\{\}\)")
pat_brace   = re.compile(r"#\s*\{")
pat_unders  = re.compile(r"_FOR_")
pat_tcol    = re.compile(r"tocolor\(\s*tocolor\(")

rows = []
for dp, dn, fn in os.walk(ROOT):
    for f in fn:
        if not f.endswith(".lua"):
            continue
        p = os.path.join(dp, f)
        rel = os.path.relpath(p, ROOT)
        txt = open(p, encoding="utf-8", errors="replace").read()
        for i, ln in enumerate(txt.split("\n"), 1):
            hits = []
            for m in pat_varfn.finditer(ln):
                hits.append("CALL var" + m.group(1))
            for m in pat_barevar.finditer(ln):
                hits.append("BARE var" + m.group(1))
            if pat_table.search(ln):
                hits.append("TABLE")
            if pat_brace.search(ln):
                hits.append("BRACE")
            if pat_unders.search(ln):
                hits.append("UNDER")
            if pat_tcol.search(ln):
                hits.append("TCOLOR")
            if hits:
                rows.append((rel, i, ",".join(sorted(set(hits))), ln.strip()[:150]))

out = io.StringIO()
out.write("TOTAL: %d\n" % len(rows))
byfile = {}
for rel, i, h, ln in rows:
    byfile.setdefault(rel, []).append((i, h, ln))
for rel in sorted(byfile):
    out.write("\n===== %s (%d)\n" % (rel, len(byfile[rel])))
    for i, h, ln in byfile[rel]:
        out.write("%5d [%s] %s\n" % (i, h, ln))
print(out.getvalue())
