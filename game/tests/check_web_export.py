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
assert not any('/tests/' in p or '/web/' in p or 'art_sources/' in p for p in paths)
raw = compressed = 0
for path in sorted(web.iterdir()):
    if path.is_file():
        data = path.read_bytes()
        gz = len(gzip.compress(data, mtime=0))
        raw += len(data)
        compressed += gz
        print(f'{path.name}: {len(data):,} bytes; gzip level 9: {gz:,} bytes')
print(f'PASS single-threaded bundle, {count} pack entries; {raw:,} raw bytes / {compressed:,} gzip bytes')
