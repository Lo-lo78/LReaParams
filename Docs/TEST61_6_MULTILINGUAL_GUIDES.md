# TEST61.6 — Multilingual guide launcher and localized manuals (source-only)

- Added REAPER Main action `LReaParams: Open User Guide` with a stable command ID `LREAPARAMSOPENUSERGUIDE` and an entry in Extensions > LReaParams. The action opens the default browser via ShellExecuteW (Windows). No navigator/audio logic is changed.
- It prefers the offline REAPER resource directory `LReaParams/Guide/index.html`. Compatible fallbacks: `UserPlugins/Guide/index.html` and `Guide/index.html`. A clear Windows message explains installation if the index is absent; a separate message handles browser launch failure.
- Language selector first: English, Italian, Spanish, French, Russian, Simplified Chinese and Japanese. Each choice offers FX Params and Track Params. Language switching is available on every page through ordinary HTML links.
- Two English manuals from TEST61.5 are retained in full. Twelve **concise translated functional guides** provide native-language page descriptions and shortcut tables, with a link to each full-length English manual. They are not claimed to be exact full translations of TEST61.5.
- `Guide/INSTALL.txt` explains where to put DLL and Guide. GitHub Actions retains its original standalone DLL artifact; adds a ready-to-install artifact with UserPlugins and LReaParams/Guide plus a separate complete Guide artifact.
- Static test validates action registration, localized index pages, navigation, local links and all anchors. No C++, REAPER or NVDA runtime build/test was executed here; the real MSVC build remains in GitHub Actions.
