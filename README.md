# Moonlit Dojo: Eight Seals

A portrait, touch-first elemental duel journey built with Godot 4.5.1 Standard.
Read the guardian’s affinity and weakness, choose FIRE, WATER, EARTH or WIND,
and watch its announced reply. Eight seals open the moonlit archive.

| Level | Guardian | HP | Affinity | Weakness |
| --- | --- | ---: | --- | --- |
| 1 | Gate Warden — tutorial | 3 | WATER | WIND |
| 2 | Cinder Rival | 4 | FIRE | WATER |
| 3 | Cairn Sentinel | 5 | EARTH | FIRE |
| 4 | Gale Assassin | 3 | WIND | EARTH |
| 5 | Twin-cut Retainer — rematch | 4 | WATER | WIND |
| 6 | Ash Monk | 4 | FIRE | WATER |
| 7 | Fourfold Ronin — mixed elite | 5 | EARTH | FIRE |
| 8 | Moonlit Master — final duel | 5 | WATER | WIND |

Water attacks show blue surf, fire red flames, earth brown stone fragments,
and wind white air arcs. Both fighters use the actual attack element’s authored
animation. Guardians share preserved samurai artwork, with distinct names,
affinities, health and deterministic technique cycles across three backdrops.

```bash
game/tests/verify.sh
~/.local/bin/godot --path game
```

Keep health through seven shrines; choose capped Mend healing or increased
capacity. Forecasts predict actual damage and suppress a defeated foe’s reply.
Retry resets the entire route. Mouse and touch use the same four buttons.

[Architecture and setup](game/README.md) · [Plan](.hermes/plans/2026-09-12-eight-seals.md)
· [Dated QA](qa/mobile/eight-seals/2026-09-12-validation.md) · [Credits](CREDITS.md).
Local Web artifact: `build/web/index.html` with its complete sibling bundle.
Native/browser/device visual acceptance remains pending. No push or deployment.
