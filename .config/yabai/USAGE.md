# Desktop usage guide: yabai, skhd, the bar and the rice

Everything here runs with SIP on. The modifier for every window-manager key is
**Cmd+Ctrl** (the cheapino keyboard's WM layer emits it). Paths are relative to
`~/.config`.

## 1. Concepts

- **Space** = a macOS desktop. yabai numbers them per Mission Control order
  (1, 2, 3 on the main display, 4 on the portrait one). Numbers stay put because
  "rearrange Spaces by most recent use" is off.
- **Tiling**: every Space is `bsp` by default: a new window splits the focused
  window's area. `stack` puts all windows in one frame; `float` leaves them alone.
- **Focus** follows the keyboard, not the mouse. The focused window has a
  coloured border (JankyBorders) and its app shows in the bar.
- **Window mode** = a sticky key layer in skhd: press Cmd+Ctrl+Space once, then
  single keys act on windows until you press Esc or q. The bar shows a WINDOW
  badge while it is on.

## 2. Everyday keys (hold Cmd+Ctrl)

| Keys | Does |
|------|------|
| h / j / k / l | focus the window west / south / north / east, crossing to the other display at the edge |
| Tab / Shift + Tab | focus the next / previous window on the Space, floating ones included |
| ` (grave) | focus a floating window on the Space (press again to cycle through them) |
| n / p | next / previous window in a stack (windows sharing one frame: Ghostty tabs, the portrait display's overflow) |
| 1 … 6 | go to Space N |
| Shift + 1 … 6 | send the focused window to Space N and follow it |
| m | zoom the focused window to fill the Space (again to undo) |
| f | float / unfloat the window, centred at half size |
| e | open the emoji & symbols picker (macOS's own Cmd+Ctrl+Space is taken by window mode; the Globe key works too) |
| d | show / hide the Dock (it auto-hides; it also peeks out at the bottom edge) |
| r | restart yabai (re-reads `yabai/yabairc`) |
| Space | enter **window mode** |

## 3. Window mode (after Cmd+Ctrl+Space, then bare keys)

| Key | Does |
|-----|------|
| h j k l | move (warp) the window in that direction |
| Shift + h j k l | swap with the window in that direction |
| Ctrl + h j k l | choose where the *next* window opens |
| - / = | shrink / grow the window by 5% |
| 0 | equalise all windows on the Space |
| m / p | zoom to the Space / zoom to the parent area |
| f | float + centre; c = centre a floating window |
| y u b n | snap a floating window to a quarter (top-left, top-right, bottom-left, bottom-right) |
| s | flip the split direction of the window's node |
| Alt + h j k l | stack the window onto the neighbour in that direction (put it back into a stack) |
| e | eject the window from its stack into a tile of its own |
| r | rotate the layout 90°; x / v mirror it |
| t | cycle the Space layout bsp → stack → float |
| Tab / Shift+Tab | move the window to the next / previous display |
| 1 … 6 | send the window to Space N and leave the mode |
| Esc or q | leave the mode |

### Floating windows

- **Float / unfloat**: Cmd+Ctrl+f (or `f` in window mode). A tiled window comes
  out of the layout centred at half the screen; a floating one goes back into the
  tiling. In window mode, `c` re-centres a floating window and `y` `u` `b` `n`
  snap it to a quarter of the screen.
- **Move / resize by hand**: hold fn and drag with the left button to move, the
  right button to resize. Works on tiled windows too (dropping one onto another
  swaps them).
- **Finding one that went behind the tiles**: Cmd+Ctrl+` (grave, above Tab) jumps
  to a floating window on the Space and cycles through them on repeat;
  Cmd+Ctrl+Tab / Shift+Tab walk every window, tiled and floating, in a fixed
  order. h/j/k/l can't do it: they look in a direction, and a covered window has
  none. Once focused, a floating window stays above the tiles until you focus a
  tile again.
- Windows without an accessibility handle (Bitwarden) are skipped by both keys,
  since yabai cannot focus them; use the Space pill in the bar or Cmd+Tab.
- On the portrait display, unfloating counts as a window arriving: with three
  rows already there it joins a stack.

Mouse: hold **fn** and drag with the left button to move any window, right
button to resize. Dropping a tiled window on another swaps them.

## 4. The bar (SketchyBar, part of the rice)

Left to right, one bar per display:

- **Theme picker**: the logo at the far left shows the active theme; click it
  for a menu of every theme alias and switch from there.
- **Space pills**: only the Spaces on that display, with the icons of the apps
  on each. The highlighted pill is the visible Space. Click a pill to go there.
- **Front app**: icon and name of the focused app. **Click it** for Hide / Quit /
  Force quit. This is the replacement for right-clicking a Dock icon.
- **Stack cue**: appears next to the front app only when the focused window has
  others stacked behind it (Ghostty tabs, the portrait display's overflow):
  "2/3" and the hidden windows' names. Click it for the next one in the stack.
  (A tab strip drawn over the window was tried and dropped: it covered the
  apps' own toolbar buttons.)
- **Now playing** (centre): the track Noctis is playing, click to play/pause,
  hover for album, position and previous/next. Needs Noctis's Local API on:
  Noctis > Settings > Account & Devices > Local API.
- **WINDOW badge** (centre): shown while skhd is in window mode.
- **Status cluster**: CPU graph (click: top processes, load, uptime), memory
  graph (click: top processes by memory), network down/up rates with a download
  graph (click: interface and IP), disk used (click: mounted volumes), volume (click for a
  slider), battery (laptops only), clock (click for this month's calendar).

A portrait display (taller than wide) gets a slim bar: theme, its Space pills,
front app, volume, battery and clock; the graphs, disk and now-playing items stay
on the wide displays (`plugins/layout.sh`, re-run on every display change).

Colours come from the active theme. `sketchybar --reload` re-reads
`sketchybar/sketchybarrc` after an edit.

## 5. Themes and the rice

```sh
theme list                 # all aliases, dark and light
theme gruvbox              # terminal + bar + borders + wallpapers + accent + apps
theme toggle               # dark <-> light defaults
theme preview dracula      # this terminal window only; `theme revert` undoes it

~/.config/rice/rice.sh status       # what is applied, wallpaper flavour per Space
~/.config/rice/rice.sh apply        # re-render the desktop for the current theme
~/.config/rice/rice.sh style pixel  # pixel-art wallpapers (style smooth to go back)
~/.config/rice/rice.sh style shuffle # new random scene on every Space (shuffle-pixel too)
~/.config/rice/rice.sh wallpapers   # render every flavour and open them in Preview
~/.config/rice/rice.sh noctis-plugin # Noctis follows the theme live (one-time build, needs `brew install dotnet`)
~/.config/rice/rice.sh uninstall    # restore every macOS setting the rice touched
```

`theme <name>` is the only switch: the rice re-applies itself in the background
afterwards (log: `~/.local/state/rice/apply.log`). Chrome and Discord need a
restart to pick up new colours; Firefox is themed only when `rice.sh apply`
runs from a real terminal. Noctis gets the theme as a content pack named "Rice"
(Settings > Appearance > Themes); with the reloader plugin installed and approved
once under Settings > Plugins, it recolours the moment `theme` runs.

## 6. Working with each tool

Where things live, how to change them, how to see what they are doing. All
config files are symlinks into `~/dotfiles`, so editing in place edits the repo.

### yabai (window manager) — `yabai/yabairc`

`yabairc` is a shell script: every line is a `yabai -m ...` message you can also
type in a terminal to try live. Cmd+Ctrl+R re-runs the whole file.

```sh
yabai -m config layout stack                 # try a setting now (not persisted)
yabai -m config --space 3 layout float       # per-Space override
yabai -m rule --add app="^Calculator$" manage=off   # float an app; add to yabairc to keep
yabai -m rule --list | jq                    # what rules are active
yabai -m query --windows --window | jq       # the focused window: app, title, role, frame...
yabai -m query --windows --space 2 | jq '.[] | {app,title}'
yabai -m query --spaces | jq                 # Spaces, their display and windows
yabai -m signal --add event=window_created action='...'   # run a script on events
yabai -m config debug_output on              # narrate every event into /tmp/yabai_<user>.out.log
```

Finding the right rule for a misbehaving window: focus it, run the first `query`
line above and look at `app`, `title`, `role`, `subrole`. Rules match those with
regexes; `title!=` / `app!=` invert a match. Rules only apply to windows that
appear after they are added; `yabai -m rule --apply` retro-fits them.

Helpers in `yabai/`: `focus-space` (Space switching), `focus-cycle` (focus through floating windows), `native-tab` (tab
stacking), `tall-display` (portrait-display rules), `verify-managed` (startup self-check). Each has its reasoning in a
header comment.

**The portrait display.** A display taller than it is wide only has room for a
column, so `tall-display` applies two rules to every Space on it (checked by
display shape at run time, so the 4K display is untouched and a rotated panel
reverts): windows split into rows, one above the other (a / b / c top to
bottom), never side by side, and the rows always share the height equally (bsp
alone would give 1/2, 1/4, 1/4); and there are at most three rows. A fourth window
is stacked onto a row instead of opening a fourth row: it joins the row you were
in when it opened, otherwise the row holding the fewest windows. If a Space ends
up over the limit anyway (a window dragged over with fn, or ejected), the next
change there (a window opening, closing or minimizing) stacks the extra rows
back, the focused one first. Cmd+Ctrl+n / p
walk the stack, window-mode `e` ejects a window from it and Alt+h/j/k/l puts the
focused window onto a neighbour's stack (or starts one). The bar shows a stack
cue next to the app name whenever the focused window has others behind it:
"2/3" plus the hidden windows' names; click it for the next one. The cap runs when a
window is created and after the keys that move a window between Spaces or
displays (Cmd+Ctrl+Shift+N, window mode Tab / 1…6). Change the limit with
`YABAI_MAX_TILES` or `MAX_TILES` in the script; `tall-display fit` re-applies the
limit and equal heights by hand; `TALL_DRY=1 tall-display cap focused` shows what it would do; it
logs to `~/.local/state/yabai/tall-display.log`.

### skhd (hotkeys) — `skhd/skhdrc`

```
mod - key : command            # one binding
:: name  : command             # declare a mode; the command runs when entering it
mod - key ; name               # a key that switches into a mode
name < key : command           # a binding only active inside that mode
name < escape ; default        # leave the mode
```

Modifiers: `cmd alt ctrl shift fn`, joined with `+`. Keys: letters, digits,
`space tab return escape backspace` or a hex keycode like `0x18`. Edit, then
`skhd --reload`. `skhd -o` prints the name of every key you press, to find
what to write. Bindings fail silently; `/tmp/skhd_<user>.err.log` has the
error from the command that ran.

### SketchyBar (the bar) — `rice/.config/sketchybar/`

- `sketchybarrc` builds the bar: bar geometry, item defaults, then every item.
  Items are added right-to-left on the right side (first added = rightmost).
- `plugins/*.sh` are the scripts items run. SketchyBar calls them with `NAME`
  (the item), `SENDER` (which event fired) and `INFO` (event payload), and they
  push state back with `sketchybar --set "$NAME" label=... icon=...`.
- Colours arrive from `~/.local/state/rice/palette.sh` as `RICE_*_0X` values
  (`0xAARRGGBB`); never hard-code a colour, read a variable so themes keep working.

```sh
sketchybar --reload                           # re-read sketchybarrc after an edit
sketchybar --query bar | jq .items            # what exists
sketchybar --query clock | jq                 # one item's full state
sketchybar --set clock label="hi"             # poke an item live
sketchybar --trigger mode_change MODE=window  # fire a custom event by hand
tail -f /opt/homebrew/var/log/sketchybar/sketchybar.err.log   # plugin errors
```

Adding an item, in `sketchybarrc`:

```sh
sketchybar --add item uptime right \
           --set uptime icon="󰔟" update_freq=60 script="$PLUGIN_DIR/uptime.sh"
```

and `plugins/uptime.sh`: `sketchybar --set "$NAME" label="$(uptime | sed 's/.*up //; s/,.*//')"`.
Add the name to the `status` bracket line to put it inside the pill. Icons are
Nerd Font glyphs (Maple Mono NF); app glyphs come from sketchybar-app-font via
`~/.local/state/rice/bin/icon_map.sh "App Name"`. Popups: add items to
`popup.<parent>` and toggle with `--set <parent> popup.drawing=toggle`; the
plugins close them on `mouse.exited.global`.

Testing a popup from a script needs the pointer on the item (the exit handler
closes it otherwise). Items hidden with `drawing=off` get no events unless they
set `updates=on`.

### JankyBorders (focus border) — `rice/.config/borders/bordersrc`

A shell script of `borders key=value` settings run at start; the rice overrides
the two colours live on every theme. `brew services restart borders` after an
edit. Settings: `width`, `style=round|square`, `active_color`, `inactive_color`,
`hidpi`.

### Wallpapers — `rice/.config/rice/wallpaper.py`

```sh
uv run ~/.config/rice/wallpaper.py ~/.local/state/rice/palette.json /tmp/x.png 1504 846 dunes
```

renders one flavour at any size (quarter 4K here, fast) for previewing. A flavour
is a function `name(c)` that returns a PIL image from `c.w, c.h` (canvas),
`c.bg, c.fg, c.accent, c.tints` (palette), `c.rng` (seeded), `c.s` (stroke scale)
and `c.pixel` / `c.portrait` flags; register it in the `FLAVOURS` dict and in
`FLAVOURS_SMOOTH` / `FLAVOURS_PIXEL` in `rice.sh`. The six mathematical flavours
(harmonograph, attractor, julia, chladni, spirograph, interference) use numpy only
and `math_base()` for a cheap background gradient. Helpers: `gradient`, `ribbon`
(variable-width stroke), `ring`, `jagged` (needs 2^k+1 points), `stars`. Pixel
variants come for free; keep strokes ≥ 1 cell and skip soft glows when `c.pixel`.
Rendered files are cached in `~/.local/state/rice/wallpapers/`; delete a file to
force a re-render.

### Themes and app skins — `rice/.config/rice/`

`ricelib.py` turns the Ghostty theme into `palette.{sh,json,css}` and renders
`templates/` (Firefox userChrome, Vencord, Übersicht widgets) by substituting
`{{BG}}`, `{{ACCENT}}`... placeholders (any palette key). Add a template, add a line in `rice.sh apply` that
renders it to its destination, and it follows every theme. `rice.sh install`
snapshots every macOS setting it changes; `uninstall` restores them, so it is
safe to experiment.

**Noctis.** `templates/noctis-theme.json` is a Noctis *content pack* theme: `base`,
`accent` and the colour keys Noctis lets packs set (see its docs/PLUGINS.md,
"Content packs"); anything left out Noctis derives itself. `apply` renders it into
`~/Library/Application Support/Noctis/plugins/rice.theme/`. Noctis only re-reads
packs when it starts, so `noctis/reloader` is a ~100-line Noctis plugin that
watches that folder and asks Noctis to re-read the pack, which recolours live.
`rice.sh noctis-plugin` builds it against the installed Noctis.app and installs it;
restart Noctis once and approve "Rice theme reloader" under Settings > Plugins.
The first time the pack appears it also selects the Rice theme for you; after
that your own pick in Settings wins. While Rice is the active theme, each reload
re-selects it, because Noctis only takes a theme's accent on selection.

### Übersicht (desktop widgets) — `rice/.config/rice/templates/ubersicht-*.jsx`

Rendered to `~/Library/Application Support/Übersicht/widgets/` on apply: a
calendar card and big clock bottom-left, a glass system card bottom-right (cpu
sparkline, cpu/mem/disk bars, network, uptime, load) and above it a Noctis
now-playing card with the cover, shown only while something is loaded. They sit
on the desktop, so you see them on an empty Space or around floating windows.
`open -b tracesOf.Uebersicht` starts it (the umlaut breaks `open -a`).

## 7. When something is off

| Symptom | What is happening | Do |
|---------|-------------------|----|
| Cmd+Ctrl+N does nothing for one Space | yabai dropped a window at startup (`could not locate window` in `/tmp/skhd_<user>.err.log`) | `verify-managed` restarts yabai once automatically; otherwise Cmd+Ctrl+R |
| A floating window disappeared behind a tile | h/j/k/l only look in a direction and a covered window has none | Cmd+Ctrl+` jumps to the floating window (again to cycle); Cmd+Ctrl+Tab steps through all windows |
| Ghostty shrinks to half after Cmd+T | native tabs are separate windows | `native-tab` stacks them; check `~/.local/state/yabai/native-tab.log` |
| A new window on the portrait display vanished | it became the fourth row and was stacked onto an existing one | the bar's stack cue ("2/3 …") names it; Cmd+Ctrl+n cycles the stack; `~/.local/state/yabai/tall-display.log` says which row took it |
| A dialog is tiled and its content is off screen | the app draws dialogs as a full-size overlay window (Avalonia apps like Noctis) | add `yabai -m rule --add app="^App$" title!="^App$" manage=off` to `yabai/yabairc` |
| Bar items stale or missing | plugin error | `sketchybar --reload`; errors in `/opt/homebrew/var/log/sketchybar/sketchybar.err.log` |
| Wallpapers unchanged after `theme` | displays were asleep during apply | `~/.config/rice/rice.sh apply` |
| Noctis kept its old colours | the reloader plugin is missing, not approved, or Noctis's internals changed | Settings > Plugins: approve "Rice theme reloader" and read its log; or restart Noctis, which re-reads the pack |
| Everything stopped after a display sleep | yabai's queries return nothing while displays are off | wake the displays, then Cmd+Ctrl+R if needed |

Logs: `/tmp/yabai_<user>.out.log`, `/tmp/skhd_<user>.err.log`,
`/tmp/yabai_verify_<user>.log`. `yabai -m config debug_output on` makes yabai
narrate every event into its out log.
