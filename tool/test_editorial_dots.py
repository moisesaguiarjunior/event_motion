from base64 import b64decode
import copy
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib
from subprocess import CalledProcessError, TimeoutExpired
from unittest.mock import patch

import editorial_dots as editorial
from illustration_assets import check_png
from png_alt_text import DESCRIPTION, SIGNATURE, embed_alt_text

ARTWORK_PNG = b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABQABpfZFQAAAAABJRU5ErkJggg==")


def receipt(verdict, findings=None, generator_requests=None):
    return {"verdict": verdict, "argument": "Editorial direction", "preserve": [],
            "findings": findings or [], "generator_requests": generator_requests or []}


class EditorialTest(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.workspace = Path(scratch.name)
        (self.workspace / ".editorial").mkdir()
        self.brief = {
            "schema_version": 1, "language": "pt-BR", "topic": "Editorial proof",
            "briefing_markdown": "Synthetic proof.\n\n- Keep this Markdown.",
            "sources": ["https://docs.fluvie.dev/guides/exporting-your-video/"],
            "requested_outputs": ["post", "infographic", "video"],
        }
        self.plan = {
            "status": "ready", "reason": "", "thesis": "A diferença aparece antes do encode.",
            "hook": "O mesmo vídeo. 288 quadros a mais.",
            "angle_comparison": "Frame counts are sourced. Encode speed was not measured.", "voice": ["Preserve the terse opening."],
            "counterpoint": "Sem estimar tempo de render.", "visual_direction": "A same-duration comparison.",
            "template": "data_story", "media": "both",
            "sources": [{"id": "1", "label": "Fluvie", "date": "", "state": "verified",
                         "url": "https://docs.fluvie.dev/guides/exporting-your-video/",
                         "note": "Frame rate times duration gives the number of frames."}],
            "claims": [{"id": "frames", "text": "8 seconds at 24 and 60 fps.",
                        "source_ids": ["1"]}],
            "generator_requests": [],
        }
        visual = json.loads((editorial.ROOT / "example/fixtures/data_story.json").read_text())
        self.draft = {
            "status": "ready", "reason": "", "post": self.plan["hook"] + " [source:1]",
            "alt_text": "Dois traços. Mesma duração.", "decisions": ["Keep the specific opener."],
            "claim_ids": ["frames"], "template": "data_story", "media": "both",
            "visual_json": json.dumps(visual), "new_sources": [], "new_claims": [],
            "generator_requests": [],
        }
        self.request = {
            "capability": "Colchete entre séries", "medium": "both",
            "reason": "Mostrar a diferença no mesmo instante.",
            "acceptance": "Ligar os pontos das duas séries e rotular a diferença.",
        }

    def process(self, responses):
        stages = []

        class Replies:
            def call(self, role, stage, schema, instructions, context):
                stages.append((role, stage, copy.deepcopy(context)))
                value = responses[stage]
                if isinstance(value, Exception):
                    raise value
                editorial.check(value, schema)
                return value

        return editorial.process(self.brief, self.workspace, Replies()), stages

    def fake_render(self, visual, draft, logs, artifacts):
        editorial.save(artifacts / "visual.json", visual)
        (artifacts / "imagem.png").write_bytes(b"png")
        if draft["media"] == "both":
            (artifacts / "video.mp4").write_bytes(b"mp4")

    def test_fact_correction_returns_to_opus_and_the_vetted_copy_is_preserved(self):
        fix = dict(self.draft, decisions=["Correct the premise; keep the opening."])
        fix["new_claims"] = [{"id": "new", "text": "Measured frames; duration is still eight seconds.",
                              "source_ids": ["1"]}]
        fix["claim_ids"] = ["new"]
        with patch.object(editorial, "render", side_effect=self.fake_render) as render:
            report, stages = self.process({
                "research": self.plan, "plan": receipt("revise", generator_requests=[self.request]),
                "draft": dict(self.draft, generator_requests=[self.request]),
                "draft-review": receipt("revise", [{"kind": "fact", "severity": "blocking",
                                                    "problem": "Old premise", "evidence": "Wrong scope."}]),
                "revision": fix, "revision-review": receipt("ready"),
            })
        self.assertEqual([role for role, _, _ in stages], ["sol", "opus", "sol", "opus", "sol", "opus"])
        self.assertEqual(stages[-1][2]["draft"], fix)
        self.assertEqual(report["status"], "ready_for_review")
        self.assertEqual(render.call_count, 1)
        self.assertEqual(report["artifacts"][:4], [
            "artifacts/pauta.md", "artifacts/post.md", "artifacts/imagem.png", "artifacts/video.mp4",
        ])
        self.assertEqual((self.workspace / "artifacts/post.md").read_text().strip(), self.plan["hook"] + " [1]")
        pauta = (self.workspace / "artifacts/pauta.md").read_text()
        self.assertIn(self.brief["topic"], pauta)
        self.assertIn(self.brief["briefing_markdown"], pauta)
        self.assertIn(self.brief["sources"][0], pauta)
        self.assertIn("new · Measured", (self.workspace / "artifacts/research-notes.md").read_text())
        backlog = (self.workspace / "artifacts/demandas-gerador.md").read_text()
        self.assertEqual(backlog.count("## Colchete entre séries"), 1)
        self.assertIn("Opus · plan, Sol · draft", backlog)
        self.assertIn(self.request["acceptance"], backlog)

    def test_blocked_angle_is_researched_and_reviewed_before_drafting(self):
        blocker = receipt("revise", [{
            "kind": "angle", "severity": "blocking", "problem": "Weak lead",
            "evidence": "The source supports a more consequential comparison.",
        }])
        revised = dict(self.plan, thesis="The choice affects the number of frames encoded.")
        with patch.object(editorial, "render", side_effect=self.fake_render):
            report, stages = self.process({
                "research": self.plan, "plan": blocker, "plan-angle-revision": revised,
                "plan-angle-review": receipt("ready"), "draft": self.draft,
                "draft-review": receipt("ready"),
            })
        self.assertEqual([stage for _, stage, _ in stages],
                         ["research", "plan", "plan-angle-revision", "plan-angle-review",
                          "draft", "draft-review"])
        self.assertEqual(stages[4][2]["plan"]["thesis"], revised["thesis"])
        self.assertEqual(report["status"], "ready_for_review")

    def test_unresolved_angle_stops_before_drafting(self):
        blocker = receipt("revise", [{
            "kind": "angle", "severity": "blocking", "problem": "Missing consequence",
            "evidence": "The revised evidence does not support a useful conclusion.",
        }])
        with patch.object(editorial, "render") as render:
            report, stages = self.process({
                "research": self.plan, "plan": blocker, "plan-angle-revision": self.plan,
                "plan-angle-review": blocker,
            })
        self.assertEqual(stages[-1][1], "plan-angle-review")
        self.assertEqual(report["status"], "needs_sources")
        self.assertNotIn("artifacts/post.md", report["artifacts"])
        render.assert_not_called()

    def test_post_reuses_source_numbers_and_keeps_urls_in_the_reply(self):
        draft = dict(self.draft, post="One verified detail. [source:1] Another. [source:1]")
        with patch.object(editorial, "render", side_effect=self.fake_render):
            report, _ = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": draft,
                "draft-review": receipt("ready"),
            })
        path = self.workspace / "artifacts"
        self.assertEqual((path / "post.md").read_text(), "One verified detail. [1] Another. [1]\n")
        self.assertEqual((path / "sources-reply.txt").read_text(),
                         "[1] Fluvie\nhttps://docs.fluvie.dev/guides/exporting-your-video/\n")
        self.assertIn("artifacts/sources-reply.txt", report["artifacts"])

    def test_post_with_raw_url_returns_to_writer_before_review(self):
        bad = dict(self.draft, post="A link. https://example.com [source:1]")
        with patch.object(editorial, "render", side_effect=self.fake_render):
            report, stages = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": bad,
                "revision": self.draft, "revision-review": receipt("ready"),
            })
        self.assertEqual([stage for _, stage, _ in stages],
                         ["research", "plan", "draft", "revision", "revision-review"])
        self.assertIn("instead of URLs", stages[-2][2]["draft_review"]["argument"])
        self.assertEqual(report["status"], "ready_for_review")

    def test_copy_request_still_gets_an_image(self):
        self.brief["requested_outputs"] = ["post"]
        with patch.object(editorial, "render", side_effect=self.fake_render):
            report, stages = self.process({
                "research": dict(self.plan, media="image"), "plan": receipt("ready"),
                "draft": dict(self.draft, media="image"), "draft-review": receipt("ready"),
            })
        self.assertEqual(stages[0][2]["delivery_outputs"], ["infographic", "post"])
        self.assertEqual(stages[0][2]["brief"]["requested_outputs"], ["post"])
        self.assertIn("artifacts/imagem.png", report["artifacts"])
        self.assertNotIn("artifacts/video.mp4", report["artifacts"])
        self.assertNotIn("artifacts/demandas-gerador.md", report["artifacts"])

    def test_unavailable_visual_still_gets_opus_review_and_delivers_approved_copy(self):
        plan = dict(self.plan, template="none", media="none")
        draft = dict(self.draft, template="none", media="none", visual_json="", alt_text="")
        with patch.object(editorial, "render") as render:
            report, stages = self.process({
                "research": plan, "plan": receipt("ready"), "draft": draft,
                "draft-review": receipt("ready"),
            })
        self.assertEqual([stage for _, stage, _ in stages],
                         ["research", "plan", "draft", "draft-review"])
        self.assertIn("No suitable visual template", stages[1][2]["visual_issue"])
        self.assertEqual(stages[-1][0], "opus")
        self.assertEqual(stages[-1][2]["draft"], draft)
        self.assertIn("No suitable visual template", stages[-1][2]["visual_issue"])
        self.assertEqual(report["status"], "needs_visual")
        self.assertIn("artifacts/post.md", report["artifacts"])
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])
        self.assertNotIn("artifacts/imagem.png", report["artifacts"])
        self.assertNotIn("artifacts/visual.json", report["artifacts"])
        self.assertNotIn("artifacts/alt-text.txt", report["artifacts"])
        self.assertFalse((self.workspace / ".editorial/approved-artifacts.json").exists())
        backlog = (self.workspace / "artifacts/demandas-gerador.md").read_text()
        self.assertIn(plan["visual_direction"], backlog)
        self.assertIn("Imagem e vídeo", backlog)
        render.assert_not_called()

    def test_missing_visual_does_not_bypass_editorial_block(self):
        plan = dict(self.plan, template="none", media="none", generator_requests=[self.request])
        draft = dict(self.draft, template="none", media="none", visual_json="", alt_text="")
        block = receipt("revise", [{"kind": "fact", "severity": "blocking",
                                    "problem": "Wrong denominator", "evidence": "The claim uses a subgroup."}])
        with patch.object(editorial, "render") as render:
            report, stages = self.process({
                "research": plan, "plan": receipt("ready"), "draft": draft,
                "draft-review": block, "revision": draft, "revision-review": block,
            })
        self.assertEqual(stages[-1][1], "revision-review")
        self.assertEqual(report["status"], "needs_sources")
        self.assertNotIn("artifacts/post.md", report["artifacts"])
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])
        render.assert_not_called()

    def test_exhausted_visual_repair_records_a_demand(self):
        draft = dict(self.draft, visual_json="[]")
        with patch.object(editorial, "render") as render:
            report, stages = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": draft,
                "draft-review-format": draft, "draft-review": receipt("ready"),
            })
        self.assertEqual(stages[-2][1], "draft-review-format")
        self.assertIn("visual must be a JSON object", stages[-1][2]["visual_issue"])
        self.assertEqual(report["status"], "needs_visual")
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])
        render.assert_not_called()

    def test_unavailable_plan_can_use_an_installed_composition(self):
        visual = json.loads(
            (editorial.ROOT / "example/fixtures/data_story_composition.json").read_text()
        )
        source = dict(self.plan["sources"][0], id="sample")
        claim = dict(self.plan["claims"][0], text="Illustrative shares total 100.",
                     source_ids=["sample"])
        plan = dict(self.plan, template="none", media="none", sources=[source],
                    claims=[claim])
        draft = dict(self.draft, visual_json=json.dumps(visual),
                     post="Four shares of an illustrative budget. [source:sample]")
        with patch.object(editorial, "render", side_effect=self.fake_render) as render:
            report, stages = self.process({
                "research": plan, "plan": receipt("ready"),
                "draft": draft, "draft-review": receipt("ready"),
            })
        self.assertEqual(stages[-1][2]["visual_issue"], "")
        self.assertEqual(report["status"], "ready_for_review")
        self.assertEqual(render.call_args.args[0], visual)
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])

        visual["series"][0]["values"][-1] -= 1
        with self.assertRaisesRegex(editorial.EditorialError, "positive shares totaling 100"):
            editorial.checked_draft(dict(draft, visual_json=json.dumps(visual)), plan)

    def test_catalog_contract_is_repaired_before_opus(self):
        catalog = json.loads((editorial.ROOT / "example/fixtures/editorial_catalog.json").read_text())
        self.brief["requested_outputs"] = ["post"]
        valid = dict(self.draft, template="editorial_catalog", media="image",
                     visual_json=json.dumps(catalog))
        invalid = dict(catalog, tiles=catalog["tiles"][:4], order=catalog["order"][:4])
        with patch.object(editorial, "render", side_effect=self.fake_render):
            report, stages = self.process({
                "research": dict(self.plan, template="editorial_catalog", media="image"),
                "plan": receipt("ready"),
                "draft": dict(valid, visual_json=json.dumps(invalid)),
                "draft-review-format": valid,
                "draft-review": receipt("ready"),
            })
        self.assertEqual(report["status"], "ready_for_review")
        self.assertIn("$.tiles: expected 8–12 entries", stages[-2][2]["validation_error"])
        self.assertEqual(stages[-1][2]["draft"], valid)
        long_title = copy.deepcopy(catalog)
        long_title["tiles"][0]["title"] = "a" * 23
        with self.assertRaisesRegex(editorial.EditorialError, r"tiles\[0\]\.title"):
            editorial.checked_draft(dict(valid, visual_json=json.dumps(long_title)), self.plan)

    def test_matrix_checks_verified_sources_and_preserves_requests_on_render_failure(self):
        matrix = (editorial.ROOT / "example/fixtures/editorial_matrix.json").read_text()
        self.brief["requested_outputs"] = ["post"]
        draft = dict(self.draft, template="editorial_matrix", media="image", visual_json=matrix,
                     post=self.plan["hook"] + " [source:S1]")
        with self.assertRaisesRegex(editorial.EditorialError, "verified source IDs"):
            editorial.checked_draft(draft, self.plan)
        sources = [dict(self.plan["sources"][0], id=f"S{i}") for i in range(1, 7)]
        plan = dict(self.plan, template="editorial_matrix", media="image", sources=sources)
        plan["claims"] = [dict(self.plan["claims"][0], source_ids=["S1"])]
        with patch.object(editorial, "render", side_effect=CalledProcessError(1, "renderer")):
            with self.assertRaises(CalledProcessError):
                self.process({
                    "research": plan, "plan": receipt("ready"), "draft": draft,
                    "draft-review": receipt("ready", generator_requests=[self.request]),
                })
        backlog = (self.workspace / "artifacts/demandas-gerador.md").read_text()
        self.assertIn("Opus · draft-review", backlog)
        self.assertIn(self.request["acceptance"], backlog)

    def test_illustration_uses_reviewed_layers_and_rejects_unverified_citations(self):
        path = editorial.ROOT / "example/fixtures/editorial_illustration.json"
        visual = json.loads(path.read_text())
        plan = dict(self.plan, template="editorial_illustration")
        draft = dict(self.draft, template="editorial_illustration", visual_json=json.dumps(visual))
        with self.assertRaisesRegex(editorial.EditorialError, "verified source IDs"):
            editorial.checked_draft(draft, plan)
        plan["sources"] = [*plan["sources"], dict(plan["sources"][0], id="2")]
        with patch.object(editorial, "render", side_effect=self.fake_render) as render:
            report, stages = self.process({
                "research": plan, "plan": receipt("ready"), "draft": draft,
                "draft-review": receipt("ready"),
            })
        self.assertEqual(report["status"], "ready_for_review")
        self.assertEqual(stages[-1][2]["draft"], draft)
        expected = dict(visual, alt_text=draft["alt_text"])
        self.assertEqual(render.call_args.args[0], expected)
        self.assertEqual(json.loads((self.workspace / "artifacts/visual.json").read_text()), expected)
        replay_alt = (self.workspace / "artifacts/alt-text.txt").read_text().strip()
        self.assertEqual(replay_alt, expected["alt_text"])
        self.assertIn("artifacts/video.mp4", report["artifacts"])

        visual["annotation"]["source_ids"] = ["unknown"]
        with self.assertRaisesRegex(editorial.EditorialError, r"annotation\.source_ids\[0\]"):
            editorial.checked_draft(dict(draft, visual_json=json.dumps(visual)), plan)

    def test_illustration_packages_only_named_local_artwork(self):
        visual = json.loads((editorial.ROOT / "example/fixtures/editorial_illustration.json").read_text())
        visual["destinations"][0]["asset"] = "chip.png"
        plan = dict(self.plan, template="editorial_illustration")
        plan["sources"] = [*plan["sources"], dict(plan["sources"][0], id="2")]
        draft = dict(self.draft, template="editorial_illustration", visual_json=json.dumps(visual))
        with self.assertRaisesRegex(editorial.EditorialError, "approved PNGs"):
            editorial.checked_draft(draft, plan)
        unsafe = copy.deepcopy(visual)
        unsafe["destinations"][0]["asset"] = "../chip.png"
        with self.assertRaisesRegex(editorial.EditorialError, r"destinations\[0\]\.asset"):
            editorial.checked_draft(dict(draft, visual_json=json.dumps(unsafe)), plan, ["chip.png"])

        library = self.workspace / "local-library"
        library.mkdir()
        png = ARTWORK_PNG
        (library / "chip.png").write_bytes(png)
        self.brief["illustration_assets"] = ["chip.png"]
        with patch.object(editorial, "ILLUSTRATION_ASSET_LIBRARY", library), patch.object(
            editorial, "render", side_effect=self.fake_render,
        ):
            report, _ = self.process({
                "research": plan, "plan": receipt("ready"), "draft": draft,
                "draft-review": receipt("ready"),
            })
        self.assertEqual(report["status"], "ready_for_review")
        self.assertIn("artifacts/assets/chip.png", report["artifacts"])
        self.assertEqual((self.workspace / "artifacts/assets/chip.png").read_bytes(), png)

    def test_illustration_asset_rejects_truncated_animated_and_undecodable_png(self):
        with self.assertRaisesRegex(ValueError, "complete PNG"):
            check_png(ARTWORK_PNG[:33])

        animated_control = b"acTL" + struct.pack(">II", 2, 0)
        animated = (ARTWORK_PNG[:33] + struct.pack(">I", 8) + animated_control
                    + struct.pack(">I", zlib.crc32(animated_control)) + ARTWORK_PNG[33:])
        with self.assertRaisesRegex(ValueError, "single-frame PNG"):
            check_png(animated)

        invalid_idat = b"IDAT\0\0"
        invalid = (ARTWORK_PNG[:33] + struct.pack(">I", 2) + invalid_idat
                   + struct.pack(">I", zlib.crc32(invalid_idat)) + ARTWORK_PNG[-12:])
        with self.assertRaisesRegex(ValueError, "cannot be decoded"):
            check_png(invalid)

    def test_voice_block_keeps_a_private_review_packet_without_deliverable(self):
        block = receipt("revise", [{"kind": "voice", "severity": "blocking",
                                    "problem": "Lost the opening", "evidence": "The concrete contrast disappeared."}],
                        generator_requests=[dict(self.request, acceptance=" ")])
        with patch.object(editorial, "render") as render:
            report, _ = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review": block, "revision": self.draft, "revision-review": block,
            })
        self.assertEqual(report["status"], "needs_sources")
        self.assertEqual(report["artifacts"], [
            "artifacts/pauta.md", "artifacts/research-notes.md", "artifacts/editorial-review.md",
            "artifacts/demandas-gerador.md",
        ])
        backlog = (self.workspace / "artifacts/demandas-gerador.md").read_text()
        self.assertIn("## Colchete entre séries", backlog)
        self.assertIn("Opus · draft-review, Opus · revision-review", backlog)
        self.assertIn("**Critério de aceite** · A detalhar.", backlog)
        render.assert_not_called()

    def test_render_contract_failure_repairs_visual_without_rewriting_post(self):
        alternate = dict(self.draft, post="Changed post must be ignored")
        failure = editorial.VisualRenderError("$.title: expected shorter copy", repairable=True)
        with patch.object(editorial, "render", side_effect=[failure, None]) as render:
            (self.workspace / "artifacts").mkdir()
            (self.workspace / "artifacts/imagem.png").write_bytes(b"png")
            (self.workspace / "artifacts/video.mp4").write_bytes(b"mp4")
            report, stages = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review": receipt("ready"), "draft-review-format": alternate,
                "draft-review-format-review": receipt("ready"),
            })
        self.assertEqual(report["status"], "ready_for_review")
        self.assertEqual(render.call_count, 2)
        self.assertEqual(render.call_args.args[1]["post"], self.draft["post"])
        self.assertEqual(stages[-1][1], "draft-review-format-review")

    def test_preflight_and_format_writer_timeouts_still_allow_opus_review(self):
        with patch.object(editorial, "checked_draft",
                          side_effect=TimeoutExpired("visual preflight", 30)):
            report, stages = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review-format": TimeoutExpired("format writer", 420),
                "draft-review": receipt("ready"),
            })
        self.assertEqual(stages[-1][:2], ("opus", "draft-review"))
        self.assertIn("visual preflight", stages[-1][2]["visual_issue"])
        self.assertIn("format writer", stages[-1][2]["visual_issue"])
        self.assertEqual(report["status"], "needs_visual")
        self.assertIn("artifacts/post.md", report["artifacts"])
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])

    def test_render_contract_repair_preflight_timeout_preserves_approved_copy(self):
        failure = editorial.VisualRenderError("$.title: expected shorter copy", repairable=True)
        visual = json.loads(self.draft["visual_json"])
        with patch.object(editorial, "render", side_effect=failure) as render, patch.object(
            editorial, "checked_draft", side_effect=[visual, TimeoutExpired("visual preflight", 30)]
        ):
            report, stages = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review": receipt("ready"), "draft-review-format": self.draft,
            })
        self.assertEqual(stages[-2][:2], ("opus", "draft-review"))
        self.assertEqual(report["status"], "needs_visual")
        self.assertIn("visual preflight", report["summary"])
        self.assertIn("artifacts/post.md", report["artifacts"])
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])
        self.assertIn("artifacts/visual.json", report["artifacts"])
        render.assert_called_once()

    def test_unavailable_renderer_preserves_review_packet(self):
        with patch.object(editorial, "render",
                          side_effect=editorial.VisualRenderError("Renderer unavailable")):
            report, _ = self.process({
                "research": self.plan, "plan": receipt("ready"), "draft": self.draft,
                "draft-review": receipt("ready"),
            })
        self.assertEqual(report["status"], "needs_visual")
        self.assertIn("Renderer unavailable", report["summary"])
        self.assertIn("artifacts/post.md", report["artifacts"])
        self.assertIn("artifacts/demandas-gerador.md", report["artifacts"])
        self.assertIn("artifacts/research-notes.md", report["artifacts"])
        self.assertIn("artifacts/visual.json", report["artifacts"])
        self.assertNotIn("artifacts/imagem.png", report["artifacts"])

    def test_empty_optional_section_and_bad_source_reference(self):
        visual = json.loads(self.draft["visual_json"])
        visual["timeline"] = []
        visual["timeline_title"] = ""
        editorial.checked_graph(visual, self.plan)
        visual["chart_source"] = "[invented]"
        with self.assertRaises(editorial.EditorialError):
            editorial.checked_graph(visual, self.plan)

    def test_png_alt_text_preserves_pixels_and_replaces_description(self):
        def chunk(kind, payload):
            body = kind + payload
            return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body))

        header = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
        pixels = chunk(b"IDAT", zlib.compress(b"\0\xff\xff\xff"))
        end = chunk(b"IEND", b"")
        path = self.workspace / "poster.png"
        path.write_bytes(SIGNATURE + header + pixels + end)
        embed_alt_text(path, "old heading")
        embed_alt_text(path, "1×, média")
        encoded = path.read_bytes()
        self.assertEqual(encoded.count(DESCRIPTION), 1)
        self.assertIn(chunk(b"iTXt", DESCRIPTION + b"\0\0\0\0" + "1×, média".encode()), encoded)
        self.assertEqual(encoded[:len(SIGNATURE + header + pixels)], SIGNATURE + header + pixels)
        self.assertTrue(encoded.endswith(end))


if __name__ == "__main__":
    unittest.main()
