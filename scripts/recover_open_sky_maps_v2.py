#!/usr/bin/env python3
"""Recover the validated Open Sky maps from the repository's historical asset pack.

The release tree stays sandbox-safe and text-only. During CI/release this script
recovers the exact v20/candidate6 312x232 PNGs, verifies their known hashes,
and rewrites the bundled base64 map parts consumed by the current runtime.
"""

from __future__ import annotations

import base64
import gzip
import hashlib
import io
import math
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
        "source_parts": 17,
        "runtime_parts": 5,
        "sha256": "3871173ba9fc0c2ff73eeaf410caa24506244312bca719292c245e134f07816d",
        "size": 120401,
    },
    "kanto": {
        "source_parts": 29,
        "runtime_parts": 6,
        "sha256": "e9606dbd6ca347f9ceaf0dd5735010a1032024cf9f34740b0505ed17801ba19f",
        "size": 115824,
    },
}

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def fetch_source_parts(region: str, count: int) -> list[str]:
    parts: list[str] = []
    for index in range(1, count + 1):
        url = (
            f"https://raw.githubusercontent.com/{REPO}/{SOURCE_COMMIT}/"
            f"{SOURCE_ROOT}/{region}/part{index:02d}.b64"
        )
        last_error = None
        for _ in range(3):
            try:
                with urllib.request.urlopen(url, timeout=30) as response:
                    parts.append(response.read().decode("ascii").strip())
                break
            except Exception as exc:
                last_error = exc
        else:
            raise RuntimeError(f"could not fetch {url}: {last_error}")
    return parts


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


def expanded_variants(name: str, data: bytes):
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


def embedded_pngs(data: bytes):
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

    stream = io.BytesIO(data)
    if zipfile.is_zipfile(stream):
        with zipfile.ZipFile(stream) as archive:
            names = [name for name in archive.namelist() if name.lower().endswith("map2d.png")]
            for name in names:
                if region in name.lower() or len(names) == 1:
                    yield archive.read(name)

    try:
        stream.seek(0)
        with tarfile.open(fileobj=stream, mode="r:*") as archive:
            members = [member for member in archive.getmembers() if member.name.lower().endswith("map2d.png")]
            for member in members:
                if region in member.name.lower() or len(members) == 1:
                    extracted = archive.extractfile(member)
                    if extracted:
                        yield extracted.read()
    except Exception:
        pass

    yield from embedded_pngs(data)


def recover(region: str, config: dict) -> bytes:
    source = fetch_source_parts(region, int(config["source_parts"]))
    expected = str(config["sha256"])
    for variant_name, encoded in decoded_variants(source):
        for decoded_name, decoded in expanded_variants(variant_name, encoded):
            for candidate in map_candidates(region, decoded):
                if hashlib.sha256(candidate).hexdigest() == expected:
                    print(f"Recovered {region} from {decoded_name}")
                    return candidate
    raise RuntimeError(f"could not recover validated {region} map")


def png_dimensions(data: bytes) -> tuple[int, int]:
    if not data.startswith(PNG_SIG) or len(data) < 24:
        raise RuntimeError("invalid PNG")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def write_runtime_assets(region: str, data: bytes, count: int) -> None:
    target_dir = DEST_ROOT / region
    target_dir.mkdir(parents=True, exist_ok=True)

    # Keep the legacy single-file asset correct as a compatibility fallback.
    (target_dir / "map2d.b64").write_text(base64.b64encode(data).decode("ascii"), encoding="ascii")

    # The current sandbox runtime decodes every part independently, then joins
    # the binary chunks. Split bytes first so every .b64 file is standalone.
    chunk_size = math.ceil(len(data) / count)
    for index in range(count):
        chunk = data[index * chunk_size : (index + 1) * chunk_size]
        if not chunk:
            raise RuntimeError(f"{region}: empty runtime map part {index + 1}")
        path = target_dir / f"map2d_full_part{index + 1:02d}.b64"
        path.write_text(base64.b64encode(chunk).decode("ascii"), encoding="ascii")

    # Do not ship accidental/manual staging pieces from the hotfix branch.
    for path in target_dir.glob("map2d_native_part*.b64"):
        path.unlink()


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
        write_runtime_assets(region, data, int(config["runtime_parts"]))
        print(f"PASS {region}: 312x232 {len(data)} bytes sha256={digest}")


if __name__ == "__main__":
    main()
