# Multi-hero combat completed — 2026-09-14

Implemented from clean `ce55a48` in four bounded passes. Kira has a selectable
WATER Tide Arc independent of the equipped sword; Main Hero retains elemental
attacks and gains Flame Dash, Stone Guard and Windstep with cooldowns and shrine
development. Five campaign nodes have real 2–3-enemy parties, including a boss
with a minion. Touch target cards, actor controls, Skills panel, typed events,
ordered replies, persistence/reset and per-enemy visuals are integrated.

Final verification: **23,006 full-suite checks / 0 failures**, **2,175 targeted
combat checks / 0 failures**, and **1,051 independent exported-pack assertions**
across three complete mixed-action campaigns. Existing legacy/area export clears,
72 starting-build campaigns, Aseprite reproduction, native asset verifiers,
recursive pack dependencies/budgets and `git diff --check` pass. All 200 tracked
baseline art/source/frame/UI files remain byte-identical; no raster was added.

Artifact: `build/web/index.html` and siblings. PCK 262,668 bytes, 301 entries.
All changes remain in the parent workspace on HEAD `ce55a48`. `git add -A`
failed because `.git/index.lock` is read-only; no commit was possible.
No push or deployment.

Native X11/Wayland and Xvfb attempts failed before rendering due to display/socket
restrictions. Zero game captures; no native/browser/device visual acceptance
claimed. Both portrait sizes pass structural/headless scene checks. The native
capture script and failure logs are retained for a display-enabled follow-up.

[QA and exact evidence](qa/2026-09-14-multi-hero-combat/validation.md) ·
[Changed files](qa/2026-09-14-multi-hero-combat/files.md) ·
[Plan](.hermes/plans/2026-09-14_192244-multi-hero-combat.md)
