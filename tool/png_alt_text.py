#!/usr/bin/env python3
"""Write a UTF-8 PNG Description at export while preserving the pixel data."""

import argparse
import json
import os
from pathlib import Path
import struct
from tempfile import NamedTemporaryFile
import zlib


SIGNATURE = b"\x89PNG\r\n\x1a\n"
DESCRIPTION = b"Description\0"


def embed_alt_text(path, description):
    if "\0" in description:
        raise ValueError("PNG descriptions cannot contain NUL characters")
    original = path.read_bytes()
    if not original.startswith(SIGNATURE):
        raise ValueError("Expected a PNG signature")
    payload = DESCRIPTION + b"\0\0\0\0" + description.encode("utf-8")
    content = b"iTXt" + payload
    chunk = struct.pack(">I", len(payload)) + content + struct.pack(">I", zlib.crc32(content))
    result = bytearray(SIGNATURE)
    offset = len(SIGNATURE)
    while offset + 12 <= len(original):
        length, kind = struct.unpack_from(">I4s", original, offset)
        end = offset + 12 + length
        if end > len(original):
            break
        if kind == b"IEND" and end == len(original) and length == 0:
            result.extend(chunk)
            result.extend(original[offset:end])
            with NamedTemporaryFile(dir=path.parent, delete=False) as output:
                temporary = Path(output.name)
                try:
                    output.write(result)
                    output.close()
                    temporary.chmod(path.stat().st_mode & 0o777)
                    temporary.replace(path)
                finally:
                    temporary.unlink(missing_ok=True)
            return
        if kind not in {b"tEXt", b"zTXt", b"iTXt"} or not original[
            offset + 8:end - 4
        ].startswith(DESCRIPTION):
            result.extend(original[offset:end])
        offset = end
    raise ValueError("Expected a complete PNG ending with IEND")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("png", type=Path)
    parser.add_argument("visual", nargs="?", type=Path)
    args = parser.parse_args()
    description = os.environ.get("EVENT_MOTION_EDITORIAL_ALT_TEXT", "").strip()
    if not description and args.visual:
        description = json.loads(args.visual.read_text(encoding="utf-8")).get("alt_text", "")
    if not isinstance(description, str):
        parser.error("alt_text must be a string")
    if description.strip():
        embed_alt_text(args.png, description.strip())


if __name__ == "__main__":
    main()
