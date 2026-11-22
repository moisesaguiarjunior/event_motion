# Roadmap

The deliverable is a local workflow that turns a brief and optional data into a visual draft for X. Each composition should have a short entry point and a reproducible image or video export.

## 1. Foundation

- [x] Create a Flutter package with a single public import and a caller-supplied clock.
- [x] Implement timeline sampling, node states, directed pulses, and a recent-event feed.
- [x] Add a Fluvie example that exports a 4:5 MP4 and PNG and documents how to run it.
- [x] Cover backward seeks, coincident events, and state shared by graph and feed.
- [x] Reuse the same timeline in a second composition built around a sequence of cards. The existing frame API covers card reveals, layout changes and custom paint. Keep the card treatment in the example until a second design needs it.
- [x] Check short and long text, localized labels, and layouts at phone feed size.

## 2. Local authoring

- [x] Specify a versioned JSON contract for the workflow composition. Define layout presets, node IDs, timing, states and copy limits.
- [x] Convert the JSON into Dart values and report validation errors with field paths. Check chronology, duplicate IDs, connection references and the duration of the scene.
- [x] Adapt Fluvie's Ollama request for the local authoring command. Save the generated spec next to the outputs for a second render.
- [x] Run the workflow with a local model and several briefs. Compare valid-output rate, latency, readability and preservation of supplied event data.

**Done when** a brief and a local event log produce an editable spec, an MP4 and a PNG through one command, and rerendering the spec produces the same frames.

## 3. Compositions for posts

- [x] Add a polished activation sequence with step labels, an event feed and a representative cover.
- [x] Add an editorial comparison image with bars, intervals and source notes. Put numeric scaling and labeling in the renderer.
- [x] Add a Flutter card sequence with a final mosaic.
- [x] Render a matching card sequence in HyperFrames and compare authoring effort, visual quality and export time.
- [x] Try a Handcrafted treatment on one composition. Verify legibility at feed size and keep the material styling configurable.
- [x] Validate 1080 × 1350 output, mobile-feed legibility, cover selection, and optional audio.

## 4. HyperFrames integration

- [x] Package one local HyperFrames template with a pinned CLI and local assets. Accept the same validated card data as Flutter.
- [x] Add a command that renders the scene, checks its dimensions, duration, frame rate, and alpha where requested, then adds it to the Fluvie composition.
- [x] Verify a transparent overlay at a nonzero start frame and an opaque clip with audio. Measure render time and disk use for a full-size example.

**Done when** the same post compiles from source on a clean checkout and the imported scene stays in sync with the Flutter layers.

## 5. Adoption and release

- [x] Try the first composition through the Social Studio job and review flow.
- [x] Add CI for analysis, tests and one representative headless render.
- [x] Document supported Flutter and Fluvie revisions and the scope of the public API.
- [x] Choose the release license, check bundled assets and dependencies, and review the release candidate before publishing the package.

See the [verification record](verification.md) for the clean-checkout render, model evaluation, adoption test, and package dry run.

## 6. Editorial motion and character compositions

- [x] Assemble the eight reference posts and the completed v0.1.0 examples in a local reference folder. Record original sources and visual notes.
- [x] Build an editorial grid with eight to twelve cells, native text, and animated miniature diagrams. Export a guided MP4 and a complete PNG poster from the same document.
- [x] Connect the grid to local Ollama authoring. Validate cell IDs, diagram types, copy lengths, and highlight order before capture.
- [x] Build a set of original Handcrafted characters and export an editorial character poster driven by a team document.
- [x] Use the same characters in an animated dashboard with curved signals, an event feed, progress totals, and an ending summary.
- [x] Check phone-size readability, the beginning and end states of each composition, motion at intermediate frames, repeatability, and the existing v0.1.0 examples.
- [x] Check the new headless exports in CI, version the verified source, and assemble the local reference library with the final artifacts.

See the [command and input guide](editorial-styles.md), the [verification record](verification.md#editorial-compositions-in-020), and the [reference library](../references/README.md).

## 7. Custom styles, group motion, and Story review

- [x] Add editable palettes, per-tile diagram accents, and per-character colors with version 1 compatibility.
- [x] Add faster dashboard motion and simultaneous activation groups. Verify two batches and preserve the approved standard renders.
- [x] Fix the Social Studio activity feed and caption overlap and verify the 9:16 Story export.
- [x] Archive the follow-up examples and publish the verified source.

## 8. Dots illustration pipeline

| Stage | Scope | Verification |
| --- | --- | --- |
| Initial integration | `editorial_illustration` exports an editable diagram, PNG, and optional silent MP4. ComfyUI supplies local PNG layers. GSAP drives the existing HyperFrames composition. | Replay the illustration from its packaged JSON and assets. Check the transparent HyperFrames clip and the Fluvie composite. |
| Next | Produce a review contact sheet from the key frames already defined by the visual or the composition. | Prepare a 360 px contact sheet that makes missing cards, text, and overlays visible before review. |
| After a suitable brief | Add one new arrangement or a 3D asset recipe when a technology story needs it. Compare an existing diagram with a local Three.js or Blender render when geometry is part of the explanation. | Save the fixture, reusable assets, and export command. Confirm the image reads at feed size and the source package can be replayed. |

Use the normal Dots queue for editorial briefs. Validate integrations with local fixtures, then obtain an independent Astra review of the candidate before merging. Update the [illustration map](mapa-de-ilustracoes.md) with verified reuse and the conditions for each extension.
