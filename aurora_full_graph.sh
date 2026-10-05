#!/usr/bin/env bash
# ============================================================
# Aurora Full Dependency Graph Generator (FIXED)
# ============================================================

set -u

PROJECT="/home/ai/project/aurora-platform"
OUT="$HOME/Desktop/aurora_graph_$(date +%Y%m%d_%H%M)"
PY="$PROJECT/.venv/bin/python"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

echo -e "${G}=== Aurora Full Graph Generator ===${N}"
echo "Project: $PROJECT"
echo "Output : $OUT"
echo ""

mkdir -p "$OUT"
cd "$PROJECT" || exit 1

# ============================================================
# PART 1 — FULL FILE TREE
# ============================================================
echo -e "${Y}[1/6] Building full file tree...${N}"

{
echo "# Aurora Full File Tree"
echo "# Generated: $(date -Iseconds)"
echo ""
echo "## ALL FILES BY TYPE"
echo ""
echo "### Python (.py):"
find . -name "*.py" -not -path "./.venv/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" -not -path "*/.cache/*" -not -path "./core/pool-*" -not -path "*/growth-lab-sandbox/*" 2>/dev/null | sort
echo ""
echo "### TypeScript/React (.tsx/.ts):"
find . \( -name "*.tsx" -o -name "*.ts" \) -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "./.venv/*" 2>/dev/null | sort
echo ""
echo "### JavaScript (.js/.mjs):"
find . \( -name "*.js" -o -name "*.mjs" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | sort
echo ""
echo "### Markdown (.md):"
find . -name "*.md" -not -path "*/node_modules/*" -not -path "./.venv/*" -not -path "*/.cache/*" 2>/dev/null | sort
echo ""
echo "### JSON (config/data):"
find . -name "*.json" -not -path "*/node_modules/*" -not -path "./.venv/*" -not -path "*/.cache/*" -not -path "*/graphify-out/*" 2>/dev/null | sort
echo ""
echo "### Shell (.sh):"
find . -name "*.sh" -not -path "*/node_modules/*" -not -path "./.venv/*" 2>/dev/null | sort
echo ""
echo "### YAML/TOML:"
find . \( -name "*.yml" -o -name "*.yaml" -o -name "*.toml" \) -not -path "*/node_modules/*" -not -path "./.venv/*" 2>/dev/null | sort
} > "$OUT/01_file_tree.txt"

echo "  → $(wc -l < "$OUT/01_file_tree.txt") lines"

# ============================================================
# PART 2 — PYTHON IMPORT GRAPH
# ============================================================
echo -e "${Y}[2/6] Analyzing Python imports...${N}"

"$PY" - "$OUT/02_import_graph.txt" <<'PYEOF'
import ast, sys
from pathlib import Path
from collections import defaultdict, Counter

out_path = Path(sys.argv[1])
PROJECT = Path("/home/ai/project/aurora-platform")
SKIP = {'.venv', '__pycache__', 'node_modules', '.next', '.cache',
        'pool-0', 'pool-1', 'pool-2', 'pool-3', 'pool-4', 'pool-5', 'pool-6', 'pool-7',
        'growth-lab-sandbox', 'clones', 'labs', 'libraries', 'rag',
        'graphify-out', 'tmp_api_state', 'audit-out', 'artifacts'}

def should_skip(p):
    return any(s in p.parts for s in SKIP)

py_files = []
for p in PROJECT.rglob("*.py"):
    if should_skip(p):
        continue
    py_files.append(p)

lines = []
lines.append(f"Total Python files analyzed: {len(py_files)}")
lines.append("")

imports = defaultdict(set)
imported_by = defaultdict(set)
all_imports = Counter()
errors = []

def path_to_module(p):
    rel = p.relative_to(PROJECT)
    parts = list(rel.with_suffix('').parts)
    if parts and parts[-1] == '__init__':
        parts = parts[:-1]
    return '.'.join(parts)

for py_file in py_files:
    mod = path_to_module(py_file)
    try:
        tree = ast.parse(py_file.read_text(errors='ignore'))
    except Exception as e:
        errors.append((str(py_file), str(e)[:80]))
        continue
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports[mod].add(alias.name)
                all_imports[alias.name] += 1
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports[mod].add(node.module)
                all_imports[node.module] += 1

for src, targets in imports.items():
    for t in targets:
        imported_by[t].add(src)

lines.append("=" * 60)
lines.append("TOP 50 MOST-IMPORTED MODULES (external + internal)")
lines.append("=" * 60)
for name, count in all_imports.most_common(50):
    lines.append(f"  {count:4d}  {name}")

lines.append("")
lines.append("=" * 60)
lines.append("TOP 30 MODULES BY OUT-DEGREE (most imports)")
lines.append("=" * 60)
top_out = sorted(imports.items(), key=lambda x: -len(x[1]))[:30]
for name, targets in top_out:
    lines.append(f"  {len(targets):4d}  {name}")

lines.append("")
lines.append("=" * 60)
lines.append("TOP 30 MODULES BY IN-DEGREE (most imported)")
lines.append("=" * 60)
top_in = sorted(imported_by.items(), key=lambda x: -len(x[1]))[:30]
for name, sources in top_in:
    lines.append(f"  {len(sources):4d}  {name}")

lines.append("")
lines.append("=" * 60)
lines.append("INTERNAL MODULES (robots.* / core.*) — imported counts")
lines.append("=" * 60)
internal = {k: v for k, v in all_imports.items() if k.startswith(('robots.', 'core.'))}
for name, count in sorted(internal.items(), key=lambda x: -x[1])[:80]:
    lines.append(f"  {count:4d}  {name}")

lines.append("")
lines.append("=" * 60)
lines.append("ORPHAN MODULES (defined but never imported)")
lines.append("=" * 60)
all_defined = set()
for py_file in py_files:
    all_defined.add(path_to_module(py_file))
orphans = []
for mod in sorted(all_defined):
    if not any(mod == k or k.endswith('.' + mod) or mod.endswith('.' + k) for k in all_imports):
        if 'test' in mod.lower() or mod.endswith('__init__') or mod.endswith('__main__'):
            continue
        orphans.append(mod)
lines.append(f"Potential orphans: {len(orphans)}")
for o in orphans[:100]:
    lines.append(f"  {o}")

lines.append("")
lines.append("=" * 60)
lines.append("PARSE ERRORS")
lines.append("=" * 60)
for f, e in errors[:30]:
    lines.append(f"  {f}: {e}")

out_path.write_text("\n".join(lines))
print(f"Wrote {out_path}: {len(lines)} lines")
PYEOF

echo "  → $(wc -l < "$OUT/02_import_graph.txt") lines"

# ============================================================
# PART 3 — DEPENDENCY MATRIX
# ============================================================
echo -e "${Y}[3/6] Building dependency matrix...${N}"

"$PY" - "$OUT/03_dependency_matrix.txt" <<'PYEOF'
import ast, sys
from pathlib import Path
from collections import defaultdict

out_path = Path(sys.argv[1])
PROJECT = Path("/home/ai/project/aurora-platform")
SKIP = {'.venv', '__pycache__', 'node_modules', '.next', '.cache',
        'pool-0', 'pool-1', 'pool-2', 'pool-3', 'pool-4', 'pool-5', 'pool-6', 'pool-7',
        'growth-lab-sandbox', 'clones', 'labs', 'libraries', 'rag',
        'graphify-out', 'tmp_api_state'}

def should_skip(p):
    return any(s in p.parts for s in SKIP)

mod_to_path = {}
for p in PROJECT.rglob("*.py"):
    if should_skip(p):
        continue
    rel = p.relative_to(PROJECT)
    parts = list(rel.with_suffix('').parts)
    if parts and parts[-1] == '__init__':
        parts = parts[:-1]
    mod = '.'.join(parts)
    mod_to_path[mod] = p

graph = defaultdict(set)
for mod, path in mod_to_path.items():
    try:
        tree = ast.parse(path.read_text(errors='ignore'))
    except Exception:
        continue
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and node.module:
            if node.module.startswith(('robots.', 'core.')) or node.module in mod_to_path:
                graph[mod].add(node.module)
        elif isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.startswith(('robots.', 'core.')) or alias.name in mod_to_path:
                    graph[mod].add(alias.name)

lines = []
lines.append("=" * 60)
lines.append("CORE/ROBOTS/* DEPENDENCIES")
lines.append("=" * 60)
for mod in sorted(graph.keys()):
    if 'robots.' in mod or mod.startswith('core.'):
        deps = sorted(graph[mod])
        if deps:
            lines.append(f"{mod}")
            for d in deps:
                lines.append(f"    → {d}")
            lines.append("")

out_path.write_text("\n".join(lines))
print(f"Wrote {out_path}: {len(lines)} lines")
PYEOF

echo "  → $(wc -l < "$OUT/03_dependency_matrix.txt") lines"

# ============================================================
# PART 4 — SIZE ANALYSIS
# ============================================================
echo -e "${Y}[4/6] Analyzing module sizes...${N}"

{
echo "# Module Size Analysis"
echo ""
echo "## TOP 100 LARGEST PYTHON FILES (by LOC)"
echo ""
find . -name "*.py" \
    -not -path "./.venv/*" -not -path "*/__pycache__/*" \
    -not -path "*/node_modules/*" -not -path "*/.cache/*" \
    -not -path "./core/pool-*" -not -path "*/growth-lab-sandbox/*" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -101
echo ""
echo "## TOP 50 LARGEST TSX/TS FILES"
echo ""
find . \( -name "*.tsx" -o -name "*.ts" \) \
    -not -path "*/node_modules/*" -not -path "*/.next/*" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -51
echo ""
echo "## TOP 50 LARGEST MD FILES"
echo ""
find . -name "*.md" \
    -not -path "*/node_modules/*" -not -path "./.venv/*" -not -path "*/.cache/*" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -51
} > "$OUT/04_size_analysis.txt"

echo "  → $(wc -l < "$OUT/04_size_analysis.txt") lines"

# ============================================================
# PART 5 — CLEAN TREE
# ============================================================
echo -e "${Y}[5/6] Building clean directory tree...${N}"

if command -v tree >/dev/null 2>&1; then
    tree -L 4 -I '.venv|__pycache__|node_modules|.next|.cache|pool-*|growth-lab-sandbox|clones|labs|libraries|graphify-out|tmp_api_state|.git|.pytest_cache|.ruff_cache' \
        --dirsfirst \
        > "$OUT/05_clean_tree.txt" 2>&1
else
    find . -maxdepth 4 -type d \
        -not -path "./.venv*" -not -path "*/__pycache__*" \
        -not -path "*/node_modules*" -not -path "*/.next*" \
        -not -path "*/.cache*" -not -path "./core/pool-*" \
        -not -path "*/growth-lab-sandbox*" -not -path "*/.git*" \
        2>/dev/null | sort > "$OUT/05_clean_tree.txt"
fi

echo "  → $(wc -l < "$OUT/05_clean_tree.txt") lines"

# ============================================================
# PART 6 — HTML VISUALIZATION (FIXED)
# ============================================================
echo -e "${Y}[6/6] Building interactive HTML graph...${N}"

"$PY" - "$OUT/06_import_graph.html" <<'PYEOF'
import ast, json, sys
from pathlib import Path
from collections import defaultdict

out_path = Path(sys.argv[1])
PROJECT = Path("/home/ai/project/aurora-platform")
SKIP = {'.venv', '__pycache__', 'node_modules', '.next', '.cache',
        'pool-0', 'pool-1', 'pool-2', 'pool-3', 'pool-4', 'pool-5', 'pool-6', 'pool-7',
        'growth-lab-sandbox', 'clones', 'labs', 'libraries', 'rag',
        'graphify-out', 'tmp_api_state'}

def should_skip(p):
    return any(s in p.parts for s in SKIP)

nodes = []
edges = []
node_ids = {}
node_id_counter = [0]

def get_id(path):
    if path not in node_ids:
        node_ids[path] = node_id_counter[0]
        node_id_counter[0] += 1
    return node_ids[path]

py_files = {}
for p in PROJECT.rglob("*.py"):
    if should_skip(p):
        continue
    rel = p.relative_to(PROJECT)
    parts = list(rel.with_suffix('').parts)
    if parts and parts[-1] == '__init__':
        parts = parts[:-1]
    mod = '.'.join(parts)
    py_files[mod] = p
    try:
        loc = len(p.read_text(errors='ignore').splitlines())
    except Exception:
        loc = 0
    nodes.append({
        "id": get_id(str(p)),
        "label": mod,
        "loc": loc,
        "group": parts[0] if parts else "root",
    })

for mod, path in py_files.items():
    try:
        tree = ast.parse(path.read_text(errors='ignore'))
    except Exception:
        continue
    src_id = node_ids[str(path)]
    for node in ast.walk(tree):
        target_mod = None
        if isinstance(node, ast.ImportFrom) and node.module:
            target_mod = node.module
        elif isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name in py_files:
                    target_mod = alias.name
                    break
        if target_mod and target_mod in py_files:
            tgt_id = node_ids[str(py_files[target_mod])]
            edges.append({"from": src_id, "to": tgt_id})

html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Aurora Import Graph</title>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
body { margin:0; background:#0d1117; color:#c9d1d9; font-family:sans-serif; }
#graph { width:100vw; height:100vh; }
#info { position:fixed; top:10px; left:10px; background:#161b22; padding:10px; border-radius:6px; z-index:100; }
#search { padding:5px; margin-top:5px; width:250px; background:#0d1117; color:#c9d1d9; border:1px solid #30363d; }
</style>
</head>
<body>
<div id="info">
  <b>Aurora Import Graph</b><br>
  <span id="stats"></span><br>
  <input id="search" placeholder="Search node...">
</div>
<div id="graph"></div>
<script>
const nodes = new vis.DataSet(""" + json.dumps(nodes) + """);
const edges = new vis.DataSet(""" + json.dumps(edges) + """);

const groups = {};
nodes.get().forEach(n => {
  if (!groups[n.group]) groups[n.group] = { color: 'hsl(' + (Object.keys(groups).length * 47) % 360 + ',70%,60%)' };
  n.color = groups[n.group].color;
  n.title = n.label + ' (' + n.loc + ' LOC)';
  n.value = Math.max(1, Math.log(n.loc + 1)) * 3;
});

const data = { nodes, edges };
const options = {
  nodes: { shape:'dot', font:{color:'#c9d1d9'} },
  edges: { arrows:'to', color:{color:'#30363d', opacity:0.5}, smooth:false },
  physics: { stabilization: { iterations: 200 }, barnesHut: { gravitationalConstant: -8000 } },
  interaction: { hover: true, tooltipDelay: 100 }
};
const network = new vis.Network(document.getElementById('graph'), data, options);
document.getElementById('stats').textContent = nodes.length + ' nodes, ' + edges.length + ' edges';

document.getElementById('search').addEventListener('input', e => {
  const q = e.target.value.toLowerCase();
  if (!q) { network.unselectAll(); return; }
  const match = nodes.get().find(n => n.label.toLowerCase().includes(q));
  if (match) { network.selectNodes([match.id]); network.focus(match.id, {scale:1.5, animation:true}); }
});
</script>
</body>
</html>
"""

out_path.write_text(html)
print(f"HTML written: {out_path}")
print(f"Nodes: {len(nodes)}, Edges: {len(edges)}")
PYEOF

echo "  → HTML ready"

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo -e "${G}============================================${N}"
echo -e "${G}DONE${N}"
echo -e "${G}============================================${N}"
echo "Output: $OUT"
echo ""
ls -lh "$OUT/"
echo ""
echo "Open the HTML in browser:"
echo "  firefox $OUT/06_import_graph.html"
echo ""
echo "Total size:"
du -sh "$OUT"
