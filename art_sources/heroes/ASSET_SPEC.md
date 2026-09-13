# Kira the Tideblade

Original ally art: copper looped braid, asymmetric teal tabard, ivory split greaves,
exposed arm and a long open crescent poleblade. Seven opaque palette colors plus
transparent background; neither the ninja nor any enemy is used as a raster base.

- Native cells: 48×48 RGBA; sheet 192×48; four distinct ready/wind-up/extension/recovery poses.
- Tag: `support`, frames 0–3, forward, 100ms each; runtime 10 FPS.
- Source: `kira.aseprite`; metadata: `kira.json`; Aseprite export: `kira_sheet.png`.
- Runtime: `game/assets/sprites/heroes/kira_sheet.png`, lossless/no mipmaps; nearest rendering.
- Resource: `game/assets/frames/heroes/kira_frames.tres`; identity: `game/data/heroes/kira.tres`.
- Palette: `16283e` outline, `246e78` cloth, `51c9bd` water/trim, `e5f4d6` ivory,
  `dcaa87` skin, `ba7b51` copper braid/haft, `34475c` boots.

Use `generate.lua` with `~/.local/bin/aseprite -b`; every pixel and export is produced
by Aseprite Sprite/Image APIs. Set XDG_CONFIG_HOME to a writable local directory.
`verify.lua` reopens the source without saving and compares its pixels to the sheet.
`game/tests/check_hero_assets.py` independently decodes PNG and compressed source
cels, checks four frame hashes, six file hashes, full palette, binary alpha, tags,
durations, and 192 color-independent silhouette comparisons against old enemies.
`game/tests/prior_hero_art.sha256` preserves all 110 prior tracked art/frame files.

The strip was inspected visually; no native game capture was possible in this
session (X11 and Wayland unavailable). The reproducibility export is kept in
`build/hero-repro/` and its PNG matches the committed-source candidate byte for byte.
