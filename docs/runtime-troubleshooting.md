# Runtime troubleshooting

## Theme integration

The hosted clipboard panel uses Omarchy's live `Color`, `Style`, and `Border`
tokens. The standalone fallback loads those tokens from the installed shell
under `$OMARCHY_PATH` (default: `/usr/share/omarchy`). It no longer reads
`~/.local/state/omarchy/clipboard-theme.json`; no extra theme hook is needed.

Panel content follows the menu palette, while the outer outline uses popup
border styling. The hosted panel uses Omarchy's native border renderer for
gradients and per-side widths; the standalone fallback uses a flat border.

If plugin changes are not visible, restart the shell to clear cached QML:

```sh
omarchy restart shell
```

Check the active theme and any theme/component errors:

```sh
omarchy theme current
journalctl --user -b --no-pager | rg 'iamcheyan.clipboard|ClipboardStyle|ClipboardThemeBridge'
```

This integration requires an Omarchy shell that provides the current
`qs.Commons` Color/Style/Border tokens and `qs.Ui.BorderOverlay`. Older shell
versions require compatibility testing. Nerd Font icons use Omarchy's configured
menu font; that font or its fontconfig fallback must include the icon glyphs.
