#!/usr/bin/env python3
"""Read-only source layer decoder: verify retained cels and exported body pixels."""
import struct,zlib,hashlib,json,sys
sys.dont_write_bytecode=True
from pathlib import Path
from check_moonlit_assets import png
root=Path(__file__).resolve().parents[2]
def decode(path):
 d=path.read_bytes();size,magic,n,w,h,depth=struct.unpack_from('<I5H',d)
 assert (size,magic,w,h,depth)==(len(d),0xA5E0,32,32,32)
 pos=128;layers=[];frames=[];tags=[]
 for f in range(n):
  length,magic,chunks,ms=struct.unpack_from('<I3H',d,pos);assert magic==0xF1FA
  cp=pos+16;cels={}
  for _ in range(chunks):
   length2,kind=struct.unpack_from('<IH',d,cp);b=cp+6
   if kind==0x2004:
    flags=struct.unpack_from('<H',d,b)[0];ln=struct.unpack_from('<H',d,b+16)[0]
    layers.append((d[b+18:b+18+ln].decode(),flags&1))
   elif kind==0x2018: tags.append(d[b:cp+length2])
   elif kind==0x2005:
    layer,x,y,opacity,typ=struct.unpack_from('<HhhBH',d,b)
    assert opacity==255
    if typ==1:
     linked=struct.unpack_from('<H',d,b+16)[0];cels[layer]=frames[linked][1][layer]
    else:
     assert typ==2
     cw,ch=struct.unpack_from('<HH',d,b+16)
     raw=zlib.decompress(d[b+20:cp+length2]);assert len(raw)==cw*ch*4
     cels[layer]=(x,y,cw,ch,raw)
   cp+=length2
  assert cp==pos+length
  frames.append((ms,cels));pos+=length
 assert pos==len(d)
 return layers,frames,tags
for name,original,hidden in [('attack','ninja/ninja_attack',{'Steel blade','Slash accents'}),('support','moonlit_dojo/ninja_support',{'Blade'})]:
 old=decode(root/f'art_sources/{original}.aseprite')
 new=decode(root/f'art_sources/weapons/player_{name}.aseprite')
 assert old[1:]==new[1:], 'all original cel pixels, tags and timing retained'
 assert [n for n,v in old[0]]==[n for n,v in new[0]]
 assert all(v==(0 if n in hidden else 1) for n,v in new[0])
 sheet=root/f'art_sources/weapons/player_{name}_sheet.png'
 assert sheet.read_bytes()==(root/f'game/assets/sprites/weapons/player_{name}_sheet.png').read_bytes()
 w,h,rgba=png(sheet);assert (w,h)==(len(new[1])*32,32)
 # Compare read-only expected compositing to PNG. No image is written/generated here.
 for f,(ms,cels) in enumerate(new[1]):
  for y in range(32):
   for x in range(32):
    expected=b'\0'*4
    for layer,(_,visible) in enumerate(new[0]):
     if not visible or layer not in cels:continue
     cx,cy,cw,ch,raw=cels[layer]
     if cx<=x<cx+cw and cy<=y<cy+ch:
      off=((y-cy)*cw+x-cx)*4;p=raw[off:off+4]
      assert p[3] in (0,255)
      if p[3]:expected=p
    off=(y*w+f*32+x)*4
    assert rgba[off:off+4]==expected,(name,f,x,y)
 print(f'PASS player {name}: {len(new[1])} original cel sets/timings/tags, hidden steel, pixel-exact exported body')
m=json.loads((root/'game/tests/player_sword_body_manifest.json').read_text())
for p,h in m.items():assert hashlib.sha256((root/p).read_bytes()).hexdigest()==h,p
print(f'PASS {len(m)} derived player file hashes')
