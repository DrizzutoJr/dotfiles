# Change Log

## [0.1.1]

### Fixed

- The active editor tab rendered its label in white on the cream tab
  background, about 1.03:1. VS Code's modern tab bar defaults
  `modernTab.activeForeground` to `list.inactiveSelectionForeground`, and
  `tab.selectedBackground`, `modernTab.activeBackground` and
  `notebook.selectedCellBackground` to `list.inactiveSelectionBackground`.
  This theme sets those two to `#FFFFFF` and `#000000` for the explorer, so
  the explorer's selection styling leaked into the tab bar. Every tab surface
  is now pinned explicitly, along with breadcrumbs and the notebook cell
  background that shared the same derivation.

## [0.1.0]

Correctness and readability pass over the original Sublime Text port.

### Fixed

- Added the missing `publisher` field. The extension previously built with
  `Publisher="undefined"` and installed as `undefined_publisher.drizzutojr-candyland`.
- Repaired five rules that set a near-white foreground over a per-token
  background. VS Code does not render per-token backgrounds, so `Invalid`,
  `diff.header`, `diff.deleted`, `diff.changed` and `diff.inserted` were
  rendering at 1.02:1 -- effectively invisible. The intended background hue is
  now the foreground.
- Raised every token foreground to at least 3.0:1 against the background.
  31 of 48 were below that, and 40 were below 4.5:1. Hue and saturation are
  preserved; only lightness changed.
- `editor.lineHighlightBackground` (white at 5% alpha) and
  `editorWhitespace.foreground` (pale yellow at 10% alpha) were invisible on
  the cream background.
- `editor.inactiveSelectionBackground` was opaque `#ff66b8`, rendering louder
  than the 50%-alpha active selection. Both are now the same hue, with the
  active state stronger.

### Added

- `semanticHighlighting`, so language servers can color Go, Python and
  TypeScript. It defaults off when a theme does not declare it.
- Workbench colors for the terminal, lists and editor widgets, moved out of
  `vscode/settings.json`. As user-level `workbench.colorCustomizations` they
  applied to every theme; the extension is now self-contained.
- Diff and problem colors as `diffEditor.*` and `editor{Error,Warning,Info}.*`
  workbench keys.
- `license`, `repository` and `type` metadata.

### Removed

- 18 of 57 token rules that could never match. Nine set only a per-token
  background; the rest target Sublime-era scopes absent from every bundled VS
  Code grammar: all seven `sublimelinter.*` rules, `other.preprocessor.c`,
  `text source`, `text.html.ruby source`, `meta.constructor.argument.css`,
  `meta.preprocessor.at-rule`, `keyword.unit.css`, `variable.other.less`,
  `entity.other.less.mixin`, `meta.delimiter.method.period.coffee` and the
  Angular rules.
- Dead scopes pruned from rules whose remaining scopes are still live:
  `declaration.tag`, `declaration.sgml.html`, `declaration.xml-processing`,
  `doctype`, `meta.property-group` and `support.constant.named-color.css`.
- `findHighlight`, `gutterForeground` and `activeGuide` from the global
  settings entry. All three are Sublime-only keys that VS Code ignores.

## [0.0.2]

- Initial port from Sublime Text.
