# Samurai enemy attack

- Native canvas: **32 × 32 pixels**, RGBA with a transparent background.
- Character: a **side-facing samurai facing right**, with dark indigo lamellar armor, a muted red sash, a kabuto helmet, a visible face guard, and a steel katana.
- Animation: **6 distinct attack frames**, **100 ms per frame**, with a forward **`attack`** tag spanning frames 1–6 (600 ms total).
- Motion: guard, anticipation, raised blade, cutting strike, follow-through, recovery. A planted ground line, shifting hips, trailing sash, and a short steel-colored slash accent support the attack.
- Pixel treatment: hard pixel edges, a compact shared palette, dark outlines, selective armor highlights, and no antialiasing. All art is drawn by Lua through Aseprite's Sprite/Image APIs.
- Editability: separate armor/body, arms/katana, and slash-effect layers, with real timeline frames and explicit durations.

## Expected outputs

| File | Purpose |
| --- | --- |
| `generate_samurai.lua` | Reproducible Aseprite-only pixel drawing and animation source |
| `samurai_attack.aseprite` | Editable 32 × 32, six-frame layered source |
| `samurai_attack_sheet.png` | Native horizontal strip, 192 × 32, transparent |
| `samurai_attack.gif` | Native 32 × 32 looping animation, six 100 ms frames |
| `samurai_attack_sheet_4x.png` | 768 × 128 horizontal preview, nearest-neighbor 4× scale |
| `verify_samurai.lua` | Independent Aseprite-side validation of the saved source and exports |
| `verification.txt` | Recorded verification results |

All creation, export, and image verification use the actual `~/.local/bin/aseprite` executable. No external image generators or image-processing libraries are used.
