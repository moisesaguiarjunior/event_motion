"""Local PNG sidecars for editorial illustrations."""

from pathlib import Path
import re
import struct

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
