# Elemental impact sheets

Four Aseprite-authored animations, each four 48×48 RGBA frames at 100ms in a
192×48 horizontal PNG. Transparent background, binary alpha, nearest sampling.
Tags: water, fire, earth, wind. Non-looping, 400ms runtime effect duration.
Primary opaque colors: WATER #328ee6, FIRE #ef493c, EARTH #a47746, WIND #ffffff.
Each primary color must exceed half the opaque pixels of every frame.
Silhouettes: curling surf/droplets, rising flame/embers, stone chunks/debris,
three wind arcs/streaks. Runtime scale 2×, defending fighter location.

Use generate.lua only through Aseprite Sprite/Image APIs. Export reproduction
to build/effect-repro, not over preserved art. Independent read-only verification
parses native compressed cels, PNG pixels/CRC, dimensions, distinct/nonempty
frames, JSON timing, runtime copies and all 20 pinned hashes. Runtime Godot tests
check SpriteFrames and imported pixel equality. See root CREDITS.md.
