# Cheapino v2 keymap

Firmware + keymap for a **Cheapino v2** — an affordable 36-key split
(`LAYOUT_split_3x5_3`: 3×5 per hand + 3 thumbs, one RP2040-Zero, one encoder).

This layout is a [Miryoku](https://github.com/manna-harbour/miryoku)-style base
with **home-row mods** and **thumb layer-taps**, plus a custom **WM layer** that
drives the Hammerspoon window manager in `.config/hammerspoon` with its
`Cmd+Ctrl` chords. Tuned for the vim / zellij / Hammerspoon workflow in this repo.

- Source of truth: [`keymap.json`](keymap.json) (QMK Configurator / `qmk` format).
- Upstream: <https://github.com/tompi/cheapino> · firmware guide `doc/firmware.md`.

> This directory is **not** stowed into `$HOME` (see `.stow-local-ignore`); it is
> firmware source, not a runtime config.

---

## 1. Flash the firmware (Vial route — recommended)

Vial lets you re-map **live over USB** with no compile toolchain — ideal while
you iterate on the Hammerspoon binds below.

1. Download `cheapino_vial.uf2` from the v2 release:
   <https://github.com/tompi/cheapino/releases>.
2. Put the RP2040-Zero in **DFU / boot mode**: hold the **BOOT** button while
   plugging in USB-C. It mounts as a USB drive (`RPI-RP2`).
3. **Drag `cheapino_vial.uf2` onto that drive.** It reboots instantly — a
   "disk ejected / write error" toast is normal and does **not** mean failure.
4. Open <https://vial.rocks> (Chrome/Edge, WebHID) or the desktop app from
   <https://get.vial.today/download/> → **Authorize** → the board appears.
5. Enter the layers below on the Vial matrix, or load a saved `.vil`.

Once flashed you rarely re-flash: Vial writes changes to the board directly.

### Re-entering boot mode later

Either hold **BOOT** and tap **RESET** on the RP2040-Zero, or tap **`QK_BOOT`**
(MEDIA layer, top-left — hold left-outer thumb, then top-left key).

---

## 2. Layers

`X/m` = tap `X`, hold for modifier `m` (**G**UI/Cmd · **A**lt/Opt · **C**trl ·
**S**hift). Thumb keys show `tap` over the `LAYER` they activate on hold.

### 0 · BASE — QWERTY + home-row mods (GACS)

```
  Q     W     E     R     T          Y     U     I     O     P
 A/G   S/A   D/C   F/S    G          H    J/S   K/C   L/A   ;/G
  Z     X     C     V     B          N     M     ,     .     /
             ESC   SPC   TAB        ENT   BSPC  DEL
             MED   NAV    WM        SYM   NUM   FUN
```

Home-row mods: `A`=Cmd `S`=Alt `D`=Ctrl `F`=Shift · mirror on `J K L ;`.
Both Alt mods emit **Left-Alt** so Ghostty (`macos-option-as-alt = left`) and
the zsh word-motions see it as Meta.

### 1 · NAV — hold left-middle thumb (over `SPC`)

```
  ·     ·     ·     ·     ·         HOME  PGDN  PGUP  END    ·
 Cmd   Alt   Ctrl  Shft   ·        LEFT  DOWN   UP   RGHT  CAPS
  ·     ·     ·     ·     ·          ·     ·     ·     ·     ·
```

Arrows land on `h j k l` (vim muscle memory), everywhere in macOS. Left home
row holds bare mods so `Shift+Arrow` selection and `Cmd+Arrow` work.

### 2 · SYM — hold right-inner thumb (over `ENT`)

```
  {     &     *     (     }          ·     ·     ·     ·     ·
  :     $     %     ^     +          ·    Shft  Ctrl  Alt   Cmd
  ~     !     @     #     |          ·     ·     ·     ·     ·
              (     )     _
```

### 3 · NUM — hold right-middle thumb (over `BSPC`)

```
  [     7     8     9     ]          ·     ·     ·     ·     ·
  ;     4     5     6     =          ·    Shft  Ctrl  Alt   Cmd
  `     1     2     3     \          ·     ·     ·     ·     ·
              .     0     -
```

### 4 · FUN — hold right-outer thumb (over `DEL`)

```
 F12   F7    F8    F9   PSCR         ·     ·     ·     ·     ·
 F11   F4    F5    F6   SCRL         ·    Shft  Ctrl  Alt   Cmd
 F10   F1    F2    F3   PAUS         ·     ·     ·     ·     ·
             APP   SPC  TAB
```

### 5 · MEDIA — hold left-outer thumb (over `ESC`)

```
BOOT  RGBt  RGBm    ·     ·          ·     ·     ·     ·     ·
  ·     ·     ·     ·     ·         PREV  VOL-  VOL+  NEXT   ·
  ·     ·     ·     ·     ·          ·     ·     ·     ·     ·
                                    STOP  PLAY  MUTE
```

`BOOT` = `QK_BOOT` (jump to bootloader for re-flashing).

### 6 · WM — Hammerspoon — hold left-inner thumb (over `TAB`)

```
  ·     ·     ·    C^R    ·           ·     ·     ·     ·     ·
  ·     ·     ·     ·     ·         C^H   C^J   C^K   C^L    ·
  ·     ·     ·     ·     ·           ·     ·     ·     ·     ·
                              [C^SPC]
```

`C^x` = **`Cmd+Ctrl+x`**, the modifier this repo's Hammerspoon uses:

| WM-layer key | Sends | Hammerspoon action |
|--------------|-------|--------------------|
| right-inner thumb | `Cmd+Ctrl+Space` | **toggle window mode** (sticky modal) |
| `h` `j` `k` `l` | `Cmd+Ctrl+h/j/k/l` | **focus** window left/down/up/right (global) |
| `R` (top row) | `Cmd+Ctrl+R` | **reload** Hammerspoon config |

See `.config/hammerspoon/docs/13.01-keybindings.md`.

---

## 3. Driving Hammerspoon from the board

Two ways, both fast:

1. **Direct focus** — hold left-inner thumb (WM), tap `h/j/k/l`. Fires the global
   `Cmd+Ctrl+hjkl` focus binds without contorting for the chord.
2. **Window mode** — hold left-inner thumb, tap right-inner thumb → sends
   `Cmd+Ctrl+Space`, which pops the **sticky window-mode modal**. Now release
   everything: the modal reads **bare** keys, so plain `h l k j` = halves,
   `y u b n` = quarters, `m` = maximize, `c` = center, `Tab` = next display,
   `q`/`Esc` = exit.

> **Numbers/symbols inside window mode.** Thirds (`1 2 3`, `4 6`) and grow/shrink
> (`-`/`=`) live on the NUM/SYM layers, not BASE. While window mode is active,
> hold the NUM thumb and tap `1/2/3` — the modal still sees the digit. If you use
> thirds constantly, consider adding letter aliases in `lua/modal.lua`
> (e.g. bind `a`/`s`/`d` to the thirds) so they stay bare-key.

Because the WM layer only emits these chords while its thumb is held, nothing
here collides with:

- **nvim** `Ctrl+hjkl` splits — use **left** Ctrl (`D`) + tap `h/j/k/l`.
- **zellij** mode keys `Ctrl+g/p/t/n/h/s/o` — Ctrl (`D` or `K`) + home-row letter.
- **zsh** `Ctrl+a/e/r/f`, Alt word-motions — home-row Ctrl/Alt + letter.

---

## 4. Home-row mods — tuning

Home-row mods have a learning curve (accidental mods on fast rolls). In Vial,
tune under **Layout → tap-hold** / **QMK Settings**:

- **Tapping term** ≈ 180–200 ms to start; lower once comfortable.
- Enable **Permissive Hold** and **Hold On Other Key Press** for snappier mods.
- Consider **Chordal Hold** / per-key tapping term if same-hand rolls misfire.

Too fiddly? In Vial, swap any `X/m` back to a plain letter in seconds — the base
letters are unchanged, you only drop the hold behaviour.

---

## 5. Encoder

Configure in Vial (**Layout → encoder**). Sensible default:

- **Rotate** → `Vol-` / `Vol+`  ·  **Press** → `Mute` (or `Play/Pause`).

For per-layer encoder behaviour (e.g. scroll on BASE, volume on MEDIA) you need
the local QMK build — it lives in `keyboards/cheapino/encoder.c`, not the keymap.

---

## 6. QMK local build (full control)

Vial covers everything above. Build from source only if you want custom C
(encoder logic, per-key RGB). Per the upstream firmware guide:

```sh
qmk setup                                             # once
cd $(qmk config user.qmk_home | cut -d= -f2)          # into qmk_firmware
git remote add tompi https://github.com/tompi/qmk_firmware
git fetch tompi cheapinov2
git checkout tompi/cheapinov2

# drop this repo's keymap in and flash
mkdir -p keyboards/cheapino/keymaps/surajp
cp ~/dotfiles/cheapino/keymap.json keyboards/cheapino/keymaps/surajp/keymap.json
qmk flash -kb cheapino -km surajp
# when it says "Waiting for drive to deploy": hold BOOT + tap RESET on the RP2040
```

Notes:

- To edit visually at <https://config.qmk.fm>, temporarily set `"keyboard"` to a
  mainline 3×5+3 board (e.g. `bastardkb/skeletyl`); compile locally as `cheapino`.
- If `qmk compile` rejects `QK_BOOT`, use the older `RESET` keycode.

---

## 7. References

- Cheapino: <https://github.com/tompi/cheapino> (`doc/firmware.md`, troubleshooting)
- Miryoku: <https://github.com/manna-harbour/miryoku>
- Home-row mods: <https://precondition.github.io/home-row-mods>
- getreuer's QMK tricks: <https://getreuer.info/posts/keyboards/tour/index.html>
- Vial: <https://get.vial.today> · <https://vial.rocks>
