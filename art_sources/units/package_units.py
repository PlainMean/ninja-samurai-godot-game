#!/usr/bin/env python3
"""Package Aseprite exports and text resources. Never creates or alters raster pixels."""
import hashlib, json, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ROSTER=[
 ('cinder_rival','Cinder Rival','Fire duelist','ba453a','f5b65d','652934'),
 ('ash_monk','Ash Monk','Staff monk','b76b42','f8d28b','673b42'),
 ('ash_shogun','Ash Shogun','Helmed warlord','953c47','ffd077','422c49'),
 ('gate_guard','Gate Guard','Spear guardian','327ea4','9bdfef','254761'),
 ('twin_cut_retainer','Twin-cut Retainer','Dual blades','526cb1','b4d5ff','303758'),
 ('moonlit_master','Moonlit Master','Moon fan master','408e9c','dbf7f1','2c526e'),
 ('earth_sentinel','Earth Sentinel','Shield sentinel','8e7947','d9c48b','49482d'),
 ('iron_vanguard','Iron Vanguard','Hammer vanguard','777d79','ded2aa','434a4d'),
 ('mountain_regent','Mountain Regent','Stone axe regent','9d684a','f0c28c','543c38'),
 ('gale_assassin','Gale Assassin','Sickle assassin','76988b','e3f5cf','314b50'),
 ('coast_ronin','Coast Ronin','Straw-hat ronin','657f9e','f4ead0','363e60'),
 ('tempest_sovereign','Tempest Sovereign','Storm glaive lord','8977ad','ffffff','47405f')]
def main():
 manifest={'native_size':48,'duration_ms':100,'units':[],'sha256':{}}
 for i,(uid,name,role,*colors) in enumerate(ROSTER):
  source=ROOT/'art_sources/units'
  runtime=ROOT/f'game/assets/sprites/units/{uid}_sheet.png'
  shutil.copyfile(source/f'{uid}_sheet.png',runtime)
  frames=ROOT/f'game/assets/frames/units/{uid}_frames.tres'
  text='[gd_resource type="SpriteFrames" load_steps=6 format=3]\n'
  text+=f'[ext_resource type="Texture2D" path="res://assets/sprites/units/{uid}_sheet.png" id="1"]\n'
  for f in range(4):
   text+=f'[sub_resource type="AtlasTexture" id="F{f}"]\natlas = ExtResource("1")\nregion = Rect2({f*48}, 0, 48, 48)\nfilter_clip = true\n'
  animations=[]
  for tag,indices,loop in [('attack',[0,1,2,3],False),('idle',[0,3],True),('hurt',[1],False),('defeat',[3],False),('guard',[0],True)]:
   fs=', '.join('{"duration": 1.0, "texture": SubResource("F%d")}'%f for f in indices)
   animations.append('{"frames": ['+fs+'], "loop": '+str(loop).lower()+', "name": &"'+tag+'", "speed": 10.0}')
  frames.write_text(text+'[resource]\nanimations = [\n'+',\n'.join(animations)+'\n]\n')
  manifest['units'].append({'unit_id':uid,'display_name':name,'role':role,'element':i//3+1,'boss':i%3==2,'scale':3.0 if i%3==2 else 2.5,'palette':['171d30',*colors,'d8aa83','eef0da']})
  for p in [source/f'{uid}.aseprite',source/f'{uid}.json',source/f'{uid}_sheet.png',runtime,frames]:
   manifest['sha256'][str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
 (ROOT/'game/tests/unit_asset_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__': main()
