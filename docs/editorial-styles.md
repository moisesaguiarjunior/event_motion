# Editorial compositions

Each template exports a 1080 × 1350 canvas from Flutter and Fluvie, with native text and artwork drawn locally. Run the commands from the repository root with Flutter and FFmpeg on your path.

| Command after `bash tool/render_example.sh` | Input to copy | Default output |
| --- | --- | --- |
| `editorial_catalog` | [editorial_catalog.json](../example/fixtures/editorial_catalog.json) | 7.5-second MP4 and full-grid PNG |
| `character_poster` | [workshop_team.json](../example/fixtures/workshop_team.json) | PNG with five illustrated roles |
| `character_dashboard` | [workshop_team.json](../example/fixtures/workshop_team.json) | 8-second MP4 and active-step PNG |

Videos run at 24 fps without an audio track. Files go to `example/build/<composition>/` by default. Supply a custom JSON file and an optional destination after the composition name.

```sh
bash tool/render_example.sh editorial_catalog ./catalog.json ./out/catalog
bash tool/render_example.sh character_poster ./team.json ./out/poster
bash tool/render_example.sh character_dashboard ./team.json ./out/dashboard
```

## Editorial grid

The [catalog schema](../example/spec/catalog.v1.schema.json) uses version 1. Set each tile's `id`, `title`, `note`, and `diagram`. The `tiles` array determines the fixed grid and `order` lists every tile ID once in the desired playback order. Each active tile gets 750 ms. The export holds the completed grid for one second. With twelve tiles the video lasts 10.5 seconds.

Choose `flow` for a sequence, `bars` for a comparison, `curve` for change, or `orbit` for relationships. The marks are illustrative and have no numeric scale. For a quantitative comparison with units, intervals, and sources, use the [comparison example](../example/lib/comparison.dart).

Keep tile titles within 22 characters and notes within 43. Concise copy gives diagrams more room, particularly with nine to twelve tiles, which use three columns. The [twelve-tile fixture](../example/fixtures/editorial_catalog_12.json) demonstrates a dense layout with reverse playback order. Review the final PNG at the size of a phone feed.

## Generate a grid locally

Run Ollama with the default `qwen3.5:4b` model installed, or select another model with `EVENT_MOTION_MODEL`. Set `EVENT_MOTION_OLLAMA_URL` if your local server uses a different endpoint. The command sends the textual brief to the Ollama endpoint and saves a validated, editable catalog alongside the cover and video. On invalid output it returns the field error to the model and allows up to three attempts.

```sh
bash tool/author_catalog.sh example/fixtures/briefs/editorial-catalog.txt ./out/thread
bash tool/render_example.sh editorial_catalog ./out/thread/catalog.json ./out/edited-thread
```

Choose a fresh destination when authoring a new catalog. Rerender the saved catalog after editing the labels or changing the highlight order. Review the resulting copy and claims before posting.

## Character poster and dashboard

The version 1 team document has a `title`, `subtitle`, `summary`, a `lead`, and four `members`. Each character specifies an `id`, a `role` of up to 16 characters, a `note` of up to 43 characters, and a distinct `figure` from `lantern`, `fold`, `seed`, `ticket`, and `seal`.

Member order determines dashboard activation. Each step uses the same event clock for its pulse, callout, status, and feed. The poster uses the five roles and the lead's note on a textured paper surface.

The [reference index](../references/README.md) credits the posts that informed each style. The [verification record](verification.md) describes the model and render checks.
