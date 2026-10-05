#!/usr/bin/env bash
# Parallel shallow-clone of all manifest repos into vendor/git/<name>
set -u
mkdir -p vendor/git logs
python3 - <<'PY' > /tmp/repos.txt
import json
m=json.load(open('manifest.json'))
seen=set()
for c in m['communities'].values():
    for r in c['repos']:
        if r not in seen: seen.add(r); print(r)
PY
wc -l < /tmp/repos.txt
cat /tmp/repos.txt | xargs -P 8 -I{} bash -c \
  'n="{}"; d="vendor/git/${n//\//_}"; git clone --depth 1 --quiet "https://github.com/$n" "$d" >>logs/clone.log 2>&1 || echo "FAIL $n" >>logs/clone_fail.log'
echo "done: $(ls vendor/git | wc -l) cloned, $(wc -l < logs/clone_fail.log 2>/dev/null || echo 0) failed"
du -sh vendor/git
