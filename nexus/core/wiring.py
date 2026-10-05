"""NEXUS assembly root — instantiates societies, binds them to the Bus.
Each society = leader agent + worker pool; adapters here are thin sockets
that later swap for vendored repos (autogen, browser-use, piper, ...)."""
from .mathlang import emit
from .bus import Bus
from .soma import Soma

class Society:
    def __init__(self, name, bus, ops, workers=4):
        self.name, self.workers, self.log = name, workers, []
        bus.subscribe(name, set(ops))
    def receive(self): raise NotImplementedError
    def act(self, m): raise NotImplementedError

class Cortex(Society):
    """leader/planner: decomposes goals into MathLang ops."""
    def plan(self, goal: str, e: float):
        ops = ["see", "install", "render", "speak"]
        rho = min(1.0, 0.3 + e * 0.7)          # body energy scales priority
        return [emit("cortex", op, {"goal": goal}, rho=rho) for op in ops]

class Panopticon(Society):
    """eyes: screenshot/OCR/web — adapter, vendor target: browser-use+Playwright."""
    def act(self, m): self.log.append(("see", m.psi["goal"]))

class Hands(Society):
    """limbs: shell/install/deploy — vendor target: OpenHands runtime."""
    def act(self, m): self.log.append(("exec", m.psi["goal"]))

class Echo(Society):
    """ears/mouth — vendor targets: faster-whisper + piper-tts."""
    def act(self, m): self.log.append(("voice", m.psi["goal"]))

class Showcase(Society):
    """Eye-of-God window: renders whatever was commanded, live."""
    def render_frame(self, frame_no, states: dict) -> str:
        lines = [f"┌─ NEXUS EYE OF GOD ─ frame {frame_no} " + "─"*20,
                 f"│ body: cpu={states['cpu']}% ram={states['ram']} budget_e={states['e']:.2f}"]
        for s, acts in states["societies"].items():
            lines.append(f"│ {s:<12} ▸ {acts}")
        lines.append("└" + "─"*46)
        return "\n".join(lines)

def assemble():
    bus, soma = Bus(), Soma()
    soc = {
        "cortex":     Cortex("cortex", bus, ["plan"], workers=8),
        "panopticon": Panopticon("panopticon", bus, ["see","render"], workers=16),
        "hands":      Hands("hands", bus, ["install","exec"], workers=16),
        "echo":       Echo("echo", bus, ["listen","speak"], workers=4),
        "showcase":   Showcase("showcase", bus, ["render"], workers=2),
    }
    return bus, soma, soc
