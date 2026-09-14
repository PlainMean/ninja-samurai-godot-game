# Multi-hero combat — 2026-09-14

Baseline: clean HEAD ce55a48. Parent workspace only; no push/deploy. Requested Astra/medium; current session model selection is environment-controlled. No delegated agents authorized. Independent verification will use separate test entry points and a read-only pack/asset verifier.

## Bounded passes (maximum five)
1. Pure combat: typed enemy states, explicit actor/target selection, Tide Arc, three data-driven deterministic skills, typed snapshots and persistence. Add focused pure tests. Gate: targeted suite then game/tests/verify.sh; repair any failure before next pass.
2. Campaign and presentation: separate party EncounterSpec resources for Ash Monk, Twin-cut Retainer, Iron Vanguard, Coast Ronin and Tempest Sovereign; preserve every original single encounter resource. Mobile target cards, actor controls, skills modal, distinct sprites and shrine development. Add scene/party tests. Same gate.
3. Verification and polish: expand replay, all-build campaigns, resource dependencies and exported gameplay coverage; attempt real native 390x844/390x780 captures and inspect them. Same gate.
4. Only if needed: repair findings from independent/native verification, gate again.
5. Final bounded documentation/verification pass: dated QA, READMEs, STOP_REASON, exact observed counts and budgets, unchanged art hashes, final targeted/full gate and diff check; commit if permitted. No deployment.

## Rules and design
Normal sword formula and elemental cycle stay unchanged. Enemies reply once in living slot order; dead slots never reply, full-party death wins, player death stops the queue. The existing spec/enemy_hp aliases refer to the selected target. Original single-enemy timing stays 1.55 seconds per round; parties add 0.95 seconds per extra living reply.
Kira Tide Arc: fixed 3 + companion development (0–2) + WATER advantage (0/1); no sword or RNG dependency. Manual Kira action consumes the entire action and suppresses automatic support that turn. Optional automatic Support Strike/Ward Pulse retained for main actions and switchable off. Fatigue remains one HP per actual enemy reply. Fallen Kira falls back to main hero.
Skills are resource-defined: Flame Dash FIRE damage 5 + skill level + advantage; Stone Guard EARTH grants a shared block pool 3 + level for the next reply phase; Windstep WIND damage 3 + level + advantage, evades the first living reply. Each has a two-round cooldown (two intervening actions); no RNG. Shrine skill development is independent of existing technique and companion training, capped at +2. Cooldowns and guard clear at encounter boundaries; actor/auto preference and skill level persist through the run and reset on new run.
No new raster assets. Existing art remains byte-identical. Portrait controls >=48 px; enemy cards and skill choices occupy separate regions. Model owns every HP change; views only project state and forward input.

## Evidence log
- Initial git status clean; HEAD ce55a48.
- Honcho lookup blocked by environment approval policy; repository used as authority.
- Pass 1 complete: 51 targeted / 20,852 full checks, zero failures; all export/asset gates pass. Repaired typed-array initialization, single-foe log compatibility and a self-referential EncounterSpec script leak (exported Resource array, typed EnemyState boundary).
- Pass 2 complete: 157 targeted / 20,988 full checks, zero failures; 301 PCK entries, 261,548 bytes. All 72 existing starting-build/seed/traversal campaigns and exported clears pass with parties. Repaired compact breakpoint and log/hint/companion spacing, retained every prior assertion. Original single resources and leader stats unchanged.
- Pass 3 complete: 2,066 targeted / 22,897 full checks, zero failures. Independent exported run: 1,051 assertions, three campaigns, 15 party clears, 39 Tide Arcs, 81 skills. 14 roots / 74 recursive dependencies verified. PCK 262,476 bytes / 301 entries. Repaired a nested test fixture exposed by stronger model boundary validation; no shipped nesting.
- Aseprite reproduced six PNG/JSON pairs byte-for-byte into build/multi-combat-reproduction. All native/independent asset verifiers pass; no new raster.
- Actual native X11/Wayland and Xvfb capture attempts failed before rendering (display/socket restrictions). Zero screenshots; no browser/device acceptance claimed. New native capture script is retained and parse-gated.
- Pass 4 is the final bounded review/documentation pass; pass 5 reserved only if verification exposes a material remaining issue.
- Pass 4 complete: 2,175 targeted / 23,006 full checks, zero failures; 1,051 independent exported assertions. Full party-card font widths, enemy frame separation and raw Kira touch checked. Final PCK 262,668 bytes / 301 entries; bundle 38,756,436 raw / 9,492,654 gzip bytes. Independent comparison preserves all 200 baseline art/source/frame/UI files and all 74 old test-directory files. READMEs, credits, STOP_REASON and dated QA updated.
- Final diff check passes. Commit attempted via git add -A: .git/index.lock is read-only. HEAD stays ce55a48; all requested changes remain in the parent workspace, uncommitted. No push/deploy. Four passes used; fifth not needed. Native/browser/device visual acceptance remains blocked by the observed display environment, not claimed.
