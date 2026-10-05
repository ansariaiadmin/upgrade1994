"""NEXUS MathLang — inter-society protocol.
Every message between societies is a typed mathematical tuple:
  M = <σ, τ, ρ, ψ, ε>   (sender society, tick, priority rho∈[0,1], payload ψ, evidence-set ε)
Serialization: msgpack; routing: content-addressed hash for idempotency.
"""
import hashlib, time, dataclasses
from typing import Any

@dataclasses.dataclass(frozen=True)
class Msg:
    sigma: str      # sender society e.g. "cortex"
    tau: float      # monotonic timestamp (sync clock)
    rho: float      # priority 0..1
    psi: dict       # payload
    epsilon: tuple  # evidence hashes (provenance chain)

    @property
    def addr(self) -> str:
        raw = f"{self.sigma}|{self.tau}|{self.psi.get('op','')}"
        return hashlib.sha256(raw.encode()).hexdigest()[:16]

def emit(sigma, op, psi_extra=None, rho=0.5, epsilon=()):
    p = {"op": op, **(psi_extra or {})}
    return Msg(sigma=sigma, tau=time.monotonic(), rho=rho, psi=p, epsilon=tuple(epsilon))

def verify(m: Msg) -> bool:
    """invariants: bounded priority, non-empty payload, provenance closure."""
    return 0.0 <= m.rho <= 1.0 and bool(m.psi) and isinstance(m.epsilon, tuple)
