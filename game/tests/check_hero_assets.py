#!/usr/bin/env python3
"""Independent read-only native compressed-cel / PNG decoder; no raster authorship."""
import sys
sys.dont_write_bytecode=True
import hashlib,json,struct,zlib
from pathlib import Path
from check_moonlit_assets import png
root=Path(__file__).resolve().parents[2]
m=json.loads((root/'game/tests/hero_asset_manifest.json').read_text())
assert (m['native_size'],m['duration_ms'])==(48,100)
for path,digest in m['sha256'].items():
 assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,path
for name in ['kira']:
 base=root/'art_sources/heroes'
 native=base/f'{name}_sheet.png'
 assert native.read_bytes()==(root/f'game/assets/sprites/heroes/{name}_sheet.png').read_bytes()
 w,h,pixels=png(native)
 assert (w,h)==(192,48) and set(pixels[3::4])=={0,255}
 cells=[b''.join(pixels[(y*w+i*48)*4:(y*w+(i+1)*48)*4] for y in range(48)) for i in range(4)]
 assert len(set(cells))==4
 assert [hashlib.sha256(c).hexdigest() for c in cells]==m["frame_sha256"]
 assert len(set(m["frame_sha256"]))==4
 palette={bytes.fromhex(c)+b'\xff' for c in m['palette']}
 for cell in cells:
  opaque=[cell[j:j+4] for j in range(0,len(cell),4) if cell[j+3]]
  assert len(opaque)>200 and set(opaque)==palette
 for old in (root/'art_sources/units').glob('*_sheet.png'):
  ow,oh,op=png(old)
  for i in range(4):
   other=b''.join(op[(y*ow+i*48)*4:(y*ow+(i+1)*48)*4] for y in range(48))
   assert other not in cells
   assert all(sum(a!=b for a,b in zip(cell[3::4],other[3::4]))>100 for cell in cells)
 meta=json.loads((base/f'{name}.json').read_text())
 assert len(meta['frames'])==4
 assert [(t['name'],t['from'],t['to'],t['direction']) for t in meta['meta']['frameTags']]==[('support',0,3,'forward')]
 for i,f in enumerate(meta['frames']):
  assert f['frame']=={'x':i*48,'y':0,'w':48,'h':48} and f['duration']==100 and not f['trimmed'] and not f['rotated']
 data=(base/f'{name}.aseprite').read_bytes()
 size,magic,count,aw,ah,depth=struct.unpack_from('<I5H',data)
 assert (size,magic,count,aw,ah,depth)==(len(data),0xA5E0,4,48,48,32)
 pos=128
 for i in range(count):
  frame_size,frame_magic,chunks,duration=struct.unpack_from('<I3H',data,pos)
  assert frame_magic==0xF1FA and duration==100
  cp=pos+16;cels=[]
  for _ in range(chunks):
   length,kind=struct.unpack_from('<IH',data,cp)
   if kind==0x2005:
    layer,x,y,opacity,celtype=struct.unpack_from('<HhhBH',data,cp+6)
    assert (layer,x,y,opacity,celtype)==(0,0,0,255,2)
    assert struct.unpack_from('<HH',data,cp+22)==(48,48)
    cels.append(zlib.decompress(data[cp+26:cp+length]))
   cp+=length
  assert cp==pos+frame_size and cels==[cells[i]],(name,i,'native/source pixels differ')
  pos+=frame_size
 assert pos==len(data)
 print(f'PASS {name}: source/export equality, four distinct poses, timing, alpha, palette, hashes')
print('PASS Kira: 4 frame hashes, 6 file hashes, 192 prior-enemy silhouette comparisons')
