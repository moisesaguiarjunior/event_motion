# Local authoring with Ollama

Install Ollama and pull the model before the first use. Start the local server if it is not already running. [Ollama installation](https://docs.ollama.com/macos) · [Structured outputs](https://docs.ollama.com/capabilities/structured-outputs)

```sh
ollama pull qwen3.5:4b
bash tool/author_workflow.sh example/fixtures/briefs/newsletter.txt example/build/newsletter
```

Use a new output directory for each authoring run. It receives `workflow.json`, `workflow.mp4`, and `workflow.png`. You can open the JSON in an editor and render it again without another model call.

```sh
bash tool/render_example.sh agent_pipeline example/build/newsletter/workflow.json example/build/replay
```

Pass a complete agent workflow as a third argument when you already have a timed event log. The model proposes a title and optional subtitle. The command carries forward the original nodes, links, timestamps, locale, and event messages directly from the input document.

```sh
bash tool/author_workflow.sh example/fixtures/briefs/locked-review.txt \
  example/build/locked-review example/fixtures/agent_pipeline.json
```

Set `EVENT_MOTION_MODEL` to another installed model or `EVENT_MOTION_OLLAMA_URL` to another local `/api/chat` URL. The default is `http://127.0.0.1:11434/api/chat`. The command adapts the shape of Fluvie's Ollama client for a plain Dart process. It requests JSON with a schema, applies the renderer's cross-field checks, and can send validation errors back for up to two repair attempts. It saves the successful JSON before starting Flutter so a render failure can be retried from the document. [Fluvie Ollama client](https://github.com/moisesaguiarjunior/fluvie/blob/b2f578a343d8f019cab577bdcef10740545e0fad/packages/fluvie_ai/lib/src/client/ollama_ai_client.dart)
