# dotfiles

Personal macOS terminal configuration, managed with **GNU Stow**.

A fast, hacker-flavored **zsh** setup built around **Homebrew**, **Starship**,
**Ghostty**, **neovim**, and modern Rust/Go CLI tools - with vim mode, a custom
prompt HUD, and a live light/dark colorscheme switcher.

## Layout

The repo mirrors `$HOME`. Stow symlinks each tracked file into place, leaving every
other file in `~/.config` (other apps, caches, state) untouched.

```
dotfiles/
|-- install.sh            one-shot bootstrap (brew -> stow -> setup)
|-- .gitignore
|-- pi/                   SEPARATE stow package: pi agent config (see below)
|-- rice/                 SEPARATE stow package: desktop rice, opt-in (see below)
|   `-- .pi/agent/        settings, agents, prompts, extensions, skills
`-- .config/
    |-- Brewfile          every package / cask / font (declarative)
    |-- starship.toml     the prompt
    |-- ghostty/config    terminal emulator
    |-- nvim/             neovim config + docs
    |-- yabai/            tiling window manager (yabairc + focus-space helper)
    |-- skhd/             hotkeys that drive yabai
    `-- zsh/              the shell config + docs + installer
```

`pi/` is its own stow package, deliberately kept out of the root `stow .` (it is
listed in `.stow-local-ignore`). See [pi agent](#pi-agent) below.

After stow:

```
~/.config/zsh/.zshrc      -> ~/dotfiles/.config/zsh/.zshrc      (symlink)
~/.config/starship.toml   -> ~/dotfiles/.config/starship.toml   (symlink)
...                          (runtime files like plugins/ stay real, untracked)
```

## Install on a new machine

```sh
git clone <this-repo> ~/dotfiles
~/dotfiles/install.sh          # installs Homebrew + stow, symlinks configs, installs everything
exec zsh
```

`install.sh` is idempotent: it installs Homebrew and Stow if missing, symlinks the
configs (`stow`), then runs `setup_zsh.sh` (all CLI tools, fonts, Ghostty, the
`fzf-tab` plugin, and the `~/.zshenv` bootstrap).

## Day-to-day

```sh
cd ~/dotfiles && stow --restow .   # re-link after adding new files
git add -A && git commit           # commits are SSH-signed
```

Edit configs in `~/.config/...` as usual - they are symlinks, so you are editing the
repo. New *files* need a `stow --restow .` to be linked.

## pi agent

The [pi](https://github.com/earendil-works) coding-agent config lives in its own
stow package, `pi/`, so it can be installed independently of the shell setup.
It tracks only *setup* — `settings.json`, `agents/`, `prompts/`, `extensions/`
(caveman, greeter, save-session, cockpit, gitlab, subagent) and `skills/`.

Secrets and machine state stay untracked and are **never** moved into the repo:
`auth.json`, `trust.json`, `models-store.json`, `sessions/`, `saved-sessions/`.
`~/.pi/agent` therefore stays a real directory; only the tracked children are
symlinked into it.

```sh
./install.sh pi     # set up ONLY the pi agent module (stow + pi runtime + link)
./install.sh        # full machine setup, which includes the pi module
cd ~/dotfiles && stow --restow pi   # re-link after adding pi files
```

**Cross-platform:** the full `./install.sh` is macOS-only (casks, fonts, IINA),
but `./install.sh pi` runs on **macOS and Linux**. It installs `stow`
(brew / apt / dnf / pacman / zypper) and the pi runtime (Homebrew
`pi-coding-agent`, or `npm i -g @earendil-works/pi-coding-agent` where only Node
is present), then symlinks the config. Note: the cockpit editor's clipboard
paste uses macOS `pbpaste`, so `p`/`P` from the system clipboard is mac-only;
everything else works on Linux.

## Documentation

- **zsh / terminal**: [`.config/zsh/docs/`](.config/zsh/docs/README.md) - getting
  started, architecture, tools, keybindings, navigation, prompt, themes, fonts,
  troubleshooting.
- **neovim**: [`.config/nvim/docs/`](.config/nvim/docs/README.md) - getting started,
  architecture, keymaps, plugins, LSP & languages, completion, navigation, git,
  theme sync, Neovide, troubleshooting.
- **yabai / skhd**: [`.config/yabai/yabairc`](.config/yabai/yabairc) and
  [`.config/skhd/skhdrc`](.config/skhd/skhdrc) - the tiling window manager and its
  hotkeys. Every line is commented in place; SIP stays enabled. Two helper scripts
  cover what yabai can't do alone without the scripting addition:
  `focus-space` (switch Spaces: yabai window focus, falling back to activating
  the app) and `native-tab` (keep Ghostty's native tabs in one tile instead of
  splitting it on every Cmd+T). `verify-managed` restarts yabai once if it
  dropped windows while starting, which is what used to make Space switching die
  until the next Cmd+Ctrl+R. Apps whose dialogs are full-size overlay windows
  (Noctis) get a `manage=off` rule for everything but their main window.
- **rice**: [`rice/.config/rice/rice.sh`](rice/.config/rice/rice.sh) - the opt-in
  desktop rice (SketchyBar, JankyBorders, generated wallpapers, Firefox/Chrome/
  Discord themes, Übersicht widgets), all rendered from the active `theme`. See
  [Desktop rice](#desktop-rice) below.

## Desktop rice

`rice/` is a second stand-alone stow package, like `pi/`, and is **never** part of
the full install. It themes the whole desktop from the same `theme <name>` command
that already drives the terminal, and it is built to be removed cleanly.

```sh
./install.sh rice                  # or: rice/.config/rice/rice.sh install
~/.config/rice/rice.sh status      # incl. which wallpaper flavour each Space got
~/.config/rice/rice.sh wallpapers  # render every flavour (smooth + pixel) and open them in Preview
~/.config/rice/rice.sh style pixel # switch every Space to the pixel-art set (style smooth to go back)
~/.config/rice/rice.sh uninstall   # restore every macOS setting, remove rendered files, unstow
~/.config/rice/rice.sh purge       # uninstall + brew uninstall the rice packages + delete state
```

How it works: `theme <name>` writes the active Ghostty theme; `rice.sh apply`
(hooked at the end of `theme()`) parses that theme file with `ricelib.py` into
`~/.local/state/rice/palette.{sh,json,css}` and renders every surface from it:

| Surface | Tool | Where it lands |
|---------|------|----------------|
| menu bar | SketchyBar (`rice/.config/sketchybar`) | native bar auto-hidden; yabai reserves 36px |
| focused-window border | JankyBorders (`rice/.config/borders`) | live recolour on switch |
| wallpaper | `wallpaper.py` (Pillow + numpy, via `uv run`) | a different flavour on **every Space** of every display, written into macOS's wallpaper store; `~/.local/state/rice/wallpapers/<theme>-<flavour>-WxH.png` |
| macOS accent + dark/light | `defaults` / AppleScript | nearest Apple accent preset, highlight = exact accent |
| Firefox | `templates/firefox-userChrome.css` | every profile's `chrome/userChrome.css` + `user.js` flag |
| Discord | Vencord theme from `templates/vencord.theme.css` | `~/Library/Application Support/Vencord/themes/rice.theme.css` |
| Chrome | `BrowserThemeColor` policy | frame colour; Chrome shows a "managed" badge |
| widgets | Übersicht (`templates/ubersicht-*.jsx`) | clock + system stats on the desktop |

**Wallpapers.** Five flavours of generated line art, all from the theme's colours:
`ridges` (sine-sum mountains with meandering rivers), `contours` (a topographic map),
`strands` (a flowing bundle of curves), `waves` (stacked rolling lines) and `peaks`
(jagged silhouettes under a ringed moon), plus the same five scenes as retro pixel
art (`pixel-ridges` ... `pixel-peaks`: a ~212-cell grid, a small palette from the
theme, Bayer dithering, stars at night). Space 1 gets the first flavour, Space 2 the
second, and so on, wrapping around. `rice.sh style pixel|smooth` switches the whole
set and is remembered across theme changes; `rice.sh style ridges pixel-peaks` picks
an explicit list; `RICE_WALLPAPER_FLAVOURS` in the environment overrides both. Each
picture is rendered at the display's Retina size (the portrait 1080p panel gets its
own composition), supersampled 1.5x and Lanczos-downscaled so edges are
anti-aliased, with dithered gradients and a 1-LSB grain so dark skies never band;
then cached per theme, flavour and size. macOS
only lets scripts change the Space that is on screen, so `apply` writes the plan
straight into `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`
and restarts WallpaperAgent; new Spaces inherit their display's first flavour, and a
`rice.sh apply` picks them up. If the displays are asleep when `apply` runs, the
wallpaper step is skipped with a warning.

`install` snapshots every setting it touches to `~/.local/state/rice/snapshot.json`
first; `uninstall` restores from it (Dock, menu bar, accent, dark mode, Chrome
policy, Vencord's enabled themes) and swaps every rice wallpaper in the store back
for your previous one (aerials included; the untouched store is also kept as
`~/.local/state/rice/wallpaper-store.pre-rice.plist`). Rendered files carry a
`RICE-MANAGED` marker and only those are deleted.
