# Moonlit Dojo: Three Seals

A portrait turn-based touch game built with Godot 4.5.1 Standard. Choose **FIRE**, **WATER**, **EARTH**, or **WIND**, then watch the samurai's automatic WATER turn. **WIND is effective against WATER.** Carry health through three encounters and choose a reward after each of the first two victories.

```bash
game/tests/verify.sh
~/.local/bin/godot --path game
```

The verification wrapper checks preserved artwork, six preserved Aseprite asset sets plus three journey sheets, deterministic mechanics, full-run touch flows, lifecycle/layout, imports, scene smoke, HTML5 export, and an actual exported-pack three-encounter clear. The complete local artifact is `build/web/`.

See [game setup and architecture](game/README.md), [actual verification and pending browser/device QA](qa/mobile/elemental/validation.md), and [artwork provenance](CREDITS.md). Implementation plans remain in `.hermes/plans/`. This revision is local only; no push or deployment was performed.

The local sophistication slice adds dedicated route, renewal-shrine and archive
reveal scenes, three Aseprite-authored support sheets, per-encounter result records,
and deterministic attack damage/SEAL previews with enemy intent. The three WATER
encounters and exact elemental cycle retain their existing balance. Route art
tracks unlocked gates; shrine and reveal glow through three authored frames.
See the [bounded roadmap](.hermes/plans/2026-09-11_171852-sophistication-roadmap.md),
[dated QA](qa/mobile/sophistication/2026-09-11-validation.md), and
[stop reason](STOP_REASON.md). Three improvement passes completed locally; native
rendering and browser/device acceptance remain blocked. No push or deployment.

Shrine gifts now preview exact current-to-result HP for both choices, including
capped Mend healing, alongside the next guardian’s name and HP. Existing reward
values and touch controls are unchanged. Pass 3 passed 3,677 checks and the full
export gate; see [continuation QA](qa/mobile/sophistication/pass-3-validation.md).
