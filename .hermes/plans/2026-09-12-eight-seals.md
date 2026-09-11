# Eight Seals implementation plan — 2026-09-12

Audit: clean commit 21e178f. Reviewed all three prior plans, current README,
STOP_REASON, sophistication/elemental QA, scenes, Resource specs, model/view/tests,
export allowlist/workflow and Aseprite Sprite/Image generator and independent PNG
verifiers. Current run: gate_guard (Gate Warden, WATER, 3), courtyard_retainer
(Twin-cut Retainer, WATER, 4), dojo_master (Moonlit Master, WATER, 5). Nine existing
support/journey sheets and two original fighter sheets are immutable. Eight
existing scenes: arena, fighter, hud, duel, run_modal, route, shrine, reveal.
PatternSpec/StrikeSpec are unused legacy reactive resources, excluded from pack.
Live Pages inspection via web failed (unsafe URL); historical deployment is
6889955, not evidence of current deployment. Baseline wrapper running; record
actual result before implementation. No deployment/workflow changes authorized.

## Exact target inventory
Order | Resource ID | Identity | HP | Affinity / weakness | reply cycle | backdrop
1 | gate_guard | Gate Warden (tutorial) | 3 | WATER / WIND | WATER | gate
2 | fire_rival | Cinder Rival | 4 | FIRE / WATER | FIRE,FIRE,WIND | courtyard
3 | earth_sentinel | Cairn Sentinel | 5 | EARTH / FIRE | EARTH,WATER | gate
4 | wind_assassin | Gale Assassin | 3 | WIND / EARTH | WIND,FIRE | courtyard
5 | courtyard_retainer | Twin-cut Retainer (rematch) | 4 | WATER / WIND | WATER,WIND | courtyard
6 | ember_monk | Ash Monk | 4 | FIRE / WATER | EARTH,FIRE | dojo
7 | mixed_elite | Fourfold Ronin | 5 | EARTH / FIRE | WIND,WATER,FIRE,EARTH | courtyard
8 | dojo_master | Moonlit Master (final duel) | 5 | WATER / WIND | WATER,FIRE,EARTH,WIND | dojo

Keep original fighter animations and all scenery bytes. Enemy identities are
named combat roles/affinities/ordered techniques, using shared samurai artwork;
no claim of eight new character sprites. Distinct intent names describe each
cycle. Backdrops reuse three authored locations coherently (gate/courtyard/dojo).
New art: four 48x48, four-frame, 100ms elemental effects water/fire/earth/wind,
blue/red/brown/white respectively; dedicated art_sources/elements and matching
runtime sprites/frames/elements. Editable Aseprite + JSON + PNG per element,
Aseprite-only pixel authorship; read-only independent source/frame/alpha/palette/
hash checks. Preserve existing scene inventory; extend route text to eight nodes,
three regional route-art stages, eight compact seal icons, existing controls.

## Bounded passes (maximum five)
1. One cohesive implementation: test-first eight-encounter inventory, exact
matchup/weakness and reply cycles, model-driven effects, longer route/rewards,
Aseprite assets, scene integration. Migrate obsolete three-run literal assertions
to exact eight-run oracles; retain every behavioral assertion and original
three WATER timing fixtures. Targeted tests gate continuation.
2. Full verification, exported-pack full-run/dependency checks, native 390x844
capture attempt and inspection, fix concrete failures within this pass, docs/QA,
local commit attempt. Stop here at first quality boundary if browser/device
acceptance unavailable. Passes 3–5 only for concrete gate failures, no new scope.

Gates: exact pinned Godot 4.5.1 Standard Compatibility; full 16 directed matrix
plus NONE; inventory/order/HP/weakness; repeatable varied intents, forecasts and
actual events/effect metadata both actors; lethal suppression; route lock/reward
once/retry/reset/all reward paths/full clear; existing touch/lifecycle/layout
assertions retained. verify.sh zero failures and no hidden parse errors; original
asset hash gates unchanged; new binary source, PNG and metadata verification;
Web export and actual pack clear, dependencies and <=1 MiB pack; diff --check;
native capture if display permits, honest browser/device limits. No push/deploy.

## Execution ledger
Baseline wrapper passed 3,677 checks / zero failures, 97-entry pack. Live lookup
failed by web access and DNS; no deployed-version claim.
Pass 1 completed: exact inventory above, cycles/model/event effects and Aseprite
assets; targeted 13,776 checks / zero failures. All four strips inspected.
Pass 2 completed: 13,944 checks / zero failures; full wrapper, normal startup,
Web export and actual pack eight-level clear pass (19 attacks / 11 replies).
123-entry / 111,796-byte pack. Corrected normal-scene const Resource compile-order
failure with typed runtime loading and explicit export allowlist omissions;
failed attempts retained, not treated as passing. All 69 existing art files
byte-identical. diff --check passes. Native and Xvfb fail before rendering; no
screenshots. Stop after 2/5 passes at visual/browser/device acceptance boundary.
See qa/mobile/eight-seals/2026-09-12-validation.md and STOP_REASON.md.
