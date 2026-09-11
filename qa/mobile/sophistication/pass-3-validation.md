# Pass 3 — exact shrine reward planning

Completed one additional bounded pass (3 total; passes 4–5 not started). Began
from the dirty pass-2 workspace and preserved its work. No resets, commits, pushes
or deployments. No subagents. No new art or scenes; six Moonlit sets, original
assets and three journey sheets pass their unchanged preservation gates.

Reward forecasts are pure, reject unavailable/stale/unknown choices, and describe
actual capped healing and capacity. Claims consume the same forecast. Existing
two shrine buttons display exact HP transitions and disable full-health Mend;
shrine instructions show the next guardian name and HP. Combat remains exactly
FIRE>EARTH, WATER>FIRE, EARTH>WIND, WIND>WATER; other matchups neutral, all enemies
WATER with WIND weakness, and three encounters with unchanged health/rewards.

## Actual verification
- Targeted final suite: exit 0, **3,677 checks / zero failures** in
  `pass-3-targeted-final.txt` (493 additional assertions).
- Full `game/tests/verify.sh`: exit 0, **3,677 checks / zero failures**, original
  asset hashes, six-set metadata, journey hashes, imports, script checks, scene
  smoke, Web export, exported pack load and three-seal run all green in
  `pass-3-verification.txt`.
- Bundle: **97 pack entries, 94,100-byte pack**; single-thread relative bundle
  check passes; 38,583,403 raw / 9,419,359 local gzip bytes.
- `git diff --check`: exit 0, `pass-3-diff-check.txt` (empty success output).
- Native visual attempt: exit 1, X11 unavailable and Wayland cannot connect;
  `pass-3-native-visual.txt`. No screenshots or visual acceptance.

New coverage exhausts both shrine indices, capacities 5–6 and health 1–capacity,
checking pure/repeatable forecasts, detached dictionaries, actual claims, capped
healing, full-health rejection, duplicate claims, invalid states/IDs, title reset
and the existing choice signal reaching the next combat model. Scene assertions
check exact labels, next health, text font widths/two-line height, 72-unit targets,
separation and unchanged 350×326 modal bounds at 390×844, 390×700, 360×800,
393×852 and 430×932. Existing touch runs, retries and all reward combinations
remain green. Exported smoke additionally verifies shrine forecast presentation.
No existing test assertion removed/weakened or skip/todo/only markers added.

Initial direct targeted launch without workspace XDG paths crashed in engine
startup (`pass-3-targeted.txt`). Using the wrapper's workspace XDG paths exposed
a test-local inferred Variant type error (`pass-3-targeted-local-xdg.txt`); fixed
with an explicit bool annotation, then targeted and full gates passed. Failed
attempt logs retained. These are not counted as successful gates.

## Files and artifact
New implementation files: `game/tests/test_reward_forecast.gd` and its Godot UID.
Modified for this pass: run_model.gd, duel.gd, run_tests.gd, export_pack_smoke.gd,
root/game README, existing roadmap and STOP_REASON. QA adds this report, initial
and final targeted logs, full verification, native attempt, diff and status logs.
Zero assets/scenes added this pass. Earlier untracked art/scenes remain preserved.
Runnable artifact: `build/web/index.html` and its complete sibling bundle.
Final status: `pass-3-git-status.txt`; all work remains uncommitted.

Native visual readability, browser WebGL/touch, physical iOS/Android/safe areas,
lifecycle and performance remain unverified. Headless geometry/font assertions
are not device approval. Ward/focus and differentiated intent/status features
remain deferred; this safe presentation pass does not claim deeper combat tactics.
Memory retrieval was unavailable because the tool requires approval under the
never-approval policy; local plan and QA supplied project context.
