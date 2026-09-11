# Moonlit Dojo: Three Seals

A portrait turn-based touch game built with Godot 4.5.1 Standard. Choose **FIRE**, **WATER**, **EARTH**, or **WIND**, then watch the samurai's automatic WATER turn. **WIND is effective against WATER.** Carry health through three encounters and choose a reward after each of the first two victories.

```bash
game/tests/verify.sh
~/.local/bin/godot --path game
```

The verification wrapper checks preserved artwork, six existing Aseprite asset sets, deterministic mechanics, full-run touch flows, lifecycle/layout, imports, scene smoke, HTML5 export, and an actual exported-pack three-encounter clear. The complete local artifact is `build/web/`.

See [game setup and architecture](game/README.md), [actual verification and pending browser/device QA](qa/mobile/elemental/validation.md), and [artwork provenance](CREDITS.md). Both implementation plans remain in `.hermes/plans/`. This elemental revision is local only; no push or deployment was performed.
