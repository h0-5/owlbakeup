import re
for p in [r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit\core\c_process.lua",
          r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit\ui-elements\c_edit.lua"]:
    print("="*20,p)
    s=open(p,encoding="utf-8",errors="replace").read().split("\n")
    for i,l in enumerate(s,1):
        if re.search(r"(?<![\w.\"'])(var[0-9]+)\s*[\(\[=]",l):
            print("%5d| %s"%(i,l.rstrip()[:190]))
