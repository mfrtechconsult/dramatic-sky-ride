#!/usr/bin/env python3
import base64
import hashlib
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "dramatic_sky_ride" / "assets" / "open_sky_stadium2"

MAPS = {
    "johto": {
        "parts": 5,
        "sha256": "8da5768583ac99055eb8272182db7ab44b516fd6762942dee41bc48f9e675487",
    },
    "kanto": {
        "parts": 6,
        "sha256": "a8ef1117cfab550d3cd61b612fbc0a556a834aa36fa0220bc12c3e510c027b2a",
    },
}

for region, cfg in MAPS.items():
    encoded = "".join(
        (ROOT / region / f"map2d_full_part{i:02d}.b64").read_text(encoding="ascii").strip()
        for i in range(1, cfg["parts"] + 1)
    )
    png = base64.b64decode(encoded, validate=True)
    assert png[:8] == b"\x89PNG\r\n\x1a\n", f"{region}: invalid PNG signature"
    width, height = struct.unpack(">II", png[16:24])
    assert (width, height) == (312, 232), f"{region}: {width}x{height}, expected 312x232"
    digest = hashlib.sha256(png).hexdigest()
    assert digest == cfg["sha256"], f"{region}: unexpected SHA256 {digest}"
    assert len(png) > 40000, f"{region}: suspiciously small map asset ({len(png)} bytes)"
    print(f"PASS {region}: {width}x{height} {len(png)} bytes sha256={digest}")

loader = (ROOT.parents[1] / "src" / "main_53f_gen2_open_sky_art_map_01.lua").read_text(encoding="utf-8")
assert "map2d_full_part" in loader, "Open Sky loader does not reference restored multipart maps"
assert "map size %sx%s; expected %dx%d" in loader, "Open Sky runtime size guard missing"
print("PASS Open Sky loader contract")
