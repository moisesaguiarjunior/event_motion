#!/usr/bin/env python3
"""Export one PNG from a local ComfyUI API workflow for Event Motion."""

import argparse
import json
import os
from pathlib import Path
from subprocess import TimeoutExpired
from tempfile import NamedTemporaryFile
from time import monotonic, sleep
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import ProxyHandler, Request, build_opener

from illustration_assets import MAX_BYTES, asset_name, check_png


def export(workflow, node, index, port, timeout):
    if not isinstance(workflow, dict) or not isinstance(workflow.get(node), dict):
        raise ValueError("Use a ComfyUI API-format workflow and the ID of its output node.")
    if "class_type" not in workflow[node]:
        raise ValueError("Save the workflow in ComfyUI's API format.")
    client = build_opener(ProxyHandler({}))
    base = f"http://127.0.0.1:{port}"
    deadline = monotonic() + timeout

    def request(route, payload=None, *, image=False):
        remaining = deadline - monotonic()
        if remaining <= 0:
            raise TimeoutError("Timed out waiting for the local ComfyUI workflow.")
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        message = Request(base + route, data=data, headers={"Content-Type": "application/json"})
        try:
            with client.open(message, timeout=min(10, remaining)) as response:
                return check_png(response.read(MAX_BYTES + 1)) if image else json.load(response)
        except HTTPError as error:
            detail = error.read(1024).decode("utf-8", errors="replace")
            raise ValueError(f"ComfyUI {route.split('?')[0]} returned HTTP {error.code}: {detail}") from error
        except URLError as error:
            raise ValueError(f"Cannot reach ComfyUI at {base}: {error.reason}") from error

    submission = request("/prompt", {"prompt": workflow})
    prompt_id = submission.get("prompt_id")
    if not isinstance(prompt_id, str) or not prompt_id:
        raise ValueError("ComfyUI returned no prompt ID.")
    route = "/history/" + quote(prompt_id, safe="")
    history = request(route).get(prompt_id)
    while history is None:
        sleep(min(0.5, max(0, deadline - monotonic())))
        history = request(route).get(prompt_id)
    status = history.get("status", {})
    if status.get("status_str") == "error":
        errors = [data.get("exception_message") for kind, data in status.get("messages", [])
                  if kind == "execution_error" and isinstance(data, dict)]
        raise ValueError(f"ComfyUI workflow failed: {next((e for e in errors if e), 'see local server log')}")
    images = history.get("outputs", {}).get(node, {}).get("images", [])
    if not 0 <= index < len(images):
        raise ValueError(f"ComfyUI node {node} produced no image at index {index}.")
    output = images[index]
    query = urlencode({"filename": output["filename"], "subfolder": output.get("subfolder", ""),
                       "type": output.get("type", "output")})
    return request("/view?" + query, image=True), prompt_id


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workflow", type=Path)
    parser.add_argument("--node", required=True, help="ComfyUI API ID of the image output node")
    parser.add_argument("--index", type=int, default=0)
    parser.add_argument("--port", type=int, default=8188)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535 or args.timeout < 1 or args.index < 0:
        parser.error("expected a valid port, positive timeout and nonnegative index")
    try:
        asset_name(args.out.name)
        if args.out.exists() or args.out.is_symlink():
            raise FileExistsError(f"Artwork already exists: {args.out}")
        workflow = json.loads(args.workflow.read_text(encoding="utf-8"))
        data, prompt_id = export(workflow, args.node, args.index, args.port, args.timeout)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with NamedTemporaryFile(dir=args.out.parent) as temporary:
            temporary.write(data)
            temporary.flush()
            os.link(temporary.name, args.out)
    except (OSError, ValueError, KeyError, TimeoutExpired) as error:
        parser.exit(1, f"{error}\n")
    print(f"Saved {args.out} (ComfyUI prompt {prompt_id})")


if __name__ == "__main__":
    main()
