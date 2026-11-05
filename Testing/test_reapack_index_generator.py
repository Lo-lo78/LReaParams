"""Offline checks for the LReaParams ReaPack XML generator (no internet)."""

import importlib.util
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / "Tools" / "generate_reapack_index.py"
spec = importlib.util.spec_from_file_location("generate_reapack_index", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class ReaPackIndexTests(unittest.TestCase):
    @staticmethod
    def release(tag, dll=True, draft=False, prerelease=False):
        assets = [{"name": "LReaParams-Setup.zip",
                   "browser_download_url": "https://example.org/installer.zip"}]
        if dll:
            assets.append({
                "name": "reaper_lreaparams.dll",
                "state": "uploaded",
                "browser_download_url": (
                    f"https://github.com/Lo-lo78/LReaParams/releases/"
                    f"download/{tag}/reaper_lreaparams.dll"
                ),
            })
        return {
            "tag_name": tag,
            "assets": assets,
            "draft": draft,
            "prerelease": prerelease,
            "published_at": "2026-11-03T18:47:00Z",
            "body": "FX & Track: Improved <group>\nSecond line",
        }

    def test_index_version_detection_links_and_windows_file_paths(self):
        releases = [
            self.release("v0.0.64"),
            self.release("v0.0.61", dll=False),
            self.release("v0.0.63"),
            self.release("v0.0.65-rc1"),
            self.release("v0.0.66", prerelease=True),
        ]
        def files(tag):
            return ["Guide/index.html", "Guide/it/index.html",
                    "Guide/LReaParams - FX Params.html"]

        versions = mod.release_versions(releases, files)
        self.assertEqual([r["version"] for r in versions], ["0.0.63", "0.0.64"])
        root = ET.fromstring(mod.build_index(versions, mod.DEFAULT_REPO))
        self.assertEqual(root.attrib["version"], "1")
        pkg = root.find("./category/reapack")
        self.assertEqual(pkg.attrib["type"], "extension")
        vlist = pkg.findall("version")
        self.assertEqual([v.attrib["name"] for v in vlist], ["0.0.63", "0.0.64"])
        for v in vlist:
            sources = v.findall("source")
            self.assertEqual(len(sources), 4)
            self.assertEqual(sources[0].attrib["file"], "reaper_lreaparams.dll")
            self.assertEqual(sources[0].attrib["platform"], "win64")
            self.assertTrue(all(s.attrib["platform"] == "win64" for s in sources))
            self.assertTrue(all(".zip" not in (s.text or "") for s in sources))
            self.assertIn("Guide/index.html",
                          [s.attrib["file"] for s in sources])
            self.assertTrue(any("LReaParams%20-%20FX%20Params.html" in (s.text or "")
                                for s in sources))
            self.assertIn("Improved <group>", v.findtext("changelog"))

    def test_skips_unavailable_dll_and_prerelease(self):
        versions = mod.release_versions([
            self.release("v0.0.63", dll=False),
            self.release("v0.0.64", prerelease=True),
            self.release("v0.0.65", draft=True),
        ], lambda tag: ["Guide/index.html"])
        self.assertEqual(versions, [])

    def test_guide_directory_is_required_for_release(self):
        with self.assertRaises(ValueError):
            mod.release_versions([self.release("v0.0.63")],
                                 lambda tag: (_ for _ in ()).throw(ValueError("Guide/index.html is missing")))


if __name__ == "__main__":
    unittest.main()
