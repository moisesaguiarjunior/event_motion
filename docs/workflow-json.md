# Agent pipeline JSON

Version 1 feeds a 4:5 panel with node states, animated connections and a recent activity feed. The [schema](../example/spec/workflow.v1.schema.json) describes the fields for authoring and structured output. The [example document](../example/fixtures/agent_pipeline.json) renders the same panel as the default demo.

| Field | Rule |
| --- | --- |
| `version`, `template` | Use `1` and `agent_pipeline`. |
| `title`, `subtitle` | A title of up to 36 characters and an optional subtitle of up to 72. |
| `locale` | Optional `en` or `pt-BR` for status captions and the activity heading. Defaults to `en`. |
| `layout` | `diamond` assigns four nodes to the top, left, right and bottom in input order. `vertical` stacks one to four nodes in input order. |
| `durationMs`, `coverMs` | Use integer milliseconds. The clip must be 250 to 60,000 ms. The cover time must resolve to a frame within the clip. |
| `nodes` | Each node has a unique `id` and a `label` of up to 18 characters. Start IDs with a lowercase ASCII letter and use up to 24 lowercase letters, digits, `_` or `-`. |
| `links` | Each directed connection has `from` and `to` IDs of distinct nodes. An empty array is valid. |
| `events` | Supply at least one event. Each sets `status` to `idle`, `active`, `complete` or `failed` for a `node` at `atMs`. Add `message` of up to 48 characters to show it in the feed. Add `from` to pulse along an existing directed link. |

Keep events in chronological order. At a tie the reader keeps input order, so the last event for a node supplies its state. An event takes effect on the first sampled frame at or after its timestamp. Duration and cover time round to the nearest frame at 24 fps. Use the last sampled frame as the upper bound for events. For example, a four-second clip has frames 0 through 95 and accepts events through 3,958 ms.

The renderer checks rules that depend on values across fields, including timing, unique node IDs and link references. A missing source link might produce `$.events[2].from: connection brief → review is missing from links`. Fix the referenced field and run the same command again. Text fields accept nonblank single-line copy.

```sh
bash tool/render_example.sh agent_pipeline ./workflow.json
```

The renderer writes `workflow.mp4` and `workflow.png` in `example/build/workflow/` by default. Pass an output directory after the JSON path to choose a destination. Keep the input file with the outputs to reproduce a draft or revise it. See [local authoring](local-authoring.md) to generate the same format with Ollama.
