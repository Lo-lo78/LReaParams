# TEST61.7 — Fix historic static tests after multilingual guide action

## Failure observed on GitHub Actions

The Windows workflow stopped on the source-only step `Testing/test27_static.py` with:

```text
assert 'F12 alone is reserved' in (root/'src/Extension.cpp').read_text()
AssertionError
```

The change to About in TEST61.6 had shortened this to `Bare F12 reserved`. The behavior of F12 had not changed: unmodified F12 remains reserved, while Ctrl+F12 addresses memory slot 12.

## Fixes

1. `src/Extension.cpp`: use `F12 alone is reserved` in About, preserving the meaning and the old static contract.
2. `Testing/test42_static.py`: verify that `stopBackgroundMidi` is still in the `ActionIndex` enum and its case exists, without assuming that this action must be the last entry immediately before `actionCount`. That assumption became obsolete when `openGuide` was appended in TEST61.6.

The action IDs, keyboard shortcuts, accessibility behavior, DLL functionality, seven offline languages, and packaging layout are unchanged.

## Verification

All 83 `run: python ...` checks declared by `.github/workflows/build-windows.yml` passed (source-only). No local CMake configure/build, native tests, DLL build, or REAPER/NVDA runtime verification was performed. GitHub Actions is responsible for the MSVC build.
