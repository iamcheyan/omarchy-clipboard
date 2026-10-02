"""Test real QML history updates against isolated, synthetic history files."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('qs'), 'Quickshell is required')
class HistoryTests(unittest.TestCase):
    def test_immediate_deletion_repetition_filtering_and_persistence(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            runtime = folder / 'runtime'
            runtime.mkdir(mode=0o700)
            history = folder / '.local/state/omarchy/clipboard-history.json'
            history.parent.mkdir(parents=True)
            initial = [{'type':'text','text':'Alpha'}, {'type':'text','text':'...'},
                       {'type':'text','text':'Beta'}, {'type':'image','path':'/tmp/synthetic.png'},
                       {'type':'text','text':'Gamma'}]
            history.write_text(json.dumps(initial))
            config = folder / 'check.qml'
            config.write_text('''import QtQuick
import Quickshell
import "''' + (ROOT / 'apps/iamcheyan-clipboard/services').as_uri() + '''"
ShellRoot {
    property bool failed: false
    function check(value, message) {
        if (!value) { failed = true; console.error("FAIL: " + message); }
    }
    Component.onCompleted: Cliphist.refresh()
    Timer {
        interval: 300; running: true
        onTriggered: {
            check(Cliphist.entries.length === 4, "initial visible history");
            const stale = Cliphist.entries[2];
            check(Cliphist.deleteEntry(Cliphist.fuzzyQuery("beta")[0]), "delete filtered selection");
            check(Cliphist.entries.length === 3, "deletion must update immediately");
            check(Cliphist.fuzzyQuery("beta").length === 0, "deleted entry disappears from search");
            check(!Cliphist.deleteEntry(stale), "stale delegate must not delete another entry");
            check(Cliphist.deleteEntry(Cliphist.entries[1]), "delete image immediately after text");
            check(Cliphist.entries.length === 2, "repeated deletion updates immediately");
            check(Cliphist.entryText(Cliphist.entries[1]) === "Gamma", "remaining row keeps correct payload");
            check(!Cliphist.deleteEntry("999\\tinvalid"), "invalid index does nothing");
            finish.start();
        }
    }
    Timer {
        id: finish; interval: 300
        onTriggered: {
            check(Cliphist.entries.length === 2, "file events must not restore deleted rows");
            console.log(failed ? "HISTORY_TEST_FAILED" : "HISTORY_TEST_PASSED");
            Qt.quit();
        }
    }
}
''')
            env = dict(os.environ, HOME=str(folder), XDG_RUNTIME_DIR=str(runtime),
                       QT_QPA_PLATFORM='offscreen')
            result = subprocess.run(['qs','-p',str(config)],env=env,capture_output=True,text=True,timeout=10)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn('HISTORY_TEST_PASSED', output)
            self.assertNotIn('HISTORY_TEST_FAILED', output)
            self.assertEqual(json.loads(history.read_text()), [initial[0], initial[1], initial[4]])


if __name__ == '__main__':
    unittest.main()
