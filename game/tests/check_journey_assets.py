#!/usr/bin/env python3
"""Read-only validation; raster authorship is exclusively Aseprite."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
from pathlib import Path
from check_moonlit_assets import png
root = Path(__file__).resolve().parents[2]
manifest = json.loads((root/'game/tests/journey_asset_manifest.json').read_text())
for path, digest in manifest['sha256'].items():
    assert hashlib.sha256((root/path).read_bytes()).hexdigest() == digest, path
for name in ['route','shrine','reveal']:
    base = root/'art_sources/journey'
    native = base/f'{name}_sheet.png'
    assert native.read_bytes() == (root/f'game/assets/sprites/journey/{name}_sheet.png').read_bytes()
    width, height, pixels = png(native)
    assert (width,height)==(480,96) and set(pixels[3::4])=={255}
    cells = [b''.join(pixels[(y*480+i*160)*4:(y*480+(i+1)*160)*4] for y in range(96)) for i in range(3)]
    assert len(set(cells))==3
    meta=json.loads((base/f'{name}.json').read_text())
    assert len(meta['frames'])==3
    assert meta['meta']['frameTags'][0]['name']=='glow'
    for i,frame in enumerate(meta['frames']):
        assert frame['duration']==300 and frame['frame']=={'x':i*160,'y':0,'w':160,'h':96}
    assert (base/f'{name}.aseprite').stat().st_size>128
    print(f'PASS journey {name}: Aseprite source, 3 distinct 300ms frames, opaque RGBA, source/runtime hashes')
