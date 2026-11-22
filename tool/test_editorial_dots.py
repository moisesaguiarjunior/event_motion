import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import editorial_dots as editorial


def receipt(verdict, findings=None):
    return {"verdict": verdict, "argument": "Editorial direction", "preserve": [],
            "findings": findings or []}


class EditorialTest(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.workspace = Path(scratch.name)
        (self.workspace / ".editorial").mkdir()
        self.brief = {
            "schema_version": 1, "language": "pt-BR", "briefing_markdown": "Synthetic proof.",
            "requested_outputs": ["post", "infographic", "video"],
        }
        self.plan = {
            "status": "ready", "reason": "", "thesis": "A diferença aparece antes do encode.",
            "hook": "O mesmo vídeo. 288 quadros a mais.", "voice": ["Preserve the terse opening."],
            "counterpoint": "Sem estimar tempo de render.", "visual_direction": "A same-duration comparison.",
            "template": "data_story", "media": "both",
            "sources": [{"id": "1", "label": "Fluvie", "date": "", "state": "verified",
                         "url": "https://docs.fluvie.dev/guides/exporting-your-video/",
                         "note": "Frame rate times duration gives the number of frames."}],
            "claims": [{"id": "frames", "text": "8 seconds at 24 and 60 fps.",
                        "source_ids": ["1"]}],
        }
        visual = json.loads((editorial.ROOT / "example/fixtures/data_story.json").read_text())
        self.draft = {
            "status": "ready", "reason": "", "post": self.plan["hook"],
            "alt_text": "Dois traços. Mesma duração.", "decisions": ["Keep the specific opener."],
            "claim_ids": ["frames"], "template": "data_story", "media": "both",
            "visual_json": json.dumps(visual), "new_sources": [], "new_claims": [],
        }

    def process(self, responses):
        stages = []

        class Replies:
            def call(self, role, stage, schema, instructions, context):
                stages.append((role, stage, copy.deepcopy(context)))
                value = responses[stage]
                editorial.check(value, schema)
                return value

        return editorial.process(self.brief, self.workspace, Replies()), stages

    def fake_render(self, visual, draft, logs, artifacts):
        editorial.save(artifacts / "visual.json", visual)
        (artifacts / "post.png").write_bytes(b"png")
        (artifacts / "post.mp4").write_bytes(b"mp4")

    def test_fact_correction_returns_to_opus_and_the_vetted_copy_is_preserved(self):
        fix = dict(self.draft, decisions=["Correct the premise; keep the opening."])
        fix["new_claims"] = [{"id": "new", "text": "Measured frames; duration is still eight seconds.",
                              "source_ids": ["1"]}]
        fix["claim_ids"] = ["new"]
        with patch.object(editorial, "render", side_effect=self.fake_render) as render:
            report, stages = self.process({
                "research": self.plan, "plan": receipt("revise"), "draft": self.draft,
                "draft-review": receipt("revise", [{"kind": "fact", "severity": "blocking",
                                                    "problem": "Old premise", "evidence": "Wrong scope."}]),
                "revision": fix, "revision-review": receipt("ready"),
            })
        self.assertEqual([role for role, _, _ in stages], ["sol", "opus", "sol", "opus", "sol", "opus"])
        self.assertEqual(stages[-1][2]["draft"], fix)
        self.assertEqual(report["status"], "ready_for_review")
        self.assertEqual(render.call_count, 1)
        self.assertEqual((self.workspace / "artifacts/post.md").read_text().strip(), self.plan["hook"])
        self.assertIn("new · Measured", (self.workspace / "artifacts/research-notes.md").read_text())

    def test_voice_block_keeps_a_private_review_packet_without_deliverable(self):
        block = receipt("revise", [{"kind": "voice", "severity": "blocking",
                                    "problem": "Lost the opening", "evidence": "The concrete contrast disappeared."}])
        with patch.object(editorial, "render") as render:
            report, _ = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review": block, "revision": self.draft, "revision-review": block,
            })
        self.assertEqual(report["status"], "needs_sources")
        self.assertNotIn("artifacts/post.md", report["artifacts"])
        render.assert_not_called()

    def test_empty_optional_section_and_bad_source_reference(self):
        visual = json.loads(self.draft["visual_json"])
        visual["timeline"] = []
        visual["timeline_title"] = ""
        editorial.checked_graph(visual, self.plan)
        visual["chart_source"] = "[invented]"
        with self.assertRaises(editorial.EditorialError):
            editorial.checked_graph(visual, self.plan)


if __name__ == "__main__":
    unittest.main()
