#!/usr/bin/env python3
import base64
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "dramatic_sky_ride" / "assets" / "open_sky_stadium2"

MAPS = {
    "johto": {
        "parts": 5,
        "size": 120401,
        "sha256": "3871173ba9fc0c2ff73eeaf410caa24506244312bca719292c245e134f07816d",
    },
    "kanto": {
        "parts": 6,
        "size": 115824,
        "sha256": "e9606dbd6ca347f9ceaf0dd5735010a1032024cf9f34740b0505ed17801ba19f",
    },
}

for region, cfg in MAPS.items():
    data = b"".join(
        base64.b64decode((ROOT / region / f"map2d_full_part{i:02d}.b64").read_text(encoding="ascii"), validate=True)
        for i in range(1, cfg["parts"] + 1)
    )
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{region}: invalid PNG signature"
    width, height = struct.unpack(">II", data[16:24])
    assert (width, height) == (312, 232), f"{region}: {width}x{height}, expected 312x232"
    assert len(data) == cfg["size"], f"{region}: {len(data)} bytes, expected {cfg['size']}"
    digest = hashlib.sha256(data).hexdigest()
    assert digest == cfg["sha256"], f"{region}: unexpected SHA256 {digest}"

    single = base64.b64decode((ROOT / region / "map2d.b64").read_text(encoding="ascii"), validate=True)
    assert single == data, f"{region}: compatibility map2d.b64 does not match multipart asset"
    print(f"PASS {region}: {width}x{height} {len(data)} bytes sha256={digest}")

loader = (ROOT.parents[1] / "src" / "main_53f_gen2_open_sky_art_map_01.lua").read_text(encoding="utf-8")
assert "map2d_full_part" in loader, "Open Sky loader does not use verified multipart maps"
assert "readJoinedBytes" in loader, "Open Sky loader must decode multipart chunks independently"
assert "map size %sx%s; expected %dx%d" in loader, "Open Sky runtime size guard missing"

manifest = json.loads((ROOT.parents[1] / "manifest.json").read_text(encoding="utf-8"))
assert "filesystem" not in manifest.get("permissions", []), manifest.get("permissions")
print("PASS Open Sky loader + sandbox contract")
