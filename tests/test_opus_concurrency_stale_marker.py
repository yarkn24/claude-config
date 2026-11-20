"""Runs the REAL opus-concurrency hooks under a throwaway HOME. Never touches live markers."""
import json, os, subprocess, tempfile, unittest
from pathlib import Path

HOOKS = Path(__file__).resolve().parent.parent / "claude" / "hooks"
SID = "11111111-2222-3333-4444-555555555555"
INTERRUPT = {"type": "user", "message": {"role": "user", "content": [{"type": "text", "text": "[Request interrupted by user for tool use]"}]}}
ALIVE = {"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": "working"}]}}


class Env:
    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.state = self.home / ".claude" / "state" / "opus_active"
        self.state.mkdir(parents=True)

    def agent(self, n, last_line, slug="-proj-root", model="opus", marker=True):
        d = self.home / ".claude" / "projects" / slug / SID / "subagents"
        d.mkdir(parents=True, exist_ok=True)
        aid, tid = "a%016d" % n, "toolu_%024d" % n
        (d / f"agent-{aid}.meta.json").write_text(json.dumps({"toolUseId": tid, "model": model}))
        (d / f"agent-{aid}.jsonl").write_text(json.dumps(ALIVE) + "\n" + json.dumps(last_line) + "\n")
        if marker:
            (self.state / tid).touch()
        return aid, tid

    def run(self, script, payload):
        env = dict(os.environ, HOME=str(self.home))
        return subprocess.run(["bash", str(HOOKS / script)], input=json.dumps(payload), text=True,
                              capture_output=True, env=env, timeout=60)

    def guard(self):
        return self.run("opus-concurrency-guard.sh", {"tool_name": "Agent", "tool_use_id": "toolu_new",
                                                      "tool_input": {"model": "opus"}})


class StaleMarker(unittest.TestCase):
    def setUp(self):
        self.e = Env()

    def tearDown(self):
        self.e.tmp.cleanup()

    def test_interrupted_agents_do_not_hold_slots(self):
        # 4 killed (TaskStop, no SubagentStop) + 2 live = 6 markers; the guard must free the 4.
        dead = [self.e.agent(i, INTERRUPT) for i in range(4)]
        live = [self.e.agent(i, ALIVE) for i in range(4, 6)]
        r = self.e.guard()
        self.assertEqual(r.returncode, 0, r.stderr)
        for _, tid in dead:
            self.assertFalse((self.e.state / tid).exists(), "dead marker survived")
        for _, tid in live:
            self.assertTrue((self.e.state / tid).exists(), "live marker was deleted")

    def test_six_live_agents_still_block(self):
        for i in range(6):
            self.e.agent(i, ALIVE)
        self.assertEqual(self.e.guard().returncode, 2)

    def test_marker_without_meta_is_kept(self):
        for i in range(6):
            (self.e.state / f"toolu_x{i}").touch()
        self.assertEqual(self.e.guard().returncode, 2)

    def test_release_is_independent_of_cwd(self):
        aid, tid = self.e.agent(7, ALIVE)
        r = self.e.run("opus-concurrency-release.sh", {"agent_id": aid, "session_id": SID,
                                                       "cwd": "/work/project"})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((self.e.state / tid).exists(), "release keyed on cwd left the slot held")


if __name__ == "__main__":
    unittest.main()
