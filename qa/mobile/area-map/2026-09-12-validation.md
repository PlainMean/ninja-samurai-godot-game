# Four Lands QA — 2026-09-12

Audit started from clean HEAD `cce61af`. Plan:
`.hermes/plans/2026-09-12_123553-area-map-weapons.md`.
Three bounded passes; full verify gate passed before each next pass.

- Baseline: original 13,944 assertions and original exported eight-seal clear.
- Pass 1: 14,267 checks, zero failures; full asset, import, native script check,
  scene smoke, Web export, exported legacy clear and pack gate passed.
- Pass 2: 14,280 checks, zero failures; full gate plus actual exported twelve-node,
  four-boss campaign and original eight-encounter clear passed.
- Pass 3: expanded all-build/seed/traversal and exhaustive damage matrix checks;
  final results recorded below after the final gate.

Coverage includes 72 complete model campaigns (six starting pairs × four swords
× three seeds), alternate frontier orders, four bosses, all six sword metadata,
loot affinity/equip, locked technique rejection, level caps, deterministic reset,
forecast purity, additive impact metadata, exact four element colors, boss loss,
retry, touch clipping, modal exclusivity and restored intro visibility. Legacy
assertions remain; old scene suites explicitly choose the retained legacy mode.
The export pack checker requires new weapon Resources and area UI script.

No new or changed art. Independent Aseprite/PNG/metadata/hash verifiers passed.
Migration duplicates all eight prior encounter Resources into twelve configured
identities; original files and original campaign remain reusable and tested.

Native 390×844 attempt: failed before rendering, exit 1. X11 unavailable, Wayland
cannot connect. Xvfb attempt also failed, exit 1; see `native-smoke.log` and
`xvfb.log`. No screenshot exists to inspect. Native screenshot script is included
and parse-checked. Browser WebGL, HTTP/Pages loading, mobile touch scrolling,
physical device safe areas/lifecycle/readability/performance remain unverified.

During implementation the gate exposed mixed indentation and early Resource
preload initialization; both were fixed before pass 1 passed. A direct Godot
invocation without local XDG directories crashed trying to open its log; all
subsequent invocations use writable repository-local XDG data. Editor TCP listen
errors reflect sandbox restrictions; no parse errors are suppressed by the gate.
No push/deploy or browser acceptance claim.

Final gate: **19,840 checks, zero failures**. Both exported campaigns passed.
Web PCK: **139 entries, 130,128 bytes**. Bundle: **38,620,514 raw bytes**,
**9,440,374 gzip bytes** (local checker’s per-file level-9 total).
Godot pinned version, both native smoke script parse checks, all asset verifiers,
headless scene smoke, single-threaded relative-path export, pack dependencies and
size limit passed. `git diff --check` and direct HEAD artwork diff passed.
Evidence: `model-scene-results.txt`, `exported-campaigns.txt`,
`full-verification.log`, `art-preservation.txt`, `diff-check.txt`.
Artifact: `build/web/index.html` and sibling files. No deployment performed.

Commit attempt: `git add` failed with exit 128 because `.git/index.lock` cannot
be created on the read-only filesystem. No commit was created. Changes remain
in the working tree for the parent workspace to commit; no reset/discard,
permission escalation, push or deployment occurred. See `commit-attempt.txt`.
