# Roadmap

The deliverable is a local workflow that turns a brief and optional data into a visual draft for X. Each composition should have a short entry point and a reproducible image or video export.

## 1. Foundation

- [x] Create a Flutter package with a single public import and a caller-supplied clock.
- [x] Implement timeline sampling, node states, directed pulses, and a recent-event feed.
- [x] Add a Fluvie example that exports a 4:5 MP4 and PNG and documents how to run it.
- [x] Cover backward seeks, coincident events, and state shared by graph and feed.
- [ ] Reuse the same timeline in a second composition built around a sequence of cards. Use the example to identify which non-graph components deserve a public API.
- [ ] Check short and long text, localized labels, and layouts at phone feed size.

## 2. Local authoring

- [ ] Specify a versioned JSON contract for the workflow composition. Define layout presets, node IDs, timing, states and copy limits.
- [ ] Convert the JSON into Dart values and report validation errors with field paths. Check chronology, duplicate IDs, connection references and the duration of the scene.
- [ ] Reuse or adapt Fluvie's Ollama client for the local authoring command. Save the generated spec next to the outputs so a second render can use the same inputs.
- [ ] Run the workflow with a local model and several briefs. Compare valid-output rate, latency, readability and whether the result preserves supplied event data.

**Done when** a brief and a local event log produce an editable spec, an MP4 and a PNG through one command, and rerendering the spec produces the same frames.

## 3. Compositions for posts

- [ ] Add a polished activation sequence with step labels, an event feed and a representative cover.
- [ ] Add an editorial comparison image with bars, intervals and source notes. Put numeric scaling and labeling in the renderer.
- [ ] Add a card sequence with a final mosaic and compare a Flutter version against one rendered by HyperFrames.
- [ ] Try a Handcrafted treatment on one composition. Verify legibility at feed size and keep the material styling configurable.
- [ ] Validate 1080 × 1350 output, mobile-feed legibility, cover selection, and optional audio.

## 4. HyperFrames integration

- [ ] Package one local HyperFrames template with a pinned CLI and local assets. Accept the same validated data fields where the scene needs them.
- [ ] Add a command that renders the scene, checks its dimensions, duration, frame rate, and alpha where requested, then adds it to the Fluvie composition.
- [ ] Verify a transparent overlay at a nonzero start frame and an opaque clip with audio. Measure render time and disk use for a full-size example.

**Done when** the same post compiles from source on a clean checkout and the imported scene stays in sync with the Flutter layers.

## 5. Adoption and release

- [ ] Try the first composition through the Social Studio job and review flow.
- [ ] Add CI for analysis, tests and one representative headless render.
- [ ] Document supported Flutter and Fluvie revisions and the scope of the public API.
- [ ] Choose the release license, check bundled assets and dependencies, and review the release candidate before publishing.
