#!/usr/bin/env python3
"""Recover the original Open Sky 312x232 Stadium 2 map renders at build time.

The original binary asset pack already exists in this repository's Git history.
Current sandbox-safe releases keep the source tree text-only, so the release
workflow deterministically reconstructs only map2d.png for Johto and Kanto,
then verifies the exact hashes used by the validated v20/candidate6 build.
"""

from __future__ import annotations

import base64
import gzip
import hashlib
import io
import tarfile
import urllib.request
import zipfile
import zlib
from pathlib import Path

REPO = "mfrtechconsult/dramatic-sky-ride"
SOURCE_COMMIT = "92c395408e9053e1f2cbfa14027c40815dd0b9c1"
SOURCE_ROOT = "dramatic_sky_ride/assets/open_sky_stadium2_encoded"
DEST_ROOT = Path("dramatic_sky_ride/assets/open_sky_stadium2")

REGIONS = {
    "johto": {
        "parts": 17,
        "sha256": "3871173ba9fc0c2ff73eeaf410caa24506244312bca719292c245e134f07816d",
        "size": 120401,
    },
    "kanto": {
        "parts": 29,
        "sha256": "e9606dbd6ca347f9ceaf0dd5735010a1032024cf9f34740b0505ed17801ba19f",
        "size": 115824,
    },
}

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def download_parts(region: str, count: int) -> list[str]:
    out: list[str] = []
    for i in range(1, count + 1):
        url = (
            f"https://raw.githubusercontent.com/{REPO}/{SOURCE_COMMIT}/"
            f"{SOURCE_ROOT}/{region}/part{i:02d}.b64"
        )
        last_error = None
        for _ in range(3):
            try:
                with urllib.request.urlopen(url, timeout=30) as response:
                    out.append(response.read().decode("ascii").strip())
                break
            except Exception as exc:  # network retry in CI
                last_error = exc
        else:
            raise RuntimeError(f"could not fetch {url}: {last_error}")
    return out


def decoded_variants(parts: list[str]):
    clean = ["".join(part.split()) for part in parts]
    joined = "".join(clean)
    try:
        yield "joined-base64", base64.b64decode(joined)
    except Exception:
        pass
    try:
        yield "per-part-base64", b"".join(base64.b64decode(part) for part in clean)
    except Exception:
        pass


def decompressed_variants(name: str, data: bytes):
    yield name, data
    for suffix, decoder in (
        ("zlib", lambda value: zlib.decompress(value)),
        ("raw-deflate", lambda value: zlib.decompress(value, -15)),
        ("gzip", gzip.decompress),
    ):
        try:
            yield f"{name}+{suffix}", decoder(data)
        except Exception:
            pass


def pngs_embedded_in(data: bytes):
    start = 0
    while True:
        offset = data.find(PNG_SIG, start)
        if offset < 0:
            return
        pos = offset + len(PNG_SIG)
        while pos + 12 <= len(data):
            length = int.from_bytes(data[pos : pos + 4], "big")
            chunk_type = data[pos + 4 : pos + 8]
            pos += 12 + length
            if pos > len(data):
                break
            if chunk_type == b"IEND":
                yield data[offset:pos]
                break
        start = offset + len(PNG_SIG)


def map_candidates(region: str, data: bytes):
    if data.startswith(PNG_SIG):
        yield data

    bio = io.BytesIO(data)
    if zipfile.is_zipfile(bio):
        with zipfile.ZipFile(bio) as archive:
            names = [name for name in archive.namelist() if name.lower().endswith("map2d.png")]
            for name in names:
                if region in name.lower() or len(names) == 1:
                    yield archive.read(name)

    try:
        bio.seek(0)
        with tarfile.open(fileobj=bio, mode="r:*") as archive:
            members = [member for member in archive.getmembers() if member.name.lower().endswith("map2d.png")]
            for member in members:
                if region in member.name.lower() or len(members) == 1:
                    fileobj = archive.extractfile(member)
                    if fileobj:
                        yield fileobj.read()
    except Exception:
        pass

    yield from pngs_embedded_in(data)


def recover(region: str, config: dict) -> bytes:
    parts = download_parts(region, int(config["parts"]))
    expected = str(config["sha256"])
    for variant_name, encoded in decoded_variants(parts):
        for decoded_name, decoded in decompressed_variants(variant_name, encoded):
            for candidate in map_candidates(region, decoded):
                if hashlib.sha256(candidate).hexdigest() == expected:
                    print(f"Recovered {region} from {decoded_name}")
                    return candidate
    raise RuntimeError(f"could not recover validated {region} map from historical asset pack")


def png_dimensions(data: bytes) -> tuple[int, int]:
    if not data.startswith(PNG_SIG) or len(data) < 24:
        raise RuntimeError("invalid PNG")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def main() -> None:
    for region, config in REGIONS.items():
        data = recover(region, config)
        digest = hashlib.sha256(data).hexdigest()
        dimensions = png_dimensions(data)
        if dimensions != (312, 232):
            raise RuntimeError(f"{region}: got {dimensions}, expected 312x232")
        if len(data) != int(config["size"]):
            raise RuntimeError(f"{region}: got {len(data)} bytes, expected {config['size']}")
        if digest != config["sha256"]:
            raise RuntimeError(f"{region}: SHA mismatch {digest}")
        target = DEST_ROOT / region / "map2d.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"PASS {region}: {dimensions[0]}x{dimensions[1]} {len(data)} bytes sha256={digest}")


if __name__ == "__main__":
    main()
