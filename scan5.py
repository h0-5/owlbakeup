import os,re
root=r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"
for dp,dn,fn in os.walk(root):
    for f in sorted(fn):
        if not f.endswith(".lua"): continue
        p=os.path.join(dp,f)
        for i,l in enumerate(open(p,encoding="utf-8",errors="replace").read().split("\n"),1):
            if "_FOR_" in l or "({})" in l:
                print("%s:%d"%(os.path.relpath(p,root),i))
                print("   ",l.rstrip()[:200])
