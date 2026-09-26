import os,re,collections
root=r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"
c=collections.Counter()
for dp,dn,fn in os.walk(root):
    for f in fn:
        if not f.endswith(".lua"): continue
        s=open(os.path.join(dp,f),encoding="utf-8",errors="replace").read()
        for m in re.finditer(r"uiGetThemeColor\(\s*([^)\n]{0,60})",s): c["T:"+m.group(1).strip()]+=1
        for m in re.finditer(r"uiGetColor\(\s*([^)\n]{0,60})",s): c["C:"+m.group(1).strip()]+=1
for k,v in c.most_common(60): print("%-46s %d"%(k,v))
