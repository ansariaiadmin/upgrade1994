#!/usr/bin/env python3
"""Parallel batched git clone for the NEXUS vendor manifest.
Batches of 6 keep memory (2GB) safe; each repo is depth-1 shallow."""
import json, subprocess, shutil, os, sys
from concurrent.futures import ThreadPoolExecutor, as_completed

os.chdir(os.path.dirname(os.path.abspath(__file__)) + "/..")
def repos():
    m = json.load(open("manifest.json")); seen=set(); out=[]
    for c in m["communities"].values():
        for r in c["repos"]:
            if r not in seen: seen.add(r); out.append(r)
    return out

def clone(n):
    d = "vendor/git/" + n.replace("/", "_")
    if os.path.isdir(d + "/.git"): return (n, "cached")
    shutil.rmtree(d, ignore_errors=True)
    try:
        p = subprocess.run(["git","clone","--depth","1","--single-branch","--quiet",
                            f"https://github.com/{n}", d],
                           capture_output=True, text=True, timeout=300,
                           env={**os.environ,"GIT_TERMINAL_PROMPT":"0"})
        if p.returncode == 0: return (n, "ok")
        shutil.rmtree(d, ignore_errors=True)
        return (n, "fail:" + p.stderr.strip().splitlines()[-1][:80] if p.stderr else "fail")
    except subprocess.TimeoutExpired:
        shutil.rmtree(d, ignore_errors=True); return (n, "timeout")

if __name__ == "__main__":
    rs = repos(); done = 0
    with open("logs/clone_report.txt","w") as rep:
        with ThreadPoolExecutor(max_workers=6) as ex:
            futs = {ex.submit(clone, r): r for r in rs}
            for f in as_completed(futs):
                n, st = f.result(); done += 1
                line = f"[{done}/{len(rs)}] {st:6s} {n}"
                print(line, flush=True); rep.write(line+"\n"); rep.flush()
