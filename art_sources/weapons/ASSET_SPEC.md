# Elemental swords

Aseprite 1.3.18.3-dev; authored exclusively with Sprite/Image Lua APIs through
`~/.local/bin/aseprite`. Four RGBA sheets, each 192×48, four 48×48 cells, forward
`sword` tag, 100 ms each, looping specular glint. Grip (24,39), blade points up.
Nearest rendering; no mipmaps. Runtime fighter scale 0.4 inside the 4× ninja
visual, following the original per-pose hand and blade-tip direction.

| Asset | Shape | Palette (dark → light) | Weapons |
|---|---|---|---|
| water | Open tideglass crescent | 122e57 225dba 359ceb 91e6ff d5f8ff | Tideglass, Moonwake |
| fire | Branched cinder flame | 501b2e ad3026 ef5726 ffac38 ffe59a | Cinder Fang, Dawnbrand |
| earth | Broad faceted ore blade | 302329 644331 99643e c28b54 e3bf82 | Stone Oath |
| wind | Narrow barbed feather | 303949 737f96 bdcad8 e3ecf4 ffffff | Gale Feather |

`generate.lua` authors the swords; `derive_player.lua` saves copies of the two
original ninja documents with Steel blade/Slash accents or Blade hidden. All
original body cels, tags and timing remain; old sources/runtime art stay unchanged.
`package.py` only copies exported PNGs and writes text resources/manifests.

Reproduce without overwriting committed assets:

```sh
bash art_sources/weapons/reproduce.sh
```

To author/package after an intentional asset edit:

```sh
export XDG_CONFIG_HOME="$PWD/build/local/config"
~/.local/bin/aseprite -b --script-param out="$PWD/art_sources/weapons" --script art_sources/weapons/generate.lua
~/.local/bin/aseprite -b --script-param root="$PWD" --script-param out="$PWD/art_sources/weapons" --script art_sources/weapons/derive_player.lua
python3 art_sources/weapons/package.py
```

`verify.lua` reopens sources natively. Independent read-only verifiers decode
compressed cels, compare PNG pixels, native/JSON tags and timing, palettes,
dominant color, unique silhouettes, alpha, hashes, body layers and prior art.
`preview.lua` creates the Aseprite-only contact sheet, ordered WATER/FIRE/EARTH/WIND.
