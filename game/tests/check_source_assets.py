#!/usr/bin/env python3
"""Read-only metadata/checksum verification. Does not render or modify artwork."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--originals', action='store_true', help='Also compare every original absolute path')
args = parser.parse_args()
manifest = json.loads((ROOT / 'game/tests/asset_manifest.json').read_text())
for row in manifest['files']:
    data = (ROOT / row['path']).read_bytes()
    assert len(data) == row['bytes'], row['path']
    assert hashlib.sha256(data).hexdigest() == row['sha256'], row['path']
    if args.originals:
        assert data == Path(row['original']).read_bytes(), row['original']
for who in ('ninja', 'samurai'):
    png = (ROOT / f'game/assets/sprites/{who}_attack_sheet.png').read_bytes()
    assert png[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack_from('>II', png, 16) == (192, 32)
    assert png[24:26] == bytes((8, 6)), 'Expected 8-bit RGBA'
    data = (ROOT / f'art_sources/{who}/{who}_attack.aseprite').read_bytes()
    size, magic, count, width, height, depth = struct.unpack_from('<I5H', data)
    assert (size, magic, count, width, height, depth) == (len(data), 0xA5E0, 6, 32, 32, 32)
    offset, layers, tags = 128, [], []
    for frame in range(count):
        length, frame_magic, old_chunks, ms = struct.unpack_from('<I3H', data, offset)
        assert frame_magic == 0xF1FA and ms == 100
        chunks = struct.unpack_from('<I', data, offset + 12)[0] or old_chunks
        pos = offset + 16
        for _ in range(chunks):
            chunk_size, kind = struct.unpack_from('<IH', data, pos)
            body = pos + 6
            if kind == 0x2004:
                name_len = struct.unpack_from('<H', data, body + 16)[0]
                layers.append(data[body + 18:body + 18 + name_len].decode())
            elif kind == 0x2018:
                tag_count = struct.unpack_from('<H', data, body)[0]
                tag_pos = body + 10
                for _ in range(tag_count):
                    first, last, direction = struct.unpack_from('<HHB', data, tag_pos)
                    name_len = struct.unpack_from('<H', data, tag_pos + 17)[0]
                    name = data[tag_pos + 19:tag_pos + 19 + name_len].decode()
                    tags.append((first, last, direction, name))
                    tag_pos += 19 + name_len
            pos += chunk_size
        assert pos == offset + length
        offset += length
    assert offset == len(data)
    assert (0, 5, 0, 'attack') in tags, tags
    expected = ['Scarf', 'Ninja', 'Steel blade', 'Slash accents'] if who == 'ninja' else ['01 • Indigo armor & sash', '02 • Arms & steel katana', '03 • Cut accent']
    assert sorted(layers) == sorted(expected), layers
    print(f'PASS {who}: 192x32 RGBA sheet, six 32x32 RGBA frames at 100 ms, forward attack tag, layers')
print(f"PASS {len(manifest['files'])} checksums" + (' and byte-identical originals' if args.originals else ''))
