#!/usr/bin/env python3
"""Read-only independent Aseprite/PNG/JSON verifier. Never authors raster pixels."""
import sys
sys.dont_write_bytecode = True
import hashlib, json, struct, zlib
from pathlib import Path
from check_moonlit_assets import png
root=Path(__file__).resolve().parents[2]
names=['water','fire','earth','wind']
colors={'water':(50,142,230,255),'fire':(239,73,60,255),'earth':(164,119,70,255),'wind':(255,255,255,255)}
manifest=json.loads((root/'game/tests/element_asset_manifest.json').read_text())
assert len(manifest['sha256'])==20
for path,digest in manifest['sha256'].items():
    assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,path
for name in names:
    base=root/'art_sources/elements'
    native=base/f'{name}_sheet.png'
    assert native.read_bytes()==(root/f'game/assets/sprites/elements/{name}_sheet.png').read_bytes()
    w,h,pixels=png(native)
    assert (w,h)==(192,48) and set(pixels[3::4])=={0,255}
    cells=[b''.join(pixels[(y*w+i*48)*4:(y*w+(i+1)*48)*4] for y in range(48)) for i in range(4)]
    assert len(set(cells))==4
    for cell in cells:
        opaque=[tuple(cell[j:j+4]) for j in range(0,len(cell),4) if cell[j+3]]
        assert len(opaque)>100 and opaque.count(colors[name]) > len(opaque)/2,(name,'primary color must dominate')
    meta=json.loads((base/f'{name}.json').read_text())
    assert len(meta['frames'])==4
    assert [(t['name'],t['from'],t['to']) for t in meta['meta']['frameTags']]==[(name,0,3)]
    for i,f in enumerate(meta['frames']):
        assert f['frame']=={'x':i*48,'y':0,'w':48,'h':48} and f['duration']==100 and not f['trimmed'] and not f['rotated']
    # Independently parse native .aseprite header and compressed cel chunks.
    data=(base/f'{name}.aseprite').read_bytes()
    size,magic,count,aw,ah,depth=struct.unpack_from('<I5H',data)
    assert (size,magic,count,aw,ah,depth)==(len(data),0xA5E0,4,48,48,32)
    pos=128
    for i in range(count):
        frame_size,frame_magic,chunks,duration=struct.unpack_from('<I3H',data,pos)
        assert frame_magic==0xF1FA and duration==100
        cp=pos+16; cels=[]
        for _ in range(chunks):
            length,kind=struct.unpack_from('<IH',data,cp)
            if kind==0x2005:
                layer,x,y,opacity,celtype=struct.unpack_from('<HhhBH',data,cp+6)
                assert (layer,x,y,opacity,celtype)==(0,0,0,255,2)
                cw,ch=struct.unpack_from('<HH',data,cp+22)
                assert (cw,ch)==(48,48)
                cels.append(zlib.decompress(data[cp+26:cp+length]))
            cp+=length
        assert cp==pos+frame_size and cels==[cells[i]],(name,i,'native/source pixels differ')
        pos+=frame_size
    assert pos==len(data)
    print(f'PASS {name}: native cel/PNG pixel equality, 4 distinct nonempty 48x48/100ms frames, exact dominant color, hashes')
print('PASS four effects / 16 frames / 20 immutable hashes')
