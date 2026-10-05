"""Soma — hardware proprioception. Body = laptop. Syncs every tick."""
import os, shutil

class Soma:
    def __init__(self):
        self.total_ram = os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / 1e9
    def sense(self) -> dict:
        try:
            import psutil
        except ImportError:
            return {"err": "psutil missing -> hands.w-installer should install it"}
        disk = shutil.disk_usage("/")
        return {
            "cpu_pct": psutil.cpu_percent(interval=None),
            "ram_used_gb": round(psutil.virtual_memory().used/1e9, 2),
            "ram_total_gb": round(self.total_ram, 1),
            "disk_free_gb": round(disk.free/1e9, 1),
            "load_avg": os.getloadavg(),
            "temp_zone_c": self._thermal(),
        }
    @staticmethod
    def _thermal():
        for p in ("/sys/class/thermal/thermal_zone0/temp",):
            try: return int(open(p).read())//1000
            except Exception: pass
        return None
    def budget(self) -> float:
        """energy scalar e∈[0,1]: how much of the body is free right now."""
        s = self.sense()
        if "err" in s: return 0.5
        return max(0.0, min(1.0, 1 - (s["cpu_pct"]/100*0.5 + (s["ram_used_gb"]/s["ram_total_gb"])*0.5)))
