# AURORA PLATFORM — COMPLETE ARCHITECTURE GRAPH

> **Single-file project bible.** Everything a model needs to understand this codebase end-to-end.
> All numbers below were extracted from the live repository, not estimated.
>
> Generated: 2026-10-04 · HEAD: `9181bbf` · Python 3.12.3 · Platform: Ubuntu 24.04

---

## TABLE OF CONTENTS

1. [What Aurora Is](#1-what-aurora-is)
2. [Hard Numbers](#2-hard-numbers)
3. [The Real Tree](#3-the-real-tree)
4. [The Import Spine](#4-the-import-spine)
5. [Runtime Data Flow](#5-runtime-data-flow)
6. [The 44 Societies](#6-the-44-societies)
7. [The 28 Extension Workers](#7-the-28-extension-workers)
8. [Data Stores](#8-data-stores)
9. [The API Surface — 347 Endpoints](#9-the-api-surface--347-endpoints)
10. [Governance & Safety Stack](#10-governance--safety-stack)
11. [The Evolutionary Pipeline](#11-the-evolutionary-pipeline)
12. [How To Run Everything](#12-how-to-run-everything)
13. [The Test Surface](#13-the-test-surface)
14. [Known Architectural Debts](#14-known-architectural-debts)
15. [Reading Order for a New Model](#15-reading-order-for-a-new-model)

---

## 1. WHAT AURORA IS

Aurora is a **multi-society autonomous agent platform**. It is not a chatbot and not a CRUD app.

The core idea: **44 specialised "societies"**, each with its own agents, workers, skills, and domain knowledge, orchestrated by a meta-society (`aurora-core`) that routes work across them. Work is planned as a **DAG**, staged in **isolated sandboxes**, verified against **unanimous review-board consensus**, and only then promoted to the live roster by the owner.

Two laws govern the whole system:

> **Builder law** — a society/cell identifier is always `{cell}-{name}`. Never a free-form id.
> **Owner law** — nothing self-modifies. The lab proposes; the owner (main leader) disposes.

```
USER ──▶ FastAPI (347 endpoints)
            │
            ▼
      AuroraMetaSociety ──── meta-orchestrator (44 societies)
            │
            ├── CapabilityPlanner   (729 capability tokens → DAG plan)
            ├── AssemblyOrchestrator(parallel per-society execution)
            ├── GrowthLab            (sandbox → gates → promote)
            ├── SocietyRegistry      (derived catalogue, never hand-maintained)
            │
            ▼
      MemoryKV (state) + EventBus (SSE) + Blackboard (evolution DAG)
```

---

## 2. HARD NUMBERS

Every figure below is measured, not guessed.

| Metric | Value | Source of truth |
|--------|-------|-----------------|
| Python files (total) | **845** | `find core api -name "*.py"` |
| Python files (core/) | 714 | — |
| Python files (api/) | 131 | — |
| Lines of code (core/) | **151,049** | `wc -l` |
| Test files (core/tests/) | 255 | — |
| Societies | **44** | `AuroraMetaSociety.societies` |
| Agents (total across societies) | **234** | `sum(len(s.agents))` |
| Workers declared (on society rosters) | **160** | `sum(len(s.workers))` |
| Workers in registry catalogue | **172** | `SocietyRegistry.discover()["counts"]` |
| Capability tokens | **729** | `CapabilityPlanner.list_capabilities()` |
| Micro-worker classes | **143** | `micro_workers._MICRO_WORKERS` |
| External (non-Python) workers | **25** | `micro_workers.EXTERNAL_WORKERS` |
| Registered extension workers | **28** | `ExtensionWorkerRegistry.workers` |
| API routers | 43 files | `api/app/routers/` |
| API endpoints | **347** | `@router.*` count |
| Routers mounted on app | 42 | `app.include_router()` calls |
| GrowthLab stage log retention | 200 stages | `growth_lab.py:415` |
| Enclave allowed roles | 2 (`aurora-core`, `security-leader`) | `secure_enclave.py:60` |

**Largest subsystems** (LOC in `core/robots/`):

| Subsystem | Files | LOC | Role |
|-----------|-------|-----|------|
| `society/` | 108 | 40,416 | The 44 societies, registry, growth lab, federation |
| `knowledge/` | 37 | 11,209 | Expertise maps, encyclopedia, playbooks, samples |
| `structure/` | 17 | 5,840 | MemoryKV, atomic IO, user modelling, daily evolution |
| `intelligence/` | 12 | 2,337 | CPG reasoning graph, scoring |
| `market/` | 12 | 1,172 | Wallet, earn, treasury primitives |
| `rag/` | 9 | 1,081 | Vector RAG (hashed TF-IDF, stdlib only) |
| `workers/` | 6 | 1,403 | Extension worker registry + domain workers |
| `tooling/` | 6 | 1,185 | Patchers, AST rewriter, model checker |
| `protocol/` | 5 | 1,405 | A2A messaging, security, MCP engine |
| `academy/` | — | — | Classrooms, XP, levels, model tiers |
| `governance/` | 7 files | — | Pre-flight gate, self-healer, sanctions, fault collector |
| `stealth/` | 2 | 378 | Headless browser engine |

---

## 3. THE REAL TREE

```
aurora-platform/                                  ← repo root
│
├── launch.sh                    ★ PRIMARY ENTRYPOINT: boots API+Dashboard+Desktop
├── Makefile                     verify | test-core | test-api | test | lint | build
├── docker-compose.yml           container orchestration
├── Dockerfile
├── nginx.conf                   reverse proxy
├── test_integration.sh
├── AURORA.desktop               desktop launcher file
│
├── core/                        ★ THE ENGINE (714 py files, 151k LOC)
│   ├── __init__.py
│   ├── secure_enclave.py        ★ air-gapped ChaCha20-Poly1305 secret store
│   ├── secrets_vault.py         ★ scrypt + BIP-39 recovery kit
│   ├── cognitive_blackboard.py  ★ SQLite blackboard (evolution DAG)
│   ├── deception_router.py      tarpit / ghost endpoints / mazes
│   ├── threat_fingerprint.py    ★ JA3-like client fingerprinting
│   ├── skill_registry.py        ★ SQLite tool-contract registry
│   ├── meta_orchestrator.py
│   ├── policy_engine.py
│   ├── hardened_worker.py
│   ├── evolution_engine.py
│   ├── runtime_arbiter.py
│   ├── capability_router.py
│   ├── desktop_console.py
│   ├── auth_nexus.py
│   ├── os_dispatcher.py
│   └── [29 root modules total]
│   │
│   ├── engine/                  DAG execution engine (core/engine/)
│   │   ├── dag_orchestrator.py  ★ DAGNode + DAGEngine (threaded, parallel)
│   │   └── cache.py             DAGResultCache (TTL cache)
│   │
│   ├── rag/                     vector_engine.py (hashed TF-IDF, 256-dim)
│   │
│   └── robots/                  ★ THE SOCIETY NERVOUS SYSTEM (75 subpackages)
│       ├── __init__.py          ★ installs robots→core.robots alias hook
│       │
│       ├── society/ (108 files, 40k LOC) ★★ THE CORE
│       │   ├── aurora_society.py     ★ AuroraMetaSociety, LazySocietyRegistry
│       │   ├── registry.py           SocietyRegistry (derived catalogue)
│       │   ├── growth_lab.py      ★ sandbox → gates → promote (+4 pillars)
│       │   ├── capability_planner.py★ 729-token index → ComposePlan
│       │   ├── assembly.py          AssemblyOrchestrator plan/execute
│       │   ├── secretary.py         Secretary.invoke_best (worker selection)
│       │   ├── builder.py           Builder.propose/build (the Builder law)
│       │   ├── review_board.py      ReviewBoard.summon/certify
│       │   ├── infrastructure.py    SocietyLibrary, RagNamespace, LabRegistry
│       │   ├── micro_workers.py  ★ 143 micro-worker classes
│       │   ├── society_factories.py ★ 44 lazy builder functions
│       │   ├── roster.py            CANONICAL_ROSTER (44 names)
│       │   ├── shared_services.py   Delegated specialist seats
│       │   ├── service_injection.py  Owner-approved borrowed officers
│       │   ├── federation.py        Peer society federation
│       │   ├── liveness.py          Awake/standby/asleep power map
│       │   ├── constellation.py     Cell routing
│       │   ├── hardware_proprioception.py ★ RAM/CPU/thermal telemetry
│       │   ├── thermal_governor.py  Thermal throttling
│       │   └── workers/          ★ 32 micro-worker definition modules
│       │
│       ├── autonomous/         ★ AutonomousRobot (sense→plan→critique→act→learn)
│       │   ├── loop.py          ★★ _execute_plan, run_cycle, scheduler
│       │   ├── gateway.py       ExecutionGateway (subprocess policy)
│       │   ├── guard.py         evaluate_write_policy, is_path_allowed
│       │   └── decision.py
│       │
│       ├── governance/ (7)     ★ fail-closed safety layer
│       │   ├── preflight_gate.py   ★ 7-invariant PreFlightGate
│       │   ├── sanctions_engine.py ★ OFAC/freeze/CEX-fencing/jurisdiction
│       │   ├── self_healer.py      ★ AST mutation + GrowthLab sandbox
│       │   ├── fault_collector.py  ★ SystemFaultEvent → MemoryKV + EventBus
│       │   ├── approval_queue.py
│       │   └── port_consortium.py
│       │
│       ├── workers/ (6)        ★ ExtensionWorkerRegistry
│       │   ├── extension_workers.py ★ Worker dataclass + registry
│       │   ├── sovereign_hands.py   ★ @register_worker decorator (9 actuators)
│       │   ├── domain_workers.py    web-deploy, market-trade-fsm, gig-scout
│       │   ├── enclave_workers.py   wallet-ops, stealth-scout, canvas-builder
│       │   └── data_integrity_guard.py ★ sentinel
│       │
│       ├── events/__init__.py  ★ EventBus singleton (200-event ring buffer)
│       ├── stealth/browser_engine.py ★ Playwright + Bézier evasion
│       │
│       ├── academy/classroom.py ★ rooms, XP, levels, tiers, award()
│       ├── economy/treasury.py  ★ TreasuryHierarchy (V1/V2/V3 vaults)
│       ├── evolution/           immune_system.py, alert_policy.py
│       ├── knowledge/ (37)      expertise maps, encyclopedia, playbooks, samples
│       ├── structure/ (17)      memory_kv.py ★, atomic_io.py, user_modeling.py
│       ├── reflexion/           CritiqueRobot (plan critique)
│       ├── intelligence/        cpg.py (reasoning graph)
│       ├── protocol/            A2A messaging, security, MCP
│       ├── brain/               Provider resolution + LLM routing
│       ├── mcp/ (7)            Model Context Protocol integration
│       ├── market/ (12)         wallet, earn, treasury, growth
│       ├── tooliing→tooling/ (6) AST rewrite, semantic patch, contract test
│       ├── rag/ (9)            Retrieval + vectors
│       ├── identity/, legal/, language/, media/, memory/, observability/
│       ├── orchestration/, persona/, psychology/, recognition/, research/
│       ├── risk/, sandbox/, scout/, secops/, security/, sentience/
│       ├── setup/, skillforge/, stress/, sovereignty/, telemetry.py
│       ├── voice/, wisdom/, workspace/
│       └── [+ ~40 more single modules]
│
├── api/                        ★ FastAPI bridge (131 py, 347 endpoints)
│   └── app/
│       ├── main.py             ★ 42 routers mounted, CORS, auth middleware
│       ├── routers/ (43 files)
│       │   ├── society_ops.py      ★ 150+ /society/* endpoints
│       │   ├── societies_live.py   ★ /societies/* roster + acceptance
│       │   ├── capability_gateway.py ★ /gateway/compose (DAG)
│       │   ├── stream.py           ★ SSE /stream/events
│       │   └── [40 more]
│       └── static/            dashboard HTML
│
├── robots/                     ★ ROOT SHIM: robots.* → core.robots.*
│   └── __init__.py            meta_path hook, sys.modules identity
│
├── rag/                        legacy top-level package (namespace)
│   └── vector_engine.py       shim → core.rag.vector_engine
│
├── tests/                      (integration scripts live in core/tests)
├── scripts/                    CLI utilities (society_board, aurora_chat, ...)
├── dashboard/                  Node dashboard (port 3000)
├── desktop/                    Electron main.js
├── android-app/                Android client
├── vscode-extension/           VS Code extension
├── docs/                       architecture, changelog, handoff, audit
├── data/, var/, .cache/        runtime state
├── artifacts/                  generated reports (JSON/MD)
├── audit-out/                  audit scripts
└── workspaces/                 deployed tools (memorykv-hygiene)
```

---

## 4. THE IMPORT SPINE

### Canonical rule

All production code imports **`core.robots.*`**. The legacy `robots.*` path works only through a `sys.meta_path` hook.

```
robots/__init__.py
    ├── sys.modules["robots"]  = sys.modules["core.robots"]
    └── installs _RobotsAliasFinder on sys.meta_path
            └── find_spec("robots.X") → import_module("core.robots.X")

Verified identity:
    import robots.events, core.robots.events
    assert robots.events.event_bus is core.robots.events.event_bus   # → True
```

Works under both `PYTHONPATH=.` and `PYTHONPATH=core:.`.

### Import order (boot)

```
app.main
  → inserts CORE_PATH into sys.path
  → imports routers (42 include_router)
       → imports robots.* (aliased to core.robots.*)
            → core.robots.society.aurora_society
                 → AuroraMetaSociety.__init__ builds 44 lazy factories
```

### The three root-module islands

| Module | Purpose | Consumed by |
|--------|---------|-------------|
| `core/*.py` (29 modules) | Security/infra primitives | `governance/`, `society/infrastructure.py` |
| `core/engine/` | DAG execution | `capability_gateway.py`, `society/growth_lab.py` |
| `core/robots/` | Society nervous system | everything |

---

## 5. RUNTIME DATA FLOW

### 5.1 The autonomous cycle (`core/robots/autonomous/loop.py`)

```
AutonomousRobot.run_cycle(project, config, issue)
 │
 ├─ 0.  CENTRALIZE  cleanup_stray_target_state()
 ├─ 0b. BRAIN       _resolve_brain()  → provider, model, tier, budgets
 ├─ 0c. THROTTLE    brain.resources.check() → overload detection
 │
 ├─ 1.  SENSE       build_repository_intelligence(project, config)
 ├─ 1b. RAG         query_for_context(...)  → relevant chunks
 ├─ 1c. TELEMETRY   MemoryKV telemetry:worker:* → brain["worker_health"]
 │                  brain["worker_warnings"] when fail_count >= 2
 │
 ├─ 2.  PLAN        _generate_plan() → Brain(LLM) or static fallback
 ├─ 3.  CRITIQUE    CritiqueRobot.critique_plan_direct()
 │                  critical finding ⇒ ALL WRITES BLOCKED
 ├─ 4.  SELECT      select_tools() → list[ToolRecommendation]
 │
 ├─ 5.  EXECUTE     _execute_plan()
 │    ├── evaluate_write_policy()  (risk + allowlist + dry-run)
 │    ├── ★ PreFlightGate.verify()  ← 7 invariants, fail-closed
 │    ├── _apply_direct_edits()
 │    ├── worker_registry.invoke()  ← ONLY dispatch path
 │    │     └── on success: MemoryKV telemetry + EventBus publish
 │    └── on unknown tool: {"success": false, "status": "unsupported"}
 │
 ├─ 6.  VERIFY      _verify_with_repair()
 │    ├── _syntax_check_files()   (compile on written .py)
 │    ├── _run_target_suite()     (pytest via ExecutionGateway)
 │    └── self-repair loop: max 2 LLM-guided repair attempts
 │
 ├─ 7.  EVIDENCE    create_evidence_package()
 ├─ 8.  LEARN       _learn()  → coupling + risk weights + critiques
 └─ 9.  LEDGER      sovereignty.record_event("cycle", ...)
```

### 5.2 Worker dispatch (fail-closed)

```
_execute_plan
   │
   ├─ tool in worker_registry.handlers ?
   │      └─► invoke(tool, payload)
   │            ├─ MemoryKV.set(f"telemetry:worker:{tool}:latest")
   │            ├─ MemoryKV.set(f"telemetry:worker:{tool}:health")
   │            │     {last_success, fail_count, last_run}
   │            └─ event_bus.publish("worker_executed", {...})
   │
   ├─ tool == "ast_rewrite"       → rewrite_ast (allowlisted)
   ├─ tool == "semantic_patch"    → apply_semantic_patch
   ├─ tool == "model_checker"     → ModelChecker (read-only)
   ├─ tool == "contract_tester"   → ContractTester (read-only)
   ├─ tool in (property_tester, benchmark) → explicit unsupported
   ├─ tool in (shell, bash, cli) → ExecutionGateway.run_command
   └─ else → {"success": false, "status": "unsupported", "reason": "unknown tool"}
```

---

## 6. THE 44 SOCIETIES

Roster declared in `core/robots/society/roster.py` (`CANONICAL_ROSTER`).
Lazy builders in `core/robots/society/society_factories.py` (44 `_build_*` functions).

| # | Society | Leader | Agents | Workers |
|---|---------|--------|--------|---------|
| 1 | accounting | accounting-leader | 7 | 3 |
| 2 | ads | ads-leader | 5 | 3 |
| 3 | archetype-foundry | foundry-leader | 5 | 3 |
| 4 | aurora-academy | aurora-academy-lead | 5 | 4 |
| 5 | **aurora-core** | aurora-core-leader | **21** | **40** |
| 6 | aurora-engineering | aurora-engineering-lead | 8 | 4 |
| 7 | aurora-quality | aurora-quality-lead | 8 | 3 |
| 8 | aurora-research | aurora-research-lead | 8 | 3 |
| 9 | aurora-security | aurora-security-lead | 8 | 3 |
| 10 | chrono | chrono-leader | 5 | 3 |
| 11 | database-ops | database-ops-leader | 6 | 3 |
| 12 | datasci-ml | datasci-ml-leader | 6 | 3 |
| 13 | deep-analytics | deep-analytics-leader | 5 | 3 |
| 14 | desktop-ops | desktop-ops-leader | 5 | 3 |
| 15 | economy | economy-leader | 5 | 4 |
| 16 | encyclopedia | encyclopedia-leader | 3 | 2 |
| 17 | github-scout | scout-lead | 5 | 3 |
| 18 | infrastructure-ops | infrastructure-ops-leader | 5 | 3 |
| 19 | integration-gateway | integration-gateway-leader | 5 | 3 |
| 20 | invest | invest-leader | 5 | 3 |
| 21 | knowledge-docs | knowledge-docs-leader | 5 | 4 |
| 22 | law | law-leader | 5 | 3 |
| 23 | legal | legal-lead | 5 | 3 |
| 24 | lingua-bridge | lingua-leader | 5 | 2 |
| 25 | market | market-leader | 5 | 2 |
| 26 | master-prompting | prompt-architect-leader | 5 | 2 |
| 27 | meta | meta-leader | 5 | 3 |
| 28 | mobile-ops | mobile-ops-leader | 5 | 2 |
| 29 | peers | peers-leader | 3 | 2 |
| 30 | persian-sense | persian-sense-leader | 6 | 3 |
| 31 | pulse | pulse-leader | 4 | 2 |
| 32 | revenue-engine | revenue-engine-leader | 5 | 6 |
| 33 | sandbox-forge | sandbox-forge-leader | 4 | 2 |
| 34 | semantic-codec | semantic-codec-leader | 5 | 2 |
| 35 | sense | sense-leader | 4 | 2 |
| 36 | seo-geo | seo-geo-leader | 4 | 2 |
| 37 | showcase | showcase-leader | 4 | 2 |
| 38 | sitekeep | sitekeep-leader | 4 | 2 |
| 39 | skill-forge | skill-forge-leader | 4 | 5 |
| 40 | tempo | tempo-leader | 3 | 2 |
| 41 | terminal-engine | terminal-engine-leader | 3 | 2 |
| 42 | treasury | treasury-leader | 3 | 2 |
| 43 | vision-media | vision-media-leader | 4 | 2 |
| 44 | web-scout | web-scout-leader | 4 | 2 |

**Totals:** 234 agents · 160 roster workers · 172 catalogue workers · **0 workers shared between societies** (verified).

### Lazy construction

`LazySocietyRegistry` holds 44 unbuilt builders. First `meta.societies[name]` triggers exactly one factory. Boot cost ≈ 600 ms for the full meta; per-society access ≈ 3 ms.

### The meta-society (`aurora-core`)

Owns 21 agents / 40 workers — it is the orchestrator *and* a participant. It holds:
- `self.societies` — `LazySocietyRegistry` (44 builders)
- `self.registry` — `SocietyRegistry(self)` (derived catalogue)
- `self.feedback` — `FeedbackLoop(self, registry)`
- `self.infrastructure` — `SocietyInfrastructure` (library/RAG/labs per society)
- `self.shared_services` — delegated specialist seats
- `self.service_injection` — owner-approved borrowed officers
- `self.pipeline_bus` — DAG message bus
- `self.symbiotic` — calibration loop
- `self.intent_router` — `IntentToPipelineRouter`
- `self.federation` — peer society federation
- `self.model_registry` — cloud/local model routing
- `self.election` — `LeaderElector` (opt-in)

---

## 7. THE 28 EXTENSION WORKERS

Registry: `ExtensionWorkerRegistry` (`core/robots/workers/extension_workers.py`).
Auto-discovery: `bootstrap_sovereign_hands()` runs `pkgutil.iter_modules()` over `core/robots/workers/` — **any new `.py` file with `@register_worker` is auto-registered with zero edits elsewhere.**

### Builtin (6) — hardcoded in `_register_builtins()`

| ID | Purpose |
|----|---------|
| `w-lint` | `ruff check` |
| `w-format` | `ruff format --check` |
| `w-search` | codebase grep |
| `w-git` | `git status/diff/log` |
| `w-refactor` | rename/extract planner |
| `w-autocomplete` | local-model completion |

### Actuator (15) — `@register_worker` decorated

| ID | Module | Does |
|----|--------|------|
| `w-installer` | sovereign_hands | pip / npm / apt install |
| `w-llm-router` | sovereign_hands | Ollama / Hermes HTTP bridge |
| `w-agent-mesh` | sovereign_hands | cross-platform agent ping / spec sync |
| `w-tool-scout` | sovereign_hands | `shutil.which` probe |
| `w-project-auditor` | sovereign_hands | workspace + git status audit |
| `w-graphify` | sovereign_hands | AST dependency graph (graphify CLI) |
| `w-repolyze` | sovereign_hands | Repolyze app probe |
| `w-laya` | sovereign_hands | laya-lab dispatcher |
| `w-self-healer` | sovereign_hands | EvolutionLoop MicroLesson triage |
| `w-web-deploy` | domain_workers | HTML/CSS/Dockerfile/nginx generation + syntax verify |
| `w-market-trade-fsm` | domain_workers | tick array → uptrend detect → Entry/SL/TP → MemoryKV ledger |
| `w-gig-scout` | domain_workers | real repo structural-gap scanner |
| `w-wallet-ops` | enclave_workers | address validation, balance/audit/transfer, MemoryKV ledger |
| `w-stealth-scout` | enclave_workers | ThreatFingerprintEngine + DeceptionRouter + BrowserEngine |
| `w-live-canvas-builder` | enclave_workers | UI components → MemoryKV + EventBus |

### Custom (7) — persisted in `.cache/workers/registry.json`

`w-custom-6` (aurora-hand-docker), `w-custom-11` (orchestrator), `w-custom-12` (project-auditor),
`w-custom-27` (tool-scout), `w-custom-28` (agent-mesh), `w-custom-29` (llm-router), `w-custom-30` (installer)

---

## 8. DATA STORES

### MemoryKV (`core/robots/structure/memory_kv.py`)

Persistent JSON key-value store. **All namespaces share one file**:
`<root>/.cache/knowledge/memory.json`

Guarantees:
- **Atomic writes** — temp file + `fsync` + `os.replace`
- **Cross-process merge** — `fcntl.flock` on `memory.json.lock`, re-reads disk before merge
- **Cross-instance freshness** — `get()` calls `_refresh_from_disk()` (version-merge)
- **Versioned entries** — each `set()` bumps `version`
- **Root default** — `MemoryKV()` with no args → `Path.cwd()`

Heavy-use namespaces: `default`, `growth-lab`, `global`, `daily-evolution`, `research-society`,
`security-society`, `internal-wallet`, `treasury`, `economy`, `ui-canvas`, `wallet-ops-ledger`,
`market-trade-ledger`, `self-healer`, `fault-collector`, `a2a-cards`, `a2a-messages`, `learning-loop`.

### EventBus (`core/robots/events/__init__.py`)

In-process ring buffer (200 events) + synchronous subscriber callbacks.
SSE exposure: `GET /stream/events` (`text/event-stream`), 30 s keepalive.
Singleton — `from core.robots.events import event_bus`.

### CognitiveBlackboard (`core/cognitive_blackboard.py`)

SQLite (`<root>/.cache/blackboard.db`). Optimistic concurrency, versioned rows, lease-based task
claiming, idempotency keys, append-only audit. Holds evolution events.

### SkillRegistry (`core/skill_registry.py`)

SQLite (`tools` table). Typed tool contracts: side-effect enum, permission level, filesystem/network
scope, input/output schema, health check, rollback handler, provenance policy.

### SecureEnclave (`core/secure_enclave.py`)

`~/.aurora/enclave/` (mode 0700). ChaCha20-Poly1305 per category, AAD-bound (files not
interchangeable). Atomic writes + directory fsync. `flock` per category.
Dual-control SoD — allowed roles `{aurora-core, security-leader}`, each requiring an HMAC-SHA256
capability token. `Zeroized` wipes secrets via `ctypes.memset`. Secure-shred on delete.

Categories: `credentials`, `api_tokens`, `configs`, `identities`.

### Knowledge

`core/robots/knowledge/society_knowledge.py` — `SOCIETY_EXPERTISE` maps all 44 societies to domain
expertise strings; `KNOWLEDGE_ESSENCE` + graded sample sets (G1–G4).

---

## 9. THE API SURFACE — 347 ENDPOINTS

42 routers mounted on `app.main:app`. Auth: `SharedSecretAuthMiddleware` compares
`x-aurora-token` against `AURORA_API_TOKEN` for guarded prefixes and **all** mutations.

**Single-process contract:** exactly ONE uvicorn worker. Ledgers/meshes live in process memory.

### Principal routers

| Router | Prefix | Count | Role |
|--------|--------|-------|------|
| `society_ops.py` | `/society` | 150 | Achievements, workers, federation, leader election, treasury, labs, services, growth, user-path, immune, alerts, models |
| `societies_live.py` | `/societies` | 10 | Roster overview, acceptance matrix, worker overview, spawn, port consortium |
| `capability_gateway.py` | `/gateway` | 6 | `/status`, `/route`, **`/compose`**, `/invalidate`, `/reset`, `/metrics` |
| `stream.py` | `/stream` | 2 | ★ SSE `/events`, `/events/history` |
| `autonomous.py` | `/autonomous` | 3 | start/stop/status cycles |
| `memory.py` | `/memory` | — | MemoryKV access |
| `workspace.py` | `/workspace` | 21 | Files, diff, git, terminal, agents |
| `ollama.py` | `/ollama` | 10 | incl. NDJSON streaming generate |

### The compose endpoint (DAG)

```
POST /gateway/compose
  {"tasks": ["deploy_service", "monitor_market"]}
    │
    ├─ build_manifests_from_meta(_META)
    ├─ CapabilityPlanner.plan_for_compose(payload)   → ComposePlan(steps[ComposeStep])
    │     · 729-token inverted index → target societies
    │     · dependency inference (producer/consumer token overlap)
    │     · sorted: most-depended-on first, then alphabetical
    ├─ FAIL-CLOSED: unmapped inputs → {"error": {"retryable": false, "code": "UNMAPPED_INPUT"}}
    ├─ SafetyGovernor.safety_flow()  → block on violation
    ├─ CognitiveGatewayGuard.inspect_and_filter()
    ├─ DAGEngine.build(nodes).run(ctx, persist_ns, persist_root)
    │     · nodes declare output_keys incl. society:{name} / worker:{name}
    │     · stale-key unload preserves pending nodes' outputs
    └─ {"steps", "composed", "workers", "dag_order", "dependency_map", "cached"}
```

---

## 10. GOVERNANCE & SAFETY STACK

### Pre-Flight Gate (`core/robots/governance/preflight_gate.py`)

Seven invariants, evaluated **before** any dispatch. Any failure raises `PreFlightAbort`:

| # | Invariant | Aborts when |
|---|-----------|-------------|
| 1 | `risk_score` | `> 0.0` |
| 2 | `network_status` | `≠ VERIFIED_CLEAN` (loopback + DNS + proxy env probe) |
| 3 | `capability_signature` | required schema keys missing |
| 4 | `sanctions_address` | address in OFAC / USDT-freeze list |
| 5 | `jurisdiction` | IP/country in sanctioned jurisdiction |
| 6 | `cex_route` | geographic IP fencing blocks exchange |
| 7 | `deterministic_fingerprint` | stable sha256 over `{capability, payload}` |

Wired into `_execute_plan` at `core/robots/autonomous/loop.py` (~line 842).

### Sanctions Engine (`core/robots/governance/sanctions_engine.py`)

- `_OFAC_BLOCKLIST` — 3 known-bad addresses (Lazarus, Blender.io, Tornado Cash)
- `_SANCTIONED_JURISDICTIONS` — IR, CU, SY, KP, RU, BY, MM, ZW, VE
- `_BLOCKED_CEX_DOMAINS` — Binance, Coinbase, Kraken, OKX, Bybit
- `_IP_JURISDICTION_MAP` — CIDR prefix → jurisdiction
- `is_route_censorship_resistant(chain, route)` — Monero/Zcash score highest; Tron/CEX non-freezable

### DataIntegrityGuard (`core/robots/workers/data_integrity_guard.py`)

Rejects any worker payload containing `stub` / `mock` / `fake` / `placeholder` / `TODO` /
`FIXME` / `synthetic`, and any payload missing its worker's required schema fields.
Raises `IntegrityViolation` (fail-closed).

### Write Policy (`core/robots/autonomous/guard.py`)

`evaluate_write_policy(risk, threshold, candidate_paths, rag_paths, project, config, dry_run)`
→ allow / preview / deny. Path containment via `is_path_allowed`, traversal rejected.

### Fault Collector (`core/robots/governance/fault_collector.py`)

Captures stack trace → emits `SystemFaultEvent` to EventBus → records footprint in MemoryKV
(ring-buffered at 200) → returns a typed fault envelope. Replaces silent `except: pass`.

### Threat / Deception

- `core/threat_fingerprint.py` — header hash + JA3-like TLS fingerprint, per-IP profiles, decay, risk levels (safe → suspicious → probed → attacker → banned)
- `core/deception_router.py` — tarpit, ghost endpoints (encrypted with an unretrievable key), maze redirects

---

## 11. THE EVOLUTIONARY PIPELINE

```
fault detected
   │
   ├─▶ fault_collector.collect_fault()          → MemoryKV + EventBus
   │
   └─▶ SelfHealer.attempt_repair(module, tb, payload, cell)
         │
         ├─ quarantine check (TTL 300 s) · attempt counter (max 3)
         ├─ 3 deterministic AST mutations:
         │     1. _add_except_handler       bare except → collect_fault
         │     2. _guard_zero_division       a / b  →  0.0 if b == 0
         │     3. _guard_attribute_none      x.attr → None if x is None
         ├─ GrowthLab.stage() in the cell's upgrade room
         │     · MetaBufferPool provides a pristine sandbox meta
         │     · Builder.propose → build → gates
         ├─ immune gate   (ImmuneSystem.force_scan, per-cell anomalies)
         ├─ hardware gate (RAM headroom < 100 MB → refuse)
         ├─ compile patched source inside sandbox
         ├─ FAIL → shutil.rmtree(sandbox); reliability -= 0.2; quarantine
         └─ PASS → atomic disk write (NamedTemporaryFile + os.replace)
                   → GrowthLab.promote(stage_id, by="user")
                   → classroom.award(root, cell, xp=100)
                   → TreasuryHierarchy.record_income(cell, 1000)
                   → CognitiveBlackboard.publish("cell.promoted", {...})
                   → importlib.reload(module)
                   → reliability = 1.0
```

### GrowthLab

| API | Behaviour |
|-----|-----------|
| `stage(draft)` | Requires `{cell, name}`; id must equal `{cell}-{name}` (Builder law). Runs in an isolated sandbox from the pool. |
| `promote(stage_id, by, cert, ledger)` | Owner-only. `cert.unanimous is True` required (10/10/10 board). `ledger.ok is True` required (monotonic). Gates safe + builder registered. |
| `retire(stage_id, by)` | Owner-only. Promoted stages are final. |
| `rooms()` | Every live society's room: roster, stage buckets, faculty, hardware |
| `gradient()` | Per-cell growth vector: data, treasury, coverage, pending stages |
| `parallel_plan()` | One sandbox per vacant cell, staged in parallel |
| `register_cell_skill(cell, name, spec)` | → `SkillRegistry` |
| `inspect_cell_capabilities(cell)` | Workers + skills + playbooks + faculty grade |

### Room metadata (the four pillars, now wired)

```json
{
  "cell": "aurora-core", "leader": "...", "agents": [...], "workers": [...],
  "stages": {"pending": 0, "promoted": 0, "retired": 0},
  "sandbox": "...",
  "faculty": {
    "knowledge_tier": 1,
    "curriculum_xp": {...},
    "available_playbooks": [...],   // from SOCIETY_EXPERTISE
    "board_seats": 21
  },
  "hardware": {"proceed": true, "memory_mb": 0.0}
}
```

---

## 12. HOW TO RUN EVERYTHING

### Boot the full stack

```bash
cd ~/project/aurora-platform
./launch.sh
```

Binds: API `127.0.0.1:8000` (uvicorn, **1 worker**) · Dashboard `:3000` · Desktop window.
Logs → `.cache/logs/launcher.log`.

### Import paths

Both work identically (alias hook normalises them):

```bash
PYTHONPATH=.       python3 -c "from core.robots.society.aurora_society import AuroraMetaSociety"
PYTHONPATH=core:.  python3 -c "from core.robots.society.aurora_society import AuroraMetaSociety"
```

### Common commands

```bash
# Full verification
make verify                     # lint + test-core + test-api

# Society e2e (44 societies, 729 capability smokes)
PYTHONPATH=core:. python3 core/tests/run_all_societies_e2e.py
    → artifacts/societies_e2e_report.{json,md}

# 10/10 society audit
PYTHONPATH=. python3 audit-out/society_10of10_runner.py

# Safety / reality suites
PYTHONPATH=core:. python3 -m pytest -q core/tests/test_multi_dimensional_chaos.py
PYTHONPATH=core:. python3 -m pytest -q core/tests/audit_reality_and_sanctions.py
PYTHONPATH=core:. python3 -m pytest -q core/tests/test_stealth_browser_and_preflight_wiring.py

# Evolution suites
PYTHONPATH=core:. python3 -m pytest -q \
    core/tests/test_hyper_growth_integration.py \
    core/tests/test_evolutionary_healing.py \
    core/tests/test_growth_lab.py \
    core/tests/test_synaptic_circuits.py

# Concurrency
PYTHONPATH=core:. python3 -m pytest -q core/tests/test_societies_parallel_probe.py

# Real-world mission
PYTHONPATH=core:. python3 -m pytest -q core/tests/test_autonomous_mission_e2e.py
```

---

## 13. THE TEST SURFACE

255 test files in `core/tests/`. The suites built for this architecture:

| Suite | Tests | Verifies |
|-------|-------|----------|
| `test_society_10of10` (runner) | 44 societies × 10 checks | Import, AgentCard, Registry, Probe, EventBus, MemoryKV, Payload limit, Auth rejection, Determinism, <300 ms |
| `run_all_societies_e2e.py` | 44 societies, 729 smokes | Activation DAG, capability dispatch, integrity guard, schema hashes |
| `test_societies_parallel_probe.py` | 3 | 44 concurrent probes, event ordering, MemoryKV race-freedom |
| `test_multi_goal_orchestration.py` | 6 | Planner → Secretary, <100 ms parallel, persistence, fail-closed |
| `test_autonomous_mission_e2e.py` | 5 | Web deploy + gig scout + market FSM, <250 ms |
| `test_high_concurrency_stress.py` | 4 | 3-tier: Light I/O, Medium concurrency, Heavy EventBus |
| `test_multi_dimensional_chaos.py` | 5 | Schema injection, self-healer, hygiene GC, load, mid-flight faults |
| `audit_reality_and_sanctions.py` | 5 | OFAC/freeze, egress probe, stealth gaps, pre-flight gating |
| `test_stealth_browser_and_preflight_wiring.py` | 8 | Bézier, keystroke timing, evasion headers, fingerprint script |
| `test_hyper_growth_integration.py` | 8 | Faculty, knowledge conformance, skills, XP ascent |
| `test_evolutionary_healing.py` | 10 | 3 AST mutations, quarantine, sandbox isolation, stage recording |
| `test_synaptic_circuits.py` | 8 | Immune, treasury, hardware, blackboard wiring |

**Artifacts** land in `artifacts/` and `audit-out/`.

---

## 14. KNOWN ARCHITECTURAL DEBTS

Honest accounting of what is *not* finished.

| Debt | Evidence | Severity |
|------|----------|----------|
| **1,602 non-canonical imports** remain (`from robots.X import`) | `artifacts/repo_weakness_report.json` | Low — the alias hook normalises them; grep is noisy, not broken |
| **489 `except Exception: pass`** remain across `core/robots/` | `repo_self_audit.py` | Medium — many are intentional fail-open in `loop.py`, `gateway.py`, `guard.py` |
| **ThermalGovernor not gating sandbox** | `thermal_governor.decide()` exists but `GrowthLab` only checks RAM | Low — wired via `hardware_proprioception` instead |
| **GrowthLab sandbox runs as user, not container** | `sandbox-forge` society defines the policy; no enforcement at lab level | Medium |
| **LLM path optional** | `resolve_runtime()` falls back to static plans when no provider | By design |
| **Playwright absent** | Browser engine auto-degrades to stdlib HTTP | By design — `backend_type` reports `fallback_http` |
| **No migrations** | `MemoryKV` / SQLite schemas are created-if-absent | Low |
| **Process-global singletons** | `_META`, `event_bus`, `registry` | By design — one-worker contract |

---

## 15. READING ORDER FOR A NEW MODEL

Read in this order. Each step assumes the previous.

1. **`README.md`**, then **`PROJECT_OVERVIEW.md`** — intent and scope
2. **`core/robots/society/roster.py`** — the 44 names, the ground truth
3. **`core/robots/society/aurora_society.py:267-505`** — `AuroraMetaSociety.__init__`: every subsystem is wired here
4. **`core/robots/society/society_factories.py`** — how one society is built
5. **`core/robots/society/capability_planner.py`** — token index + `ComposePlan`
6. **`core/engine/dag_orchestrator.py`** — how a plan actually runs in parallel
7. **`core/robots/autonomous/loop.py`** — the full sense→plan→critique→act→learn cycle
8. **`core/robots/governance/preflight_gate.py`** — what must hold before dispatch
9. **`core/robots/structure/memory_kv.py`** — every state read/write funnels here
10. **`core/robots/society/growth_lab.py`** — stage / gates / promote (the Owner law)
11. **`core/secure_enclave.py`** — how secrets actually work
12. **`api/app/main.py`** — the 42 routers, then `routers/society_ops.py`
13. **`core/tests/run_all_societies_e2e.py`** — see the whole system assert itself

### Invariants you must not break

```
1. Canonical imports are core.robots.*   (robots/* is a meta_path alias only)
2. Unknown tool  ⇒ {"success": false, "status": "unsupported"}   never silent pass
3. Any write goes through evaluate_write_policy() + PreFlightGate
4. MemoryKV is the only state store; no ad-hoc JSON files
5. Stage ids are {cell}-{name}; GrowthLab enforces it
6. promote() requires by="user" + unanimous cert + monotonic ledger
7. Nothing self-modifies: the lab proposes, the owner disposes
8. society_skill/worker outputs pass DataIntegrityGuard before persisting
```

---

*End of document. Every number verified against the live tree on 2026-10-04.*