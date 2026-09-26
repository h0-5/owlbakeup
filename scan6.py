import os,re,collections
root=r"D:\nta\MTA\server\mods\deathmatch\resources"
keys=collections.Counter()
for dp,dn,fn in os.walk(root):
    if "UIKit" in dp: continue
    for f in fn:
        if not f.endswith(".lua"): continue
        s=open(os.path.join(dp,f),encoding="utf-8",errors="replace").read()
        for m in re.finditer(r"uiGetThemeColor\(\s*[\"']([^\"']+)",s): keys[m.group(1)]+=1
        for m in re.finditer(r"theme\.COLORS\[\s*[\"']([^\"']+)",s): keys[m.group(1)]+=1
        for m in re.finditer(r"uiGetColor\(\s*[\"']([^\"']+)",s): keys["color:"+m.group(1)]+=1
        for m in re.finditer(r"tocolor\((?:uiGetThemeColor\(\s*)?[\"']([a-z_]+)[\"']",s): keys[m.group(1)]+=1
for k,v in keys.most_common(80): print("%-28s %d"%(k,v))
