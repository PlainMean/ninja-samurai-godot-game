# Moonlit Dojo: Three Seals

A portrait touch game built with Godot 4.5.1 Standard. Challenge three guardians: **Block CUT**, **Dodge HEAVY**, then **Strike when OPEN**. Double cuts require two fresh blocks. Carry your health through the dojo and choose a technique after each of the first two victories.

```bash
game/tests/verify.sh
~/.local/bin/godot --path game
```

The verification wrapper checks preserved artwork, six new Aseprite asset sets, deterministic mechanics, full-run touch flows, lifecycle/layout, imports, scene smoke, HTML5 export, and an actual exported-pack three-encounter clear. The complete local artifact is `build/web/`.

See [game setup and architecture](game/README.md), [actual verification and pending browser/device QA](qa/mobile/moonlit-dojo/validation.md), and [artwork provenance](CREDITS.md). Both implementation plans remain in `.hermes/plans/`. No publication is part of local verification.
