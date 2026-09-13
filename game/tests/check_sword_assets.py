#!/usr/bin/env python3
"""Independent read-only native compressed-cel / PNG decoder; no raster authorship."""
import sys
sys.dont_write_bytecode=True
import hashlib,json,struct,zlib
from pathlib import Path
from check_moonlit_assets import png
root=Path(__file__).resolve().parents[2]
m=json.loads((root/'game/tests/sword_asset_manifest.json').read_text())
assert (m['native_size'],m['duration_ms'])==(48,100)
for path,digest in m['sha256'].items():
 assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,path
for name in ['water','fire','earth','wind']:
 base=root/'art_sources/weapons'
 native=base/f'{name}_sheet.png'
 assert native.read_bytes()==(root/f'game/assets/sprites/weapons/{name}_sheet.png').read_bytes()
 w,h,pixels=png(native)
 assert (w,h)==(192,48) and set(pixels[3::4])=={0,255}
 cells=[b''.join(pixels[(y*w+i*48)*4:(y*w+(i+1)*48)*4] for y in range(48)) for i in range(4)]
 assert len(set(cells))==4
 assert [hashlib.sha256(c).hexdigest() for c in cells]==m["swords"][name]["frame_sha256"]
 assert len(set(m["swords"][name]["frame_sha256"]))==4
 palette={bytes.fromhex(c)+b'\xff' for c in m['swords'][name]['palette']}
 for cell in cells:
  opaque=[cell[j:j+4] for j in range(0,len(cell),4) if cell[j+3]]
  assert len(opaque)>200 and set(opaque)==palette
 meta=json.loads((base/f'{name}.json').read_text())
 assert len(meta['frames'])==4
 assert [(t['name'],t['from'],t['to'],t['direction']) for t in meta['meta']['frameTags']]==[('sword',0,3,'forward')]
 for i,f in enumerate(meta['frames']):
  assert f['frame']=={'x':i*48,'y':0,'w':48,'h':48} and f['duration']==100 and not f['trimmed'] and not f['rotated']
 data=(base/f'{name}.aseprite').read_bytes()
 size,magic,count,aw,ah,depth=struct.unpack_from('<I5H',data)
 assert (size,magic,count,aw,ah,depth)==(len(data),0xA5E0,4,48,48,32)
 pos=128;native_tags=[]
 for i in range(count):
  frame_size,frame_magic,chunks,duration=struct.unpack_from('<I3H',data,pos)
  assert frame_magic==0xF1FA and duration==100
  cp=pos+16;cels=[]
  for _ in range(chunks):
   length,kind=struct.unpack_from('<IH',data,cp)
   if kind==0x2018:
    b=cp+6;nt=struct.unpack_from('<H',data,b)[0];tp=b+10
    for _ in range(nt):
     first,last,direction=struct.unpack_from('<HHB',data,tp)
     ln=struct.unpack_from('<H',data,tp+17)[0]
     native_tags.append((data[tp+19:tp+19+ln].decode(),first,last,direction))
     tp+=19+ln
   if kind==0x2005:
    layer,x,y,opacity,celtype=struct.unpack_from('<HhhBH',data,cp+6)
    assert (layer,x,y,opacity,celtype)==(0,0,0,255,2)
    assert struct.unpack_from('<HH',data,cp+22)==(48,48)
    cels.append(zlib.decompress(data[cp+26:cp+length]))
   cp+=length
  assert cp==pos+frame_size and cels==[cells[i]],(name,i,'native/source pixels differ')
  pos+=frame_size
 assert pos==len(data)
 assert native_tags==[("sword",0,3,0)]
 print(f'PASS {name}: source/export equality, four distinct poses, timing, alpha, palette, hashes')
# Require different silhouettes, not merely palette swaps.
masks=[]
for name in m['swords']:
 w,h,p=png(root/f'art_sources/weapons/{name}_sheet.png')
 mask=bytes(p[(y*w+x)*4+3] for y in range(48) for x in range(48))
 assert all(sum(a!=b for a,b in zip(mask,other))>60 for other in masks)
 masks.append(mask)
 rgb=[p[i:i+3] for i in range(0,len(p),4) if p[i+3]]
 avg=[sum(c[k] for c in rgb)/len(rgb) for k in range(3)]
 if name=='water': assert avg[2]>avg[0]*1.5
 if name=='fire': assert avg[0]>avg[1]*1.5 and avg[0]>avg[2]*2
 if name=='earth': assert avg[0]>avg[1]>avg[2] and avg[0]<180
 if name=='wind': assert min(avg)>145 and max(avg)-min(avg)<40
prior=(root/'game/tests/prior_sword_art.sha256').read_text().splitlines()
for line in prior:
 digest,path=line.split('  ',1)
 assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,path
print(f'PASS 4 swords, 16 distinct frames, 20 file hashes, 6 silhouette comparisons, {len(prior)} preserved art hashes')
