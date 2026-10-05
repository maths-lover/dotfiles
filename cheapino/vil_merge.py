#!/usr/bin/env python3
"""Splice cheapino/keymap.json into a Vial .vil export.

Vial's web/desktop UI imports its own `.vil` format (File -> Load Saved Layout),
NOT a QMK keymap.json. This takes a `.vil` you exported from YOUR board
(File -> Save Current Layout) and rewrites only the real key positions of layers
0-6 from keymap.json, translating QMK-short keycodes into the long VIA/Vial
spelling this firmware uses. Everything else (uid, phantom -1 cells, encoder,
macros, tap-dance, combos, QMK settings, extra layers 7+) is preserved so Vial
loads it without complaint.

Usage:
    python3 vil_merge.py base.vil                 # -> writes surajp.vil
    python3 vil_merge.py base.vil out.vil
    python3 vil_merge.py base.vil --training      # -> writes training.vil

--training derives a beginner layout: home row = plain letters (no hold-mods, so
a fast typist stops triggering stray Cmd/Ctrl/Shift), and the right-outer thumb
becomes a one-shot Shift for easy capitals (costs the FUN layer + forward-Delete
until you switch back). Numbers/symbols/arrows/Hammerspoon layers still work.

Then in Vial: File -> Load Saved Layout -> pick the output file.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent

# keymap.json LAYOUT_split_3x5_3 order (index 0-35) -> electrical [row, col],
# verbatim from tompi/qmk_firmware keyboards/cheapino/keyboard.json.
INDEX_TO_MATRIX = [
    [4, 10], [4, 9], [4, 8], [4, 7], [4, 6],        # L top
    [0, 0], [0, 1], [0, 2], [0, 3], [0, 4],         # R top
    [5, 10], [5, 9], [5, 8], [5, 7], [5, 6],        # L home
    [1, 0], [1, 1], [1, 2], [1, 3], [1, 4],         # R home
    [6, 10], [6, 9], [6, 8], [6, 7], [6, 6],        # L bottom
    [2, 0], [2, 1], [2, 2], [2, 3], [2, 4],         # R bottom
    [6, 11], [5, 11], [4, 11],                      # L thumbs (outer, mid, inner)
    [0, 5], [1, 5], [2, 5],                         # R thumbs (inner, mid, outer)
]

# QMK-short leaf keycode -> VIA/Vial long spelling this firmware speaks.
# Anything not listed (KC_A..Z, KC_0..9, KC_F1..12, KC_TAB, KC_HOME, arrows,
# bare mods, RGB_*, KC_TRNS, KC_NO) is already valid and passes through.
RENAME = {
    "KC_ENT": "KC_ENTER", "KC_BSPC": "KC_BSPACE", "KC_SPC": "KC_SPACE",
    "KC_ESC": "KC_ESCAPE", "KC_DEL": "KC_DELETE", "KC_SCLN": "KC_SCOLON",
    "KC_RGHT": "KC_RIGHT", "KC_PGDN": "KC_PGDOWN", "KC_GRV": "KC_GRAVE",
    "KC_COMM": "KC_COMMA", "KC_SLSH": "KC_SLASH", "KC_BSLS": "KC_BSLASH",
    "KC_MINS": "KC_MINUS", "KC_EQL": "KC_EQUAL", "KC_LBRC": "KC_LBRACKET",
    "KC_RBRC": "KC_RBRACKET", "KC_CAPS": "KC_CAPSLOCK", "KC_PSCR": "KC_PSCREEN",
    "KC_SCRL": "KC_SCROLLLOCK", "KC_PAUS": "KC_PAUSE", "KC_APP": "KC_APPLICATION",
    "KC_MPRV": "KC_MEDIA_PREV_TRACK", "KC_MNXT": "KC_MEDIA_NEXT_TRACK",
    "KC_MPLY": "KC_MEDIA_PLAY_PAUSE", "KC_MSTP": "KC_MEDIA_STOP",
    "KC_MUTE": "KC_AUDIO_MUTE", "KC_VOLD": "KC_AUDIO_VOL_DOWN",
    "KC_VOLU": "KC_AUDIO_VOL_UP", "QK_BOOT": "RESET",
}

# Shifted symbols: this firmware writes them as LSFT(base) (e.g. "!" = LSFT(KC_1)).
SHIFTED = {
    "KC_EXLM": "LSFT(KC_1)", "KC_AT": "LSFT(KC_2)", "KC_HASH": "LSFT(KC_3)",
    "KC_DLR": "LSFT(KC_4)", "KC_PERC": "LSFT(KC_5)", "KC_CIRC": "LSFT(KC_6)",
    "KC_AMPR": "LSFT(KC_7)", "KC_ASTR": "LSFT(KC_8)", "KC_LPRN": "LSFT(KC_9)",
    "KC_RPRN": "LSFT(KC_0)", "KC_UNDS": "LSFT(KC_MINUS)", "KC_PLUS": "LSFT(KC_EQUAL)",
    "KC_LCBR": "LSFT(KC_LBRACKET)", "KC_RCBR": "LSFT(KC_RBRACKET)",
    "KC_PIPE": "LSFT(KC_BSLASH)", "KC_COLN": "LSFT(KC_SCOLON)",
    "KC_TILD": "LSFT(KC_GRAVE)",
}

MODS = "LGUI|LCTL|LSFT|LALT|RGUI|RCTL|RSFT|RALT"


def vk(code: str) -> str:
    """Translate one QMK-short keycode string into Vial .vil spelling."""
    if code in ("KC_TRNS", "KC_NO"):
        return code
    if code in SHIFTED:
        return SHIFTED[code]
    m = re.fullmatch(r"LT\((\d+),\s*(.+)\)", code)          # LT(n,kc) -> LTn(kc)
    if m:
        return f"LT{m.group(1)}({vk(m.group(2))})"
    m = re.fullmatch(rf"({MODS})_T\((.+)\)", code)          # mod-tap
    if m:
        return f"{m.group(1)}_T({vk(m.group(2))})"
    m = re.fullmatch(rf"({MODS})\((.+)\)", code)            # modded / nested
    if m:
        return f"{m.group(1)}({vk(m.group(2))})"
    return RENAME.get(code, code)                           # leaf


def apply_training(base: dict) -> None:
    """In-place: plain home-row letters + one-shot Shift on the right-outer thumb."""
    override = {
        10: "KC_A", 11: "KC_S", 12: "KC_D", 13: "KC_F",       # left home
        16: "KC_J", 17: "KC_K", 18: "KC_L", 19: "KC_SCOLON",  # right home
        35: "OSM(MOD_LSFT)",                                  # right-outer thumb
    }
    grid = base["layout"][0]
    for idx, code in override.items():
        r, c = INDEX_TO_MATRIX[idx]
        grid[r][c] = code


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--training"]
    training = "--training" in sys.argv
    if not args:
        sys.exit(__doc__)
    base_path = Path(args[0])
    default_out = "training.vil" if training else "surajp.vil"
    out_path = Path(args[1]) if len(args) > 1 else HERE / default_out

    keymap = json.loads((HERE / "keymap.json").read_text())["layers"]
    base = json.loads(base_path.read_text())

    have, need = len(base.get("layout", [])), len(keymap)
    if have < need:
        sys.exit(f"Firmware exposes {have} layers but keymap needs {need}; "
                 "tell me and I'll compress the design.")

    for li, layer in enumerate(keymap):
        grid = base["layout"][li]                # keep phantom -1 cells as-is
        for idx, code in enumerate(layer):
            r, c = INDEX_TO_MATRIX[idx]
            grid[r][c] = vk(code)

    if training:
        apply_training(base)

    out_path.write_text(json.dumps(base, indent=2))
    mode = "training (plain home row)" if training else "full (home-row mods)"
    print(f"wrote {out_path.name}: {mode}, {need} layers merged, {have - need} "
          f"kept, uid {base.get('uid')} preserved")


if __name__ == "__main__":
    main()
