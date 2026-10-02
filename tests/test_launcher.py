"""Exercise launcher IPC routing without accessing the real desktop."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherTests(unittest.TestCase):
    def run_launcher(self, action, *, host_ok=True, existing=False, ipc_error=False):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            log = folder / 'calls'
            def tool(name, body):
                path = folder / name
                path.write_text('#!/usr/bin/python3\n' + body)
                path.chmod(0o755)
            tool('omarchy-shell',
                 'import os,sys,json\n'
                 'with open(os.environ["TEST_LOG"],"a") as f: f.write(json.dumps(sys.argv)+"\\n")\n'
                 'sys.exit(0 if os.environ["TEST_HOST_OK"]=="1" else 1)\n')
            tool('ps', 'import os\n'
                 'if os.environ["TEST_EXISTING"]=="1": print("4321 quickshell quickshell -p " + os.environ["TEST_CONFIG"])\n')
            tool('qs', 'import os,sys,json\n'
                 'with open(os.environ["TEST_LOG"],"a") as f: f.write(json.dumps(sys.argv)+"\\n")\n'
                 'if sys.argv[1]=="ipc" and os.environ["TEST_IPC_ERROR"]=="1": print("Function not found.")\n')
            env = dict(os.environ, PATH=f'{folder}:/usr/bin:/bin',
                       TEST_LOG=str(log), TEST_HOST_OK=str(int(host_ok)),
                       TEST_EXISTING=str(int(existing)), TEST_IPC_ERROR=str(int(ipc_error)),
                       TEST_CONFIG=str(ROOT / 'apps/iamcheyan-clipboard/shell.qml'))
            result = subprocess.run(['/usr/bin/bash', str(ROOT / 'bin/iamcheyan-clipboard'), action, '40'],
                                    env=env, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            return [json.loads(line) for line in log.read_text().splitlines()]

    def test_host_routes_and_precedes_standalone(self):
        for action, method in [('toggle','toggleAtBar'), ('open','openAtBar'),
                               ('toggle-at-bar','toggleAtBar'), ('open-at-bar','openAtBar'),
                               ('toggle-at-cursor','toggleAtCursor'), ('open-at-cursor','openAtCursor')]:
            with self.subTest(action=action):
                calls = self.run_launcher(action, existing=True)
                self.assertEqual(len(calls), 1)
                self.assertEqual(calls[0][1:], ['iamcheyan.clipboard', method])

    def test_existing_standalone_preserves_placement(self):
        for action, suffix in [('toggle-at-bar',['toggleAtBar','40']),
                               ('open-at-bar',['openAtBar','40']),
                               ('toggle-at-cursor',['toggle']), ('open-at-cursor',['open'])]:
            with self.subTest(action=action):
                calls = self.run_launcher(action, host_ok=False, existing=True)
                self.assertEqual(calls[1][1:], ['ipc','--pid','4321','call','clipboard',*suffix])
                self.assertEqual(len(calls), 2)

    def test_missing_handler_with_success_exit_still_starts_fallback(self):
        calls = self.run_launcher('toggle-at-cursor', host_ok=False, existing=True, ipc_error=True)
        self.assertEqual(len(calls), 3)
        self.assertEqual(calls[2][1:3], ['--no-duplicate','-p'])

    def test_no_host_or_standalone_starts_fallback(self):
        calls = self.run_launcher('open-at-cursor', host_ok=False)
        self.assertEqual(calls[1][1:3], ['--no-duplicate','-p'])


if __name__ == '__main__':
    unittest.main()
