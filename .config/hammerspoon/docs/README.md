# Hammerspoon window manager documentation

Docs for the hand-rolled Hammerspoon window manager. Organised Johnny Decimal
style: area **10–19 "Hammerspoon window manager"**, one category per topic.

Start at [Getting started](11.01-getting-started.md), or jump to a topic.

| ID | Doc | Contents |
|----|-----|----------|
| 11.01 | [Getting started](11.01-getting-started.md) | Install, Accessibility permission, first launch |
| 12.01 | [Architecture & configuration](12.01-architecture-and-configuration.md) | Module layout, load order, config dir, tunables |
| 13.01 | [Keybindings](13.01-keybindings.md) | Window-mode modal reference |
| 14.01 | [Window operations](14.01-window-operations.md) | Halves, thirds, quarters, maximize, center, grow/shrink |
| 15.01 | [Multi-display](15.01-multi-display.md) | Move to display, focus across screens, unplug/replug |
| 16.01 | [Reload & lifecycle](16.01-reload-and-lifecycle.md) | Auto-reload, autostart, dock/menubar |
| 17.01 | [Troubleshooting](17.01-troubleshooting.md) | Common problems and fixes |

---

Conventions used in these docs:

- **Window mode** = the sticky modal entered with `Cmd+Ctrl+Space`; keys inside
  it are written bare (`h`, `[`, `Tab`).
- Paths are relative to `~/.config/hammerspoon` unless absolute.
- IDs follow Johnny Decimal (area 10–19, `category.ID`); add `11.02`, `14.02`,
  etc. to extend a topic without renumbering.

[Back to dotfiles README](../../../README.md)
