#!/usr/bin/env python3
"""Read-only metadata, native PNG decoding, preservation and budget checks. No art writes."""
import hashlib
import json
import struct
import zlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
NAMES = ('ninja_support', 'samurai_support', 'dojo_backdrops', 'dojo_props', 'combat_fx', 'dojo_icons')
SPECS = {
 'ninja_support': (32,32,[('idle',[400,400]),('guard',[100,100]),('dodge',[100]*3),('hurt',[100]*2),('defeat',[100,100,200])],['Scarf','Body','Blade']),
 'samurai_support': (32,32,[('idle',[400,400]),('warn_cut',[100]),('warn_heavy',[100]),('hurt',[100]*2),('defeat',[100,100,200])],['Armor','Arms and blade','Cloth']),
 'dojo_backdrops': (195,128,[(n,[100]) for n in ('gate','courtyard','dojo')],['Sky or wall','Architecture','Floor']),
 'dojo_props': (16,32,[('lantern',[300,300])]+[(n,[100]) for n in ('banner_gate','banner_retainer','banner_master')],['Fixture','Light or emblem']),
 'combat_fx': (32,32,[('block',[60,60,100]),('dodge',[80]*3),('hit',[60,60,100]),('seal',[100,100,200])],['Core','Accents']),
 'dojo_icons': (16,16,[(n,[100]) for n in ('heart_full','heart_empty','seal_empty','seal_full','cut','heavy','double_cut','mend','long_breath','iron_resolve')],['Outline','Fill'])}

def png(path):
    data=path.read_bytes(); assert data[:8]==b'\x89PNG\r\n\x1a\n'
    pos=8; compressed=b''
    while pos<len(data):
        size=struct.unpack_from('>I',data,pos)[0]; tag=data[pos+4:pos+8]; block=data[pos+8:pos+8+size]
        assert zlib.crc32(tag+block)&0xffffffff==struct.unpack_from('>I',data,pos+8+size)[0]
        if tag==b'IHDR':
            w,h,depth,color,compression,filtering,interlace=struct.unpack('>IIBBBBB',block)
            assert (depth,color,compression,filtering,interlace)==(8,6,0,0,0)
        if tag==b'IDAT': compressed+=block
        pos+=size+12
    raw=zlib.decompress(compressed); stride=w*4; prior=bytearray(stride); pixels=bytearray(); pos=0
    for _ in range(h):
        kind=raw[pos]; row=bytearray(raw[pos+1:pos+1+stride]); pos+=stride+1
        for x in range(stride):
            a=row[x-4] if x>=4 else 0; b=prior[x]; c=prior[x-4] if x>=4 else 0
            if kind==1: value=a
            elif kind==2: value=b
            elif kind==3: value=(a+b)//2
            elif kind==4:
                p=a+b-c; distances=[abs(p-a),abs(p-b),abs(p-c)]; value=[a,b,c][distances.index(min(distances))]
            else: assert kind==0; value=0
            row[x]=(row[x]+value)&255
        pixels.extend(row); prior=row
    assert pos==len(raw)
    return w,h,bytes(pixels)

def main():
    archive=ROOT/'art_sources/moonlit_dojo'
    assert {p.stem for p in archive.glob('*.aseprite')}==set(NAMES)
    manifest=json.loads((ROOT/'game/tests/moonlit_asset_manifest.json').read_text())
    for path,digest in manifest['sha256'].items(): assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
    resident=added=total=0
    for name,(w,h,tags,layers) in SPECS.items():
        metadata=json.loads((archive/f'{name}.json').read_text()); count=sum(len(ms) for _,ms in tags)
        assert len(metadata['frames'])==count
        assert [l['name'] for l in metadata['meta']['layers']]==layers
        offset=0
        for (tag,durations),actual in zip(tags,metadata['meta']['frameTags'],strict=True):
            assert (actual['name'],actual['from'],actual['to'],actual['direction'])==(tag,offset,offset+len(durations)-1,'forward')
            for ms in durations:
                frame=metadata['frames'][offset]
                assert frame['frame']=={'x':offset*w,'y':0,'w':w,'h':h}
                assert frame['duration']==ms and not frame['rotated'] and not frame['trimmed']
                offset+=1
        native=archive/f'{name}_sheet.png'; runtime=ROOT/f'game/assets/sprites/moonlit_dojo/{name}_sheet.png'
        assert native.read_bytes()==runtime.read_bytes()
        width,height,pixels=png(native); assert (width,height)==(w*count,h)
        assert set(pixels[3::4]) <= {0,255}
        if name=='dojo_backdrops': assert set(pixels[3::4])=={255}
        frames=[]
        for i in range(count):
            cell=b''.join(pixels[(y*width+i*w)*4:(y*width+(i+1)*w)*4] for y in range(h))
            frames.append(cell)
            if name.endswith('_support'):
                assert any(cell[(29*w)*4+3:30*w*4:4]) and not any(cell[30*w*4+3::4])
        assert len(set(frames))==count
        repro=ROOT/f'build/art-repro/{name}_sheet.png'
        if repro.exists():
            assert png(repro)==(width,height,pixels)
            rmeta=json.loads(repro.with_name(f'{name}.json').read_text())
            assert rmeta['frames']==metadata['frames'] and rmeta['meta']['frameTags']==metadata['meta']['frameTags']
        resident+=len(pixels); added+=native.stat().st_size; total+=count
        print(f'PASS {name}: {count} frames, source/runtime bytes, decoded RGBA, exact metadata')
    assert total==51 and added<=256*1024 and resident+2*192*32*4<=1024*1024
    print(f'PASS six sets / {total} frames; {added} added PNG bytes; {resident+2*192*32*4} resident atlas RGBA bytes; {len(manifest["sha256"])} hashes')
if __name__=='__main__': main()
