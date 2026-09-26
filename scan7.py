import re
p=r"C:\Users\mohmm\Downloads\4mTE4d3\[rp]\main-menu\client_decompiled.lua"
s=open(p,encoding="utf-8",errors="replace").read()
fns=sorted(set(re.findall(r"eui:(\w+)",s)))
print("eui calls:"," ".join(fns))
print()
print("other exports:",sorted(set(re.findall(r"exports\[?[\"']?([\w-]+)[\"']?\]?[:.](\w+)",s))))
