import os,re
root=r"D:\nta\MTA\server\mods\deathmatch\resources\UIKit"
files=[];src={}
for dp,dn,fn in os.walk(root):
    for f in fn:
        if f.endswith(".lua"):
            p=os.path.join(dp,f);files.append(p);src[p]=open(p,encoding="utf-8",errors="replace").read()
all_text="\n".join(src.values())
defined=set()
for p,s in src.items():
    for m in re.finditer(r"^\s*(?:local\s+)?function\s+([A-Za-z_][\w.:]*)",s,re.M): defined.add(m.group(1).split(".")[-1])
    for m in re.finditer(r"^\s*([A-Za-z_][\w]*)\s*=",s,re.M): defined.add(m.group(1))
    for m in re.finditer(r"\bUI\.[A-Za-z_]\w*\s*=\s*",s): defined.add(m.group(0).split(".")[1])
# varN used as function call  ->  varN(...)
calls={}
for p,s in src.items():
    for m in re.finditer(r"(?<![\w.\"'])(var\d+)\s*\(",s):
        calls.setdefault(m.group(1),set()).add(os.path.relpath(p,root))
# varN indexed -> varN[...]
idx={}
for p,s in src.items():
    for m in re.finditer(r"(?<![\w.\"'])(var\d+)\s*\[",s):
        idx.setdefault(m.group(1),set()).add(os.path.relpath(p,root))
print("--- varN CALLED as function ---")
for k in sorted(calls,key=lambda x:int(x[3:])): print("  %-7s %s"%(k,sorted(calls[k])))
print("--- varN INDEXED ---")
for k in sorted(idx,key=lambda x:int(x[3:])): print("  %-7s %s"%(k,sorted(idx[k])))
