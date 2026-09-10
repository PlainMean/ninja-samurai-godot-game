# Ninja vs Samurai — Block & Counter

A one-screen, touch-only portrait duel built with Godot 4.5.1 Standard and GDScript. Block the warning, then Strike during the opening. Three counters win; three missed blocks lose. Includes Start, Pause/Resume, and Retry; no audio or keyboard dependency.

From this repository:

```bash
game/tests/verify.sh
~/.local/bin/godot --path game
```

The verification script imports, runs 309 headless checks, smoke-tests the scene, exports `build/web/index.html`, and smoke-tests the exported pack. See [game/README.md](game/README.md) for exact setup, individual commands, controls, architecture, and local HTTP instructions; [qa/mobile/validation.md](qa/mobile/validation.md) records actual results and remaining browser/device coverage. See [CREDITS.md](CREDITS.md) for artwork provenance.
