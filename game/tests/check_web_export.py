#!/usr/bin/env python3
"""Read-only exported bundle checks; does not claim a browser/HTTP test."""
import gzip
import json
from pathlib import Path
import re
import struct

root = Path(__file__).resolve().parents[2]
web = root / 'build/web'
html = (web / 'index.html').read_text()
assert 'const GODOT_THREADS_ENABLED = false;' in html
assert '$GODOT_' not in html
assert 'turn-based FIRE, WATER, EARTH, WIND' in html
config = json.loads(re.search(r'const GODOT_CONFIG = (.+);', html)[1])
assert config['canvasResizePolicy'] == 0
assert not config.get('serviceWorker') and not config.get('experimentalVK')
for name, size in config['fileSizes'].items():
    assert (web / name).stat().st_size == size
assert (web / 'index.wasm').read_bytes()[:8] == b'\0asm\x01\0\0\0'
# Read Godot 4.5 PCK v3 directory to catch omitted script dependencies.
pck = (web / 'index.pck').read_bytes()
assert pck[:4] == b'GDPC'
version, major, minor, patch, flags = struct.unpack_from('<5I', pck, 4)
assert (version, major, minor, patch, flags) == (3, 4, 5, 1, 2)
directory_offset = struct.unpack_from('<Q', pck, 32)[0]
count = struct.unpack_from('<I', pck, directory_offset)[0]
pos = directory_offset + 4
paths = []
for _ in range(count):
    length = struct.unpack_from('<I', pck, pos)[0]
    pos += 4
    paths.append(pck[pos:pos + length].rstrip(b'\0').decode())
    pos += length + 8 + 8 + 16 + 4
assert any(p.endswith('scripts/combat_model.gdc') for p in paths), paths
assert not any('/tests/' in p or '/tools/' in p or '/web/' in p or 'art_sources/' in p or p.endswith(('.json','.aseprite','.lua','.gif','.gd')) for p in paths)
for script in ['area_panel','data/weapon_spec','run_model','combat_event','data/element','data/encounter_spec','duel','arena_view','fighter_view','hud','run_modal','effects_view','frame_playback','layout_helper','touch_action','browser_lifecycle']:
    assert any(p.endswith('scripts/'+script+'.gdc') for p in paths), script
for scene in ['route','shrine','reveal']:
    assert any(p.endswith('scenes/'+scene+'.tscn.remap') or p.endswith('scenes/'+scene+'.tscn') for p in paths), scene
    assert any(scene+'_sheet.png-' in p and p.endswith('.ctex') for p in paths), scene
for encounter in ['gate_guard','fire_rival','earth_sentinel','wind_assassin','courtyard_retainer','ember_monk','mixed_elite','dojo_master']:
    assert any(p.endswith('data/encounters/'+encounter+'.tres.remap') or p.endswith('data/encounters/'+encounter+'.tres') for p in paths), encounter
for name in ['ninja_support','samurai_support','dojo_backdrops','dojo_props','combat_fx','dojo_icons']:
    assert any(p.endswith('assets/frames/moonlit_dojo/'+name+'_frames.tres.remap') or p.endswith('assets/frames/moonlit_dojo/'+name+'_frames.tres') for p in paths), name
    assert any(name+'_sheet.png-' in p and p.endswith('.ctex') for p in paths), name
for name in ['ninja','samurai']:
    assert any(name+'_attack_sheet.png-' in p and p.endswith('.ctex') for p in paths), name
assert not any(p.endswith(('scripts/data/pattern_spec.gdc', 'scripts/data/strike_spec.gdc')) for p in paths)
for name in ['water','fire','earth','wind']:
    assert any(p.endswith('assets/frames/elements/'+name+'_frames.tres.remap') or p.endswith('assets/frames/elements/'+name+'_frames.tres') for p in paths), name
    assert any(name+'_sheet.png-' in p and p.endswith('.ctex') for p in paths), name
assert len(pck) <= 1048576, 'PCK exceeds 1 MiB'

raw = compressed = 0
for path in sorted(web.iterdir()):
    if path.is_file():
        data = path.read_bytes()
        gz = len(gzip.compress(data, mtime=0))
        raw += len(data)
        compressed += gz
        print(f'{path.name}: {len(data):,} bytes; gzip level 9: {gz:,} bytes')
print(f'PASS single-threaded bundle, {count} pack entries; {raw:,} raw bytes / {compressed:,} gzip bytes')

for name in ["cinder","tide","stone","gale","dawn","moon"]:
    assert any(p.endswith("data/weapons/"+name+".tres.remap") or p.endswith("data/weapons/"+name+".tres") for p in paths), name

units=json.loads((root/'game/tests/unit_asset_manifest.json').read_text())['units']
for u in units:
    uid=u['unit_id']
    for resource in [f'data/units/{uid}.tres',f'data/encounters/areas/{uid}.tres',f'assets/frames/units/{uid}_frames.tres']:
        assert any(p.endswith(resource) or p.endswith(resource+'.remap') for p in paths), resource
    assert any(uid+'_sheet.png-' in p and p.endswith('.ctex') for p in paths), uid
assert any(p.endswith('scripts/data/unit_spec.gdc') for p in paths)
print('PASS all 12 unit specs, encounters, SpriteFrames and imported atlases in release pack')
