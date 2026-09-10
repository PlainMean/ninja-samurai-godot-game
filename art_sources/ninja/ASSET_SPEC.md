# Ninja attack asset

- Native canvas: 32 × 32 pixels, RGBA, transparent background.
- Character: side-facing ninja looking right, dark navy/black outfit, red scarf, steel blade.
- Animation: six editable attack frames, each exactly 100 ms; looping `attack` tag covering frames 1–6.
- Motion: ready stance, raised anticipation, forward cut, full extension, follow-through, recovery.
- Rendering: hand-authored pixel geometry through Aseprite Sprite/Image APIs only. Crisp pixels, limited palette, no antialiasing.
- Layers: separate scarf, body, blade, and slash effects for editing.
- Sheet: six 32 × 32 cells horizontally, 192 × 32 PNG, native resolution (no scaling).

## Expected outputs

- `generate_ninja.lua`: reproducible Aseprite drawing and export script.
- `ninja_attack.aseprite`: layered six-frame editable source.
- `ninja_attack_sheet.png`: transparent horizontal sprite sheet.
- `ninja_attack.gif`: looping animation at 100 ms per frame.
- `verify_ninja.lua`: independent source and export verification.
- `verification.txt`: verification results from reopening files in Aseprite.
