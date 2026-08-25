# Key UI tests

Runs `voidhub-key-ui.luau` outside Roblox against a fake `game` / `Instance` /
`Enum` environment, so the redeem flow, auto-login, failure handling and window
dragging can be exercised without an executor.

```sh
sh tests/key-ui/run.sh          # needs `luau` on PATH
LUAU=/path/to/luau sh tests/key-ui/run.sh
```

## Layout

| Path | Purpose |
| --- | --- |
| `shim.luau` | Fake Roblox API: instances, signals, tweens, a cooperative `task` scheduler, a fake executor filesystem and clipboard, plus the `check` / `report` helpers. |
| `bridge.luau` | Exposes the UI chunk's top-level locals (`auth`, `sanitizeKey`) to the assertions. |
| `cases/<name>/setup.luau` | Optional, runs *before* the UI: seeds a saved key, decides how the loader behaves. |
| `cases/<name>/check.luau` | Assertions, run after the UI has loaded. |

Each case is concatenated into a single chunk — `shim + setup + UI + bridge +
check` — so the UI file is executed exactly as shipped, with nothing stubbed
inside it.

## Cases

- **redeem** — empty input, failure classification, key sanitising, the rule
  that a key is only written to disk after it is accepted, gateway/paste
  buttons, and a successful redeem.
- **autologin-valid** — a saved key validates on boot and the window closes
  itself.
- **autologin-expired** — a saved key is rejected, gets removed from disk, and
  the window stays usable with the key left in the box.
- **dragging** — the window follows the pointer, stays clamped on screen, and
  stops when the mouse is released away from the title bar.

## Limits

The shim is not a renderer. It does not lay anything out, so it cannot catch
visual regressions, invalid property names, or `AutomaticSize` mistakes — those
still need a real client.
