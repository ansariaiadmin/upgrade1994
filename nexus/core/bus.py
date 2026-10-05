"""Zero-copy in-process event bus with priority scheduling (<1ms hop target)."""
import heapq, itertools, threading
from .mathlang import Msg, verify

class Bus:
    def __init__(self):
        self._q, self._subs, self._lock, self._seq = [], {}, threading.Lock(), itertools.count()
        self.delivered = 0
    def subscribe(self, society: str, ops: set[str] | None = None):
        self._subs.setdefault(society, []).append(ops)  # None => all
    def publish(self, m: Msg):
        if not verify(m): raise ValueError(f"protocol violation: {m}")
        with self._lock:
            # negative rho => max-heap by priority; seq breaks ties FIFO
            heapq.heappush(self._q, (-m.rho, next(self._seq), m))
    def drain(self, society: str, limit=64):
        out, keep = [], []
        with self._lock:
            while self._q and len(out) < limit:
                neg, seq, m = heapq.heappop(self._q)
                subs = self._subs.get(society, [])
                if any(f is None or m.psi['op'] in f for f in subs):
                    out.append(m); self.delivered += 1
                else:
                    keep.append((neg, seq, m))
            for k in keep: heapq.heappush(self._q, k)
        return out
