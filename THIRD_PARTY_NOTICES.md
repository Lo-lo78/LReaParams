# Third-party licenses and notices

LReaParams itself: GNU General Public License version 3 only
(`LICENSE`, SPDX `GPL-3.0-only`). This statement covers code for which
LReaParams' author has the right to choose this license. It does not replace
notices applicable to third-party components.

## REAPER extension SDK headers (Cockos Incorporated)

The headers in `third_party/reaper-sdk/` originate from
https://github.com/justinfrankel/reaper-sdk, identified by the pinned commit
and SHA-256 checksums in `third_party/reaper-sdk/manifest.json`.
Their copyright and permissive conditions are preserved in the headers.
They allow use, modification and redistribution, with attribution of origin,
notice retention, and clear marking of modified versions. They are not
asserted to be GPL-licensed or owned by the LReaParams author.

## NSIS (Nullsoft Scriptable Install System)

The installer is built using NSIS. The NSIS installer engine and the zlib
compression module used here are distributed under the zlib/libpng license,
not GPLv3. See the official NSIS license:
https://nsis.sourceforge.io/Docs/AppendixI.html

The installer uses `SetCompressor zlib` to avoid packaging NSIS's LZMA
module (which carries separate license terms).

## REAPER

REAPER is a separate application from Cockos, not shipped with this
installer. LReaParams is an independent extension and is not presented as an
official Cockos product.
