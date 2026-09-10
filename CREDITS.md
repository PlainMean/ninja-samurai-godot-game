# Credits and provenance

Ninja and samurai artwork was supplied with this project. The supplied files do not identify a separate artist or include an artwork license; this document records provenance and does not assign a new license to the art.

| Fighter | Original repository | Runtime copy | Editable archive |
| --- | --- | --- | --- |
| Ninja | `/home/cmuxao/projects/hermes_area/aseprite-ninja-attack` | `game/assets/sprites/ninja_attack_sheet.png` | `art_sources/ninja/ninja_attack.aseprite` |
| Samurai | `/home/cmuxao/projects/hermes_area/aseprite-samurai-attack` | `game/assets/sprites/samurai_attack_sheet.png` | `art_sources/samurai/samurai_attack.aseprite` |

Both runtime sheets are byte-identical 192×32 RGBA PNGs: six native 32×32 frames, 100 ms each. The samurai is flipped only at runtime. No artwork was regenerated or resized. The existing archive also preserves each specification, Lua generator, Lua verifier, recorded verification report, GIF, and enlarged preview. Only the two native sheets enter the game pack.

The complete original paths, file sizes, and SHA-256 hashes are in [asset_manifest.json](game/tests/asset_manifest.json) and [source_assets.sha256](game/tests/source_assets.sha256). Both original repositories were read only. The Lua generators and verifiers were not executed.

Godot Engine 4.5.1 Standard provides the engine, default font, and UI primitives. The custom HTML shell is adapted from `godot.html` inside the matching `web_nothreads_release.zip`. Godot is distributed under the MIT license; its engine and bundled component notices, including font notices, are preserved in [THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt), extracted from the installed engine's own license APIs. The verification script includes both notices files beside the exported game.
