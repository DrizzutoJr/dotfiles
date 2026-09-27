# Drizzutojr Candyland

A light VS Code color theme on a `#fdf6e3` cream background, ported from the
Sublime Text Candyland theme.

## Building

The theme ships as a committed `.vsix` next to this directory. Packaging is a
manual step -- `vscode/macos_setup.sh` only installs the newest `.vsix` it
finds, it never builds one.

After changing `themes/Drizzutojr Candyland-color-theme.json`:

1. Bump `version` in `package.json`.
2. Add a `CHANGELOG.md` entry.
3. Repackage, writing the `.vsix` one level up:

   ```bash
   cd vscode/extensions/drizzutojr-candyland/package
   vsce package --out ../
   ```

4. Delete the superseded `.vsix` so only the current one is committed.
5. Install it:

   ```bash
   code --install-extension ../drizzutojr-candyland-<version>.vsix --force
   ```

`vsce` comes from Homebrew and is listed in `homebrew/brew_packages.yaml`.

## Design constraints

Two rules keep the theme readable and self-contained. Both were violated by the
original Sublime port.

**Every token foreground clears 3.0:1 against the background.** The source
palette was tuned for a dark background; dropped onto cream, most of it fell
below 2.5:1. Colors were corrected by lowering lightness while holding hue and
saturation, so the palette still reads as Candyland.

**VS Code renders only `foreground` and `fontStyle` from `tokenColors`.**
Per-token `background` is silently ignored, so anything needing a background --
diffs, errors, selections -- belongs in the `colors` block as a workbench key.

Workbench colors live here rather than in `vscode/settings.json`. A
`workbench.colorCustomizations` block in user settings applies to every theme,
not just this one.
