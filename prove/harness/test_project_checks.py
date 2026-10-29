"""Check that bounded verification fails closed and stops its descendants."""
from pathlib import Path
import sys
import tempfile
import unittest

from project_checks import run_check


class BoundedCheckTests(unittest.TestCase):
    def test_exit_status_and_output(self):
        with tempfile.TemporaryFile(mode="w+") as log:
            code, timed_out = run_check([sys.executable, "-c", "print('failed'); raise SystemExit(7)"],
                                        Path.cwd(), log, 5)
            log.seek(0)
            self.assertEqual((code, timed_out), (7, False))
            self.assertIn("failed", log.read())

    @unittest.skipUnless(sys.platform == "linux", "process-group audit uses /proc")
    def test_timeout_stops_child_that_ignores_term(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryFile(mode="w+") as log:
            pidfile = Path(directory) / "child.pid"
            child = "import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)"
            parent = ("import subprocess,sys,time; from pathlib import Path; "
                      "p=subprocess.Popen([sys.executable,'-c',sys.argv[2]]); "
                      "Path(sys.argv[1]).write_text(str(p.pid)); time.sleep(60)")
            code, timed_out = run_check([sys.executable, "-c", parent, str(pidfile), child],
                                        Path.cwd(), log, 1)
            self.assertEqual((code, timed_out), (124, True))
            pid = int(pidfile.read_text())
            # A killed orphan may briefly remain a zombie awaiting reaping.
            import time
            for _ in range(100):
                stat = Path(f"/proc/{pid}/stat")
                if not stat.exists() or stat.read_text().split(") ", 1)[1].startswith("Z"):
                    break
                time.sleep(0.01)
            else:
                self.fail(f"verification child {pid} survived timeout")
            log.seek(0)
            self.assertIn("timed out", log.read())


if __name__ == "__main__":
    unittest.main()
