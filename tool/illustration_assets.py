"""Local PNG sidecars for editorial illustrations."""

from pathlib import Path
import re
import struct
import subprocess
import zlib

from png_alt_text import SIGNATURE


MAX_BYTES = 4 * 1024 * 1024
MAX_SIDE = 2048
ASSET_NAME = re.compile(r"[a-z0-9][a-z0-9_-]{0,47}\.png\Z")


def asset_name(value):
    if not isinstance(value, str) or not ASSET_NAME.fullmatch(value):
        raise ValueError("Artwork must use a lowercase PNG filename, without a path.")
    return value


def check_png(data):
    if len(data) > MAX_BYTES:
        raise ValueError("Artwork exceeds 4 MiB.")
    if len(data) < 33 or not data.startswith(SIGNATURE + b"\0\0\0\rIHDR"):
        raise ValueError("Artwork must be a PNG image.")
    width, height = struct.unpack_from(">II", data, 16)
    if not (1 <= width <= MAX_SIDE and 1 <= height <= MAX_SIDE):
        raise ValueError("Artwork must fit within 2048 × 2048 px.")

    offset = len(SIGNATURE)
    complete = False
    while offset + 12 <= len(data):
        size, kind = struct.unpack_from(">I4s", data, offset)
        content_end = offset + 8 + size
        end = content_end + 4
        if end > len(data):
            break
        crc, = struct.unpack_from(">I", data, content_end)
        if crc != zlib.crc32(data[offset + 4:content_end]):
            raise ValueError("Artwork contains a damaged PNG chunk.")
        if kind in {b"acTL", b"fcTL", b"fdAT"}:
            raise ValueError("Artwork must be a single-frame PNG.")
        if kind == b"IEND":
            complete = size == 0 and end == len(data)
            break
        offset = end
    if not complete:
        raise ValueError("Artwork must be a complete PNG image.")

    decoded = subprocess.run(
        ["ffmpeg", "-v", "error", "-xerror", "-i", "pipe:0", "-map", "0:v:0",
         "-frames:v", "1", "-abort_on", "empty_output", "-f", "null", "-"],
        input=data, capture_output=True, timeout=15,
    )
    if decoded.returncode:
        raise ValueError("Artwork contains PNG image data that cannot be decoded.")
    return data


def read_asset(directory, name):
    directory = Path(directory)
    path = directory / asset_name(name)
    if directory.is_symlink() or path.is_symlink() or not path.is_file():
        raise ValueError(f"Artwork {name} is missing from the local asset directory.")
    with path.open("rb") as stream:
        return check_png(stream.read(MAX_BYTES + 1))


def referenced_assets(visual):
    cards = [visual["origin"], visual["channel"], *visual["destinations"]]
    return tuple(dict.fromkeys(asset_name(card["asset"]) for card in cards if "asset" in card))
