"""Exercise the existing manual workflow's optional immutable source selection."""
import os
from pathlib import Path
import subprocess
import textwrap
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = (ROOT / ".github/workflows/dead-signal-production-release.yml").read_text()
BLOCK = WORKFLOW.split("      - name: Validate optional source commit\n", 1)[1].split("      - uses:", 1)[0]
SCRIPT = textwrap.dedent(BLOCK.split("        run: |\n", 1)[1])


class ReleaseSourcePinTests(unittest.TestCase):
    def run_guard(self, pin, operation="deploy"):
        env = dict(os.environ, SOURCE_SHA=pin, OPERATION=operation)
        return subprocess.run(["bash", "-c", SCRIPT], env=env, capture_output=True, text=True)

    def test_empty_pin_preserves_default_deploy_and_rollback(self):
        for operation in ("deploy", "rollback"):
            with self.subTest(operation=operation):
                self.assertEqual(self.run_guard("", operation).returncode, 0)

    def test_full_reviewed_commit_is_accepted_for_deploy(self):
        self.assertEqual(self.run_guard("62a5de44471d3fe41137b5cb9adb07ace4f7d026").returncode, 0)

    def test_mutable_refs_malformed_and_injected_values_are_rejected(self):
        for pin in ("main", "refs/heads/main", "a"*39, "A"*40, "a"*41, "a"*40+"\necho bad", "$(echo bad)", "a"*40+"; true"):
            with self.subTest(pin=pin):
                self.assertNotEqual(self.run_guard(pin).returncode, 0)

    def test_rollback_rejects_a_pin(self):
        self.assertNotEqual(self.run_guard("a"*40, "rollback").returncode, 0)

    def test_existing_manual_main_environment_and_secret_guards_remain(self):
        self.assertIn("ref: ${{ inputs.source_sha || github.sha }}", WORKFLOW)
        self.assertIn("github.ref == 'refs/heads/main'", WORKFLOW)
        self.assertIn("environment: dead-signal-production", WORKFLOW)
        self.assertIn("${{ secrets.ROBLOX_PRODUCTION_API_KEY }}", WORKFLOW)
        self.assertIn("PUBLISH-V18-PRODUCTION", WORKFLOW)
        self.assertIn("RESTORE-PREVIOUS-PRODUCTION", WORKFLOW)
        self.assertNotIn("  push:", WORKFLOW)
        self.assertNotIn("  pull_request:", WORKFLOW)


if __name__ == "__main__":
    unittest.main()
