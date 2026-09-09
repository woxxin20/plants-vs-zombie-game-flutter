# Bundled fonts

Sourced from the Google Fonts repository, `ofl/` tree, on 2026-09-09.
All three are **SIL Open Font License 1.1**; the full licence text ships next to
each family as `OFL-<Family>.txt`, which is what the OFL requires when a font is
redistributed inside an application.

| File | Family | Axes | Size | Licence |
| --- | --- | --- | --- | --- |
| `Orbitron.ttf` | Orbitron | `wght` 400-900 | 38,576 B | OFL 1.1 |
| `Inter.ttf` | Inter | `opsz`, `wght` 100-900 | 876,576 B | OFL 1.1 |
| `JetBrainsMono.ttf` | JetBrains Mono | `wght` 100-800 | 187,208 B | OFL 1.1 |

Total 1,102,360 B. These are **variable** fonts, so one file covers every weight
the design tokens ask for — declaring nine static faces would cost several times
this. Flutter renders the default instance for a bare `fontWeight`; if a weight
ever looks wrong, reach for `FontVariation('wght', n)` rather than adding files.

ADR-005 forbids `google_fonts` because the product must work in airplane mode.
These files are bundled, not fetched. Do not add the package.

Closes `ARCH-Q-001` and `AUD-002`.
