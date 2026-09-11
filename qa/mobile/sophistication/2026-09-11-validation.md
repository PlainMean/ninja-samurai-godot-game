# Sophistication QA — 2026-09-11

Two of at most five passes completed. Local automated acceptance passed. Native
visual and browser/device release acceptance remain BLOCKED. No push/deployment.
Starting commit 3ec92e4, initially clean. User-requested model/effort cannot be
independently established through repository tooling; no subagents used.

## Delivered behavior
- Three dedicated presentation scenes: route, shrine, archive reveal, hosted by
  the existing modal. Existing battle, results controls and three encounters stay.
- Route caption distinguishes SEALED/NEXT/LOCKED; authored route frame follows the
  unlocked encounter, never decorative time. Shrine/reveal animate at 300ms/frame.
- One result record per completed/lost encounter; shrine displays actual fight
  attacks/damage. Retry/title clears records. Final archive has narrative reveal
  and existing final aggregate stats.
- Four pure attack forecasts show damage or SEAL, disappear during resolution,
  clamp overkill and account for skipped lethal replies. Explicit enemy intent;
  weakness derived from the unchanged WATER>FIRE>EARTH>WIND>WATER directed cycle.
- Unchanged 3/4/5-HP WATER enemies, four WATER replies and seven WIND attacks for
  the effective clear; existing health rewards remain the progression system.
- No status ability, affinity rotation, new rewards or separate results navigation.

## Actual gates and evidence
| Gate | Actual result | Evidence |
| --- | --- | --- |
| Baseline wrapper | Exit 0; 2,922 checks / 0 failures | baseline-verification.txt |
| Pass 1 targeted scene/model suite | 2,965 checks / 0 failures | pass-1-targeted.txt |
| Pass 1 full wrapper | Exit 0, exported three-seal clear | pass-1-verification.txt |
| Pass 2 targeted suite | 3,182 checks / 0 failures before final compact-layout assertions | pass-2-targeted.txt |
| Pass 2 final full wrapper | Exit 0; 3,184 checks / 0 failures | pass-2-verification.txt |
| Preserved artwork | Both original hash suites and six-set metadata checks pass | both pass verification logs |
| New artwork | Three source/runtime sheets, hashes, dimensions, distinct frames and JSON timing pass | pass-2-verification.txt; game/tests/journey_asset_manifest.json |
| Import/script and headless scene smoke | Pass; pinned 4.5.1 Standard | pass-2-verification.txt |
| Web export and pack load | Pass; 97 entries, 93,572-byte pack | pass-2-verification.txt |
| Exported full run | Pass; route, shrine, reveal, intent and forecast assertions plus existing full-run assertions | pass-2-verification.txt |
| Relative single-thread bundle checks | Pass; 38,582,875 raw / 9,418,852 local gzip bytes | pass-2-verification.txt |
| Native visual smoke | BLOCKED: X11 unavailable, Wayland cannot connect; no captures | native-visual.txt |
| Live deployed baseline | BLOCKED: web open rejected; curl DNS resolution failed | deployed-baseline.txt |
| git diff --check | Exit 0, no output | diff-check.txt |

Full wrapper includes original six touch-only clears at 1×/2×/3×, 120 retries,
all reward combinations, exact timing/impact boundaries, pointer/lifecycle safety,
no fourth encounter, and five portrait layouts. New checks add forecast/actual
agreement across all four attackers and five defenders (including NONE), lethal
reply suppression, record/reset/loss behavior, panel exclusivity and compact
header/control separation. No existing assertion was weakened or removed, and
no skip/todo/only test markers were introduced.

The prior socket-listener environment errors occur during import/export and are
not script failures. Native failure is separate: the display never initializes.
Logs in build/*.log are generated; retained QA transcripts above are committed.
Runnable local artifact: build/web/index.html with its complete sibling bundle.
Local gzip sizes are not network or browser performance measurements.

## Art provenance and inspection
Three new 160×96 illustrations, nine total frames, in Aseprite editable sources
and horizontal 480×96 PNG sheets. Source/JSON/Lua: art_sources/journey/; runtime:
game/assets/sprites/journey/. Generated only through ~/.local/bin/aseprite
Sprite/Image APIs. Initial export required workspace-local XDG configuration;
rerun succeeded. Python only reads/hashes/validates PNGs and writes text metadata,
never raster art. CREDITS and a separate new manifest are updated; existing art
and manifests retain their bytes. All three sheets inspected directly: gate
route, renewal shrine and lit archive. This is asset inspection, not game visual
approval. Route frame sampling was tied to actual progress following inspection.

## Explicit remaining limitations
Native game appearance, text readability, animation feel and screenshot review;
real WebGL browser loading/touch/mouse; iOS Safari/Android Chrome; physical target
size, safe areas, browser background/resume, MIME/HTTPS, cold/warm loading,
performance/memory remain untested. Native headless and exported-pack execution
are not browser coverage. Historical deployment records refer to 6889955, not
this revision; live deployment state could not be verified.

STOP_REASON.md records the quality stop: defer additional touch targets and
balance/status migrations until native/device visual review is available. The
25-minute engineering ceiling was not reached. This is a bounded local slice,
not completion of stretch ideas or release approval.

## Commit attempt and final repository state
After green gates, `git add` and `git commit` were attempted. Both failed with
`Unable to create .../.git/index.lock: Read-only file system`. The managed
workspace grants read-only access to .git and disallows escalation. No commit
was created, no push/deploy attempted. HEAD remains 3ec92e4. Working tree is DIRTY
with completed changes; see files-changed.txt. Commit remains blocked until the
repository metadata is writable. Whitespace checks still pass.

## Continuation addendum
Pass 3 subsequently completed from this dirty workspace: 3,677 checks / zero
failures and full wrapper exit 0. See [pass 3 report](pass-3-validation.md) for
current results, added reward previews and remaining limitations. Earlier entries
above describe the historical passes 1–2, including their commit attempt; no
commit was attempted in the continuation.
