"""Package Aseprite output and text metadata only; never authors raster pixels."""
from pathlib import Path
import hashlib,json,shutil,sys
sys.dont_write_bytecode=True
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'game/tests'))
from check_moonlit_assets import png
palettes={'water':['122e57','225dba','359ceb','91e6ff','d5f8ff'],'fire':['501b2e','ad3026','ef5726','ffac38','ffe59a'],'earth':['302329','644331','99643e','c28b54','e3bf82'],'wind':['303949','737f96','bdcad8','e3ecf4','ffffff']}
m={'native_size':48,'duration_ms':100,'swords':{},'sha256':{}}
for name,palette in palettes.items():
 base=root/'art_sources/weapons'; dst=root/'game/assets/sprites/weapons';dst.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(base/f'{name}_sheet.png',dst/f'{name}_sheet.png')
 frames=root/f'game/assets/frames/weapons/{name}_frames.tres';frames.parent.mkdir(parents=True,exist_ok=True)
 text='[gd_resource type="SpriteFrames" load_steps=6 format=3]\n[ext_resource type="Texture2D" path="res://assets/sprites/weapons/'+name+'_sheet.png" id="1"]\n'
 for i in range(4): text+=f'[sub_resource type="AtlasTexture" id="F{i}"]\natlas = ExtResource("1")\nregion = Rect2({i*48}, 0, 48, 48)\nfilter_clip = true\n'
 text+='[resource]\nanimations = [{"frames": ['+', '.join('{"duration": 1.0, "texture": SubResource("F%d")}'%i for i in range(4))+'], "loop": true, "name": &"sword", "speed": 10.0}]\n'
 frames.write_text(text)
 w,h,p=png(base/f'{name}_sheet.png')
 m['swords'][name]={'palette':palette,'frame_sha256':[hashlib.sha256(b''.join(p[(y*w+i*48)*4:(y*w+(i+1)*48)*4] for y in range(48))).hexdigest() for i in range(4)]}
 for path in [base/f'{name}.aseprite',base/f'{name}.json',base/f'{name}_sheet.png',dst/f'{name}_sheet.png',frames]:m['sha256'][str(path.relative_to(root))]=hashlib.sha256(path.read_bytes()).hexdigest()
(root/'game/tests/sword_asset_manifest.json').write_text(json.dumps(m,indent=2)+'\n')

# Copy the Aseprite-derived body sheets; preserve the original atlas/timing definitions.
import re
body_hashes={}
for name,original in [('attack','game/assets/frames/ninja_frames.tres'),('support','game/assets/frames/moonlit_dojo/ninja_support_frames.tres')]:
 source=root/f'art_sources/weapons/player_{name}_sheet.png'
 if not source.exists(): continue
 runtime=root/f'game/assets/sprites/weapons/player_{name}_sheet.png'
 shutil.copyfile(source,runtime)
 frames=root/f'game/assets/frames/weapons/player_{name}_frames.tres'
 text=re.sub(r'path="res://assets/sprites/[^\"]+"',f'path="res://assets/sprites/weapons/player_{name}_sheet.png"',(root/original).read_text())
 frames.write_text(text)
 for path in [source,runtime,frames,root/f'art_sources/weapons/player_{name}.aseprite',root/f'art_sources/weapons/player_{name}.json']:
  body_hashes[str(path.relative_to(root))]=hashlib.sha256(path.read_bytes()).hexdigest()
(root/'game/tests/player_sword_body_manifest.json').write_text(json.dumps(body_hashes,indent=2)+'\n')
