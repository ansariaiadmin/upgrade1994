import sys; sys.path.insert(0,'.')
from core.wiring import assemble
bus, soma, soc = assemble()
goal = "upgrade-style: install a text editor and show it live"
e = soma.budget()
for m in soc["cortex"].plan(goal, e): bus.publish(m)
for name in ("panopticon","hands","echo"):
    for m in bus.drain(name): soc[name].act(m)
print(soc["showcase"].render_frame(1, {
    "cpu": 0.0, "ram": round(soma.sense()["ram_used_gb"],2), "e": e,
    "societies": {k: v.log for k,v in soc.items() if v.log}}))
print("delivered:", bus.delivered)
