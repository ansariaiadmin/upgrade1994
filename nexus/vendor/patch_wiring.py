#!/usr/bin/env python3
"""Single-patch assembler: scans every vendored repo, detects its type
(pyproject/setup.py/package.json/Cargo.toml), and emits vendor/wiring.lock.json
mapping each community -> concrete importable modules + install hooks."""
import json, os, glob

ROOT = os.path.dirname(os.path.abspath(__file__)) + "/.."
manifest = json.load(open(f"{ROOT}/manifest.json"))

def detect(d):
    kind = []
    if os.path.exists(f"{d}/pyproject.toml") or os.path.exists(f"{d}/setup.py"): kind.append("python")
    if os.path.exists(f"{d}/package.json"): kind.append("node")
    if os.path.exists(f"{d}/Cargo.toml"): kind.append("rust")
    # find top-level importable package dirs
    pkgs = [p for p in glob.glob(f"{d}/*/") if os.path.exists(p+"__init__.py")]
    return kind, [os.path.basename(p.rstrip("/")) for p in pkgs][:5]

lock = {"generated_by": "vendor/patch_wiring.py", "communities": {}}
for name, c in manifest["communities"].items():
    entries = []
    for r in c["repos"]:
        d = f"{ROOT}/vendor/git/" + r.replace("/", "_")
        if not os.path.isdir(d + "/.git"): continue
        kind, pkgs = detect(d)
        entries.append({"repo": r, "path": os.path.relpath(d, ROOT), "kinds": kind, "packages": pkgs})
    lock["communities"][name] = {"role": c["role"], "modules": entries}

json.dump(lock, open(f"{ROOT}/vendor/wiring.lock.json", "w"), indent=1)
n = sum(len(v["modules"]) for v in lock["communities"].values())
print(f"patched: {n} wired modules across {len(lock['communities'])} communities")
for k,v in lock["communities"].items():
    print(f"  {k:11s} ({v['role']}): {len(v['modules'])} repos -> {[m['repo'].split('/')[-1] for m in v['modules']][:4]}")
