#!/usr/bin/env bash
# NEXUS vendor bootstrap: clones all wired repos (depth-1) from wiring.lock.json.
# Usage: bash nexus/vendor/clone.sh   (run once on any laptop; idempotent)
set -u
cd "$(dirname "$0")/.."        # -> nexus/
export GIT_TERMINAL_PROMPT=0
python3 - <<'EOF'
import json, os, subprocess
lock = json.load(open('wiring.lock.json'))
seen = set()
for comm, spec in lock['communities'].items():
    for m in spec['modules']:
        p = m.get('vendor_path')
        if not p or p in seen or m['status'] != 'cloned': continue
        seen.add(p)
        if os.path.isdir(os.path.join(p, '.git')):
            print(f"[skip] {p}"); continue
        url = "https://github.com/" + m['source'] + ".git"
        r = subprocess.run(["git","clone","--depth","1",url,p],
                           capture_output=True, text=True)
        print(("[ok]  " if r.returncode==0 else "[FAIL]") + f" {p}")
print(f"done: {len(seen)} modules")
EOF
