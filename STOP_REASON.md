# Distinct units complete — 2026-09-12

Implemented twelve distinct animated enemy unit sets from clean HEAD `9b6b1b7`
in three bounded, fully gated passes. Every area node references a unique
UnitSpec and SpriteFrames; all four bosses have distinct silhouettes, larger
scale and BOSS markers. Names/roles appear on map, HUD, intro and loot.

Every raster was authored/exported through Aseprite Sprite/Image APIs. Editable
sources, JSON metadata, native/runtime PNGs and SpriteFrames are retained in the
new units directories. All 91 prior tracked art files are byte-preserved.
Attack has four 100ms poses per unit; support tags reuse those poses. Combat,
weapons, exact elemental cycle/colors, RNG, rewards and full-clear rules remain.

Final targeted and full `game/tests/verify.sh`: **20,286 checks, zero failures**.
Independent checks passed 48 source/export frame matches, 60 hashes, 66 silhouette
pairs and twelve reproducible PNGs. Web export and actual exported legacy/area
full clears passed. PCK: 195,756 bytes / 237 entries. `git diff --check` passed.
Artifact: `build/web/index.html` and siblings. No push/deployment.

All twelve sprite strips were inspected. Native 390×844 capture was blocked by
unavailable X11/Wayland and Xvfb socket permissions; no game screenshot captured.
Browser WebGL/HTTP and physical device visual/touch/performance acceptance remain.

A local commit was attempted and blocked by read-only `.git/index.lock` (128).
HEAD remains `9b6b1b7`; verified changes are left unstaged for the parent workspace.

[Plan](.hermes/plans/2026-09-12_210613-distinct-units.md) ·
[QA and exact roster](qa/mobile/distinct-units/2026-09-12-validation.md) ·
[Art specification](art_sources/units/ASSET_SPEC.md).
