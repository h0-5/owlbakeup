import os,re,collections
root=r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"
tot=collections.Counter(); per={}
for dp,dn,fn in os.walk(root):
    for f in fn:
        if not f.endswith(".lua"): continue
        p=os.path.join(dp,f); s=open(p,encoding="utf-8",errors="replace").read()
        c={"_FOR_":s.count("_FOR_"),"({})":s.count("({})"),"bare_var":len(re.findall(r"(?<![\w.\"'\[])var\d+\b",s))}
        per[os.path.relpath(p,root)]=c
        for k,v in c.items(): tot[k]+=v
for k in sorted(per):
    c=per[k]
    if sum(c.values()): print("%-42s FOR=%-3d tbl=%-3d var=%d"%(k,c["_FOR_"],c["({})"],c["bare_var"]))
print("TOTALS",dict(tot))
