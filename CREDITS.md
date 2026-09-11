# Credits and provenance

Ninja and samurai artwork was supplied with this project. The supplied files do not identify a separate artist or include an artwork license; this document records provenance and does not assign a new license to the art.

| Fighter | Original repository | Runtime copy | Editable archive |
| --- | --- | --- | --- |
| Ninja | `/home/cmuxao/projects/hermes_area/aseprite-ninja-attack` | `game/assets/sprites/ninja_attack_sheet.png` | `art_sources/ninja/ninja_attack.aseprite` |
| Samurai | `/home/cmuxao/projects/hermes_area/aseprite-samurai-attack` | `game/assets/sprites/samurai_attack_sheet.png` | `art_sources/samurai/samurai_attack.aseprite` |

Both runtime sheets are byte-identical 192×32 RGBA PNGs: six native 32×32 frames, 100 ms each. The samurai is flipped only at runtime. No supplied artwork was regenerated or resized. The existing archive also preserves each specification, Lua generator, Lua verifier, recorded verification report, GIF, and enlarged preview. Only the two native attack sheets from these original archives enter the game pack.

The complete original paths, file sizes, and SHA-256 hashes are in [asset_manifest.json](game/tests/asset_manifest.json) and [source_assets.sha256](game/tests/source_assets.sha256). Both original repositories were read only. The original Lua generators and verifiers were not executed.

Godot Engine 4.5.1 Standard provides the engine, default font, and UI primitives. The custom HTML shell is adapted from `godot.html` inside the matching `web_nothreads_release.zip`. Godot is distributed under the MIT license; its engine and bundled component notices, including font notices, are preserved in [THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt), extracted from the installed engine's own license APIs. The verification script includes both notices files beside the exported game.

## Moonlit Dojo expansion — 2026-09-11

Six additional layered assets were authored locally by Codex using **Aseprite 1.3.18.3-dev Sprite/Image Lua APIs**: `ninja_support`, `samurai_support`, `dojo_backdrops`, `dojo_props`, `combat_fx`, and `dojo_icons`. Their 51 frames, native PNG strips, JSON metadata, reproducible generator, specification, and independent source-to-sheet verifier are archived in [art_sources/moonlit_dojo](art_sources/moonlit_dojo/). Support drawing routines adapt the supplied generators to preserve fighter proportions and palettes; the supplied files themselves remain byte-identical. This provenance does not invent a license grant for supplied or derived artwork.

Only the six new native PNG strips and generated SpriteFrames resources ship alongside the original attack sheets. No diffusion, Python/Pillow, ImageMagick, SVG, browser, or Godot raster authoring was used. New manifests are separate: [moonlit_asset_manifest.json](game/tests/moonlit_asset_manifest.json) and [moonlit_assets.sha256](game/tests/moonlit_assets.sha256).

## Journey illustrations (2026-09-11)
Original route gates, renewal shrine and moonlit archive reveal by this project's
Codex-assisted authoring session. Three 160×96 illustrations, each with three
300ms support frames, authored/exported exclusively using Aseprite Sprite/Image
APIs through `~/.local/bin/aseprite`. Editable sources, JSON and reproducible Lua:
`art_sources/journey/`; byte-identical runtime sheets:
`game/assets/sprites/journey/`. Hashes: `game/tests/journey_asset_manifest.json`.
All previously credited art and its manifests remain unchanged.

## Eight Seals elemental effects — 2026-09-12
Four original impact animations (`water`, `fire`, `earth`, `wind`) authored by
this Codex-assisted project session exclusively through **Aseprite
1.3.18.3-dev Sprite/Image Lua APIs**, using `~/.local/bin/aseprite`. Blue curling
surf, red rising flame, brown shattered stone and white air arcs each contain
four distinct 48×48 frames at 100ms. No supplied pixels were changed or copied
into these effects. Editable sources, JSON, native PNGs and reproducible Lua:
`art_sources/elements/`. Byte-identical runtime strips and SpriteFrames:
`game/assets/sprites/elements/`, `game/assets/frames/elements/`.
Independent binary source/PNG/palette verification and 20 hashes:
`game/tests/check_element_assets.py`, `game/tests/element_asset_manifest.json`.
Python is used only for read-only verification and textual metadata; no Pillow,
ImageMagick, SVG, browser canvas, diffusion or Godot raster authoring was used.
All eight guardians use the previously credited samurai art; no new character
sprite provenance or license grant is implied.
