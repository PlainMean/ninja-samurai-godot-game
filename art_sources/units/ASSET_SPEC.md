# Twelve area units

All raster pixels are authored by `generate.lua` through Aseprite Sprite/Image
APIs, using individually drawn geometry for each identity. Native RGBA: 48×48;
four nonempty, distinct frames; 100ms each; forward `attack` tag; transparent
background with binary alpha. Sheets are horizontal 192×48, untrimmed. Facing
right in source, mirrored for enemies. No prior asset is overwritten.

`game/tests/unit_asset_manifest.json` records the ordered roster, roles, affinities,
boss status, six-color unit palettes, scale, and 60 immutable SHA-256 values.
Palette entries: shared dark outline, unique primary, highlight, shadow, skin,
blade. No two units share an alpha silhouette in any attack pose; the independent
verifier also requires >100 differing pixels between every pair of ready masks.
Boss signatures: Ash Shogun's horned heavy helm and tassets; Moonlit Master's
circular halo and fan robe; Mountain Regent's jagged crown and slab axe;
Tempest Sovereign's wing mantle and forked glaive.

Runtime SpriteFrames: attack uses all four 100ms poses; idle loops poses 0/3,
guard holds 0, hurt holds 1, defeat holds 3. These support tags are pose reuse,
not separately authored animations. Nearest filtering lives on FighterView's
AnimatedSprite2D. Guard scale 2.5, boss scale 3.0; feet at native row 44.

From repository root (use a fresh output directory to reproduce):

```bash
XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/aseprite -b \
  --script-param out="$PWD/build/unit-repro" --script art_sources/units/generate.lua
XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/aseprite -b \
  --script-param src="$PWD/art_sources/units" --script art_sources/units/verify.lua
python3 game/tests/check_unit_assets.py
sha256sum -c game/tests/prior_unit_art.sha256
bash game/tests/verify.sh
```

`package_units.py` only copies Aseprite PNGs and writes text SpriteFrames/manifest;
it never constructs, edits or encodes raster pixels. Run it only after an intended
new art revision, then independently review the hash changes. Existing artwork
is protected by `prior_unit_art.sha256`, captured at HEAD 9b6b1b7.
