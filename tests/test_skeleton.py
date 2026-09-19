from __future__ import annotations

import hashlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRAINSTORM_SHA256 = (
    "adfc636252b6ed1fd398bbb7c4d1e7f735e5c492684e6fb852cbaabcb2cf9a2e"
)


class SkeletonTests(unittest.TestCase):
    def test_repository_ships_no_custom_skills(self) -> None:
        self.assertFalse((ROOT / "skills").exists())
        self.assertNotIn("COPY skills/", (ROOT / "Dockerfile").read_text())

    def test_identity_is_explicit_and_capabilities_are_not_claimed(self) -> None:
        persona = (ROOT / "runtime/persona.md").read_text()
        self.assertIn("You are Scheduling Agent", persona)
        self.assertIn("has not been implemented", persona)
        self.assertIn("Never\ncreate background monitoring jobs", persona)

    def test_compose_uses_scheduling_agent_identity(self) -> None:
        compose = (ROOT / "compose.yml").read_text()
        self.assertIn("AGENT_ID: ${AGENT_ID:-scheduling-agent}", compose)
        self.assertIn("platform: linux/amd64", compose)
        self.assertIn("scheduling-agent-home:/var/lib/hermes", compose)

    def test_usage_reporter_comes_from_the_base_image(self) -> None:
        self.assertFalse((ROOT / "image/s6-overlay/s6-rc.d/agent-index").exists())
        self.assertFalse((ROOT / "vendor/client.pin").exists())
        self.assertNotIn("vendor/client.pin", (ROOT / "Dockerfile").read_text())

    def test_sam_brainstorm_is_preserved_verbatim(self) -> None:
        document = (
            ROOT / "docs/SAM_SCHEDULING_AGENT_BRAINSTORM.md"
        ).read_bytes()
        marker = b"implemented by the current agent skeleton.\n"
        body = document.split(marker, 1)[1].lstrip(b"\n").rstrip(b"\n")
        original_shape = b"\n" + body
        self.assertEqual(
            EXPECTED_BRAINSTORM_SHA256,
            hashlib.sha256(original_shape).hexdigest(),
        )


if __name__ == "__main__":
    unittest.main()
