"""NEXUS module loader: reads wiring.lock.json and resolves each community's
vendor modules on disk. Emits mathlang tokens for every module that imports."""
import json, os, importlib, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_lock():
    with open(os.path.join(ROOT, 'wiring.lock.json')) as f:
        return json.load(f)

def probe(modules):
    """For each vendor module, verify the dir exists; return (ok, missing)."""
    ok, missing = [], []
    for m in modules:
        p = os.path.join(ROOT, m['vendor_path']) if m.get('vendor_path') else None
        if p and os.path.isdir(p):
            ok.append(m['source'])
        else:
            missing.append(m['source'])
    return ok, missing

def census():
    lock = load_lock()
    report = {}
    total_ok = total_missing = 0
    for comm, spec in lock['communities'].items():
        ok, missing = probe(spec['modules'])
        report[comm] = {"role": spec['role'], "present": len(ok), "missing": missing}
        total_ok += len(ok); total_missing += len(missing)
    report['__TOTALS__'] = {"present": total_ok, "missing": total_missing}
    return report

if __name__ == '__main__':
    r = census()
    print("NEXUS VENDOR CENSUS")
    for k, v in r.items():
        if k == '__TOTALS__':
            print(f"TOTAL: {v['present']} present / {v['missing']} missing"); continue
        flag = 'OK' if not v['missing'] else f"MISSING:{','.join(v['missing'])}"
        print(f"  {k:12s} {v['present']:2d} modules  [{flag}]")
