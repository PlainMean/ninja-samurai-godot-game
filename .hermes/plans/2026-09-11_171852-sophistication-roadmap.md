# Moonlit Dojo sophistication roadmap — 2026-09-11

## Audit and bounded contract
Starting commit: 3ec92e4; working tree initially clean. Godot 4.5.1 Standard,
Compatibility, 390×844, single-threaded relative Web export. Existing three
encounters have 3/4/5 HP, WATER affinity, automatic WATER replies, two bounded
health rewards. CombatModel owns deterministic damage; RunModel owns progression;
duel coordinates arena/HUD/modal scenes. Existing tests cover exact directed
cycle, timing, touch, retries, rewards, assets, and exported three-seal clear.
Two historical plans and elemental/moonlit QA reviewed. Prior native/browser
coverage is explicitly blocked. Six support Aseprite sets and original attacks
have byte-preservation gates. Existing generator uses Sprite/Image APIs.
Baseline verify.sh passed (baseline-verification.txt). Historical deployed build
is 6889955 per QA; current local elemental revision is later. Live baseline
inspection attempted through web and curl: web rejected URL, curl DNS failed.
No claim of current deployed equivalence. Deployment workflow remains untouched.

Maximum five passes; local engineering ceiling 25 minutes from audit completion.
Each pass must add model and scene assertions, run targeted tests and verify.sh,
inspect artifacts, then advance only when mandatory gates are green. Native
visual smoke is conditional on display access; inability is recorded, never
represented as visual approval. No push/deploy. Preserve all existing art bytes.

## High-value cohesive slice (priority order)
1. Journey presentation: dedicated route, shrine and final reveal scene panels,
   three new Aseprite-authored illustrated animation sheets, deterministic route
   progress and per-encounter result records. Keep existing battle and modal
   touch controls and three encounters. Acceptance: route marks earned/current/
   locked nodes; shrine only between fights; reveal only after third seal; losses
   retain earned progress; records append once/reset completely; all six touch
   clears, 120 retries, existing layout and artwork assertions remain intact.
2. Tactical readability: authoritative model attack forecasts and enemy intent,
   derived weakness for every element, readable selected outcome and lethal
   suppression of enemy reply. Acceptance: all 16 pairings plus NONE unchanged;
   forecast is pure, predicts actual/clamped damage, and never queues input;
   scene shows deterministic intent without overlapping controls. No balance
   migration or hidden outcomes.
3. If time and visual confidence allow: explicit limited-use ward ability with
   deterministic charge/status display. Gate: exhaustive timing/charge/reset,
   reward combinations and successful/lost full runs; no existing assertion
   removed or weakened. Requires an independently readable touch target.

## Stretch (not required for this bounded slice)
Enemy affinity rotation, differentiated intent cycles, shrine ability selection,
separate results navigation, optional route branches. These require balance and
physical-screen review; do not combine them opportunistically. Preserve three
encounters unless a future documented migration proves equivalent coverage.

## Exact mandatory gates for every completed pass
- Godot targeted model/scene suite: zero failures, no script/parse errors.
- game/tests/verify.sh exit 0: pinned engine, preserved assets, imports, full
  deterministic/scene tests, scene smoke, Web export, actual exported-pack clear,
  single-thread/no-backend pack validation and ≤1 MiB pack.
- New art: Aseprite editable source + JSON + runtime PNG, SHA256 manifest,
  3 distinct frames per sheet, binary alpha, nearest filtering; no raster tools
  besides Aseprite. Existing artwork hash files remain unchanged.
- git diff --check exit 0; actual logs retained under qa/mobile/sophistication/.
- Attempt native visual smoke with 390×844 display; inspect screenshots if any.
- README/dated QA accurately describe features, checks and blocked device/browser
  coverage. Commit only green completed work; STOP_REASON.md states why loop ends.

## Execution ledger
Pass 1 complete: 2,965 model/scene checks, zero failures; full wrapper exit 0;
97 exported entries / 91,572-byte pack; three-seal exported clear. New art sheets
inspected directly. Native attempted: X11 unavailable and Wayland connection
failed, so no screenshot/readability approval. Pass 2 selected next; bounded
readability work avoids new controls until native/device visual QA is possible.

Pass 2 complete: final 3,184 checks / zero failures; full wrapper exit 0;
97-entry, 93,572-byte pack; exported clear includes journey and forecast assertions.
Direct asset inspection led to route frames following unlocked encounter rather
than time. Final compact-layout assertions cover header and controls. Stop after
2/5 passes at quality boundary: new ward/status controls and balance migrations
need unavailable visual/device review. No time-ceiling claim. See STOP_REASON.md
and qa/mobile/sophistication/2026-09-11-validation.md for actual evidence.

## Continuation — pass 3
User authorized up to three further bounded passes from the dirty pass-2 tree,
with no commit/push/deploy. This supersedes the original commit instruction.
Completed one additional pass: authoritative, pure shrine reward forecasts used
by both claim application and the two existing choice controls; exact current /
maximum HP transitions and the next guardian's name/HP support the reward choice.
No fifth button, new art, scenes, reward values, intent cycles or balance changes.
Targeted and full verification: 3,677 checks / zero failures; wrapper exit 0,
97 entries / 94,100-byte pack; exported three-encounter clear; diff check exit 0.
Native display attempt still fails before rendering. Stop at 3/5 total passes
(1/3 additional); ward and differentiated intents remain deferred for visual and
device validation. No claim of exhausted time budget. Evidence:
qa/mobile/sophistication/pass-3-validation.md. Previous logs remain intact.
