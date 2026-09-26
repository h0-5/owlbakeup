import os,re,collections
root=r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"
k=collections.Counter()
for dp,dn,fn in os.walk(root):
    for f in fn:
        if not f.endswith(".lua"): continue
        s=open(os.path.join(dp,f),encoding="utf-8",errors="replace").read()
        for m in re.finditer(r"theme\.COLORS\[\s*[\"']?([\w]+)",s): k[m.group(1)]+=1
        for m in re.finditer(r"uiGetThemeColor\(\s*[\"']?([\w]+)",s): k[m.group(1)]+=1
        for m in re.finditer(r"uiGetColor\(\s*[\"']?([\w]+)",s): k[m.group(1)]+=1
print(" ".join("%s(%d)"%(a,b) for a,b in k.most_common()))
