# Changed files — 2026-09-14

20 modified tracked files; 43 new files. No art assets changed.

## Modified

- `CREDITS.md`
- `README.md`
- `STOP_REASON.md`
- `game/README.md`
- `game/export_presets.cfg`
- `game/scenes/arena.tscn`
- `game/scenes/duel.tscn`
- `game/scripts/area_panel.gd`
- `game/scripts/combat_event.gd`
- `game/scripts/combat_model.gd`
- `game/scripts/data/encounter_spec.gd`
- `game/scripts/duel.gd`
- `game/scripts/fighter_view.gd`
- `game/scripts/hud.gd`
- `game/scripts/layout_helper.gd`
- `game/scripts/run_model.gd`
- `game/tests/check_web_export.py`
- `game/tests/run_tests.gd`
- `game/tests/test_area_campaign.gd`
- `game/tests/verify.sh`

## New

- `.hermes/plans/2026-09-14_192244-multi-hero-combat.md`
- `game/data/encounters/parties/ash_monk.tres`
- `game/data/encounters/parties/coast_ronin.tres`
- `game/data/encounters/parties/iron_vanguard.tres`
- `game/data/encounters/parties/tempest_sovereign.tres`
- `game/data/encounters/parties/twin_cut_retainer.tres`
- `game/data/skills/flame_dash.tres`
- `game/data/skills/stone_guard.tres`
- `game/data/skills/windstep.tres`
- `game/scripts/combat_controls.gd`
- `game/scripts/combat_controls.gd.uid`
- `game/scripts/data/enemy_state.gd`
- `game/scripts/data/enemy_state.gd.uid`
- `game/scripts/data/skill_spec.gd`
- `game/scripts/data/skill_spec.gd.uid`
- `game/tests/export_multi_combat_smoke.gd`
- `game/tests/export_multi_combat_smoke.gd.uid`
- `game/tests/multi_combat_gate.gd`
- `game/tests/multi_combat_gate.gd.uid`
- `game/tests/native_multi_combat_smoke.gd`
- `game/tests/native_multi_combat_smoke.gd.uid`
- `game/tests/test_multi_combat.gd`
- `game/tests/test_multi_combat.gd.uid`
- `game/tests/test_multi_rules.gd`
- `game/tests/test_multi_rules.gd.uid`
- `game/tests/test_multi_scene.gd`
- `game/tests/test_multi_scene.gd.uid`
- `qa/2026-09-14-multi-hero-combat/aseprite-reproduction.log`
- `qa/2026-09-14-multi-hero-combat/commit-attempt.log`
- `qa/2026-09-14-multi-hero-combat/files.md`
- `qa/2026-09-14-multi-hero-combat/native-x11.log`
- `qa/2026-09-14-multi-hero-combat/native-xvfb.log`
- `qa/2026-09-14-multi-hero-combat/pass1-targeted.log`
- `qa/2026-09-14-multi-hero-combat/pass1-verify.log`
- `qa/2026-09-14-multi-hero-combat/pass2-targeted.log`
- `qa/2026-09-14-multi-hero-combat/pass2-verify.log`
- `qa/2026-09-14-multi-hero-combat/pass3-targeted.log`
- `qa/2026-09-14-multi-hero-combat/pass3-verify.log`
- `qa/2026-09-14-multi-hero-combat/pass4-targeted.log`
- `qa/2026-09-14-multi-hero-combat/pass4-verify.log`
- `qa/2026-09-14-multi-hero-combat/preservation.log`
- `qa/2026-09-14-multi-hero-combat/validation.md`
- `qa/2026-09-14-multi-hero-combat/xvfb-server.log`

## Local generated artifacts (gitignored)

- `build/web/index.html` and siblings: verified single-threaded Web release.
- `build/multi-combat-reproduction/`: Aseprite-only byte-identical asset reproduction.
- `build/*.log`: import, targeted/full suites, native-script checks, export and exported-pack execution.

Scenes changed: `game/scenes/arena.tscn` (two persistent extra enemy slots), `game/scenes/duel.tscn` (combat controls root). HUD/target/skill controls are projected by scripts; no new art or scene raster.
