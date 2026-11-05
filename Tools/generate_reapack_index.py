#!/usr/bin/env python3
"""Create a ReaPack 1.x XML index from published GitHub releases.

Only stable releases with a standalone reaper_lreaparams.dll GitHub Release
asset are published. The installer ZIP/EXE stays untouched. Guides are sourced
from each release's *tagged source tree*, not from the moving main branch.

The DLL is installed by ReaPack into REAPER/UserPlugins.
All Guide/* files are installed into REAPER/UserPlugins/Guide.
LReaParams 0.0.63 already recognizes this directory for "Open User Guide".

Usage:
  GH_TOKEN=... python Tools/generate_reapack_index.py --output index.xml
  python Tools/generate_reapack_index.py --fixture Testing/reapack_fixture.json
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

DEFAULT_REPO = "Lo-lo78/LReaParams"
BINARY = "reaper_lreaparams.dll"
TAG_RE = re.compile(r"^v(\d+(?:\.\d+){2,3})$")
ALLOWED_GUIDE_EXTENSIONS = {
    ".html", ".htm", ".css", ".js", ".json", ".txt", ".svg",
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".ico",
}


def github_get(path, token, api_base="https://api.github.com"):
    url = api_base.rstrip("/") + "/" + path.lstrip("/")
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "LReaParams-ReaPack-Index",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_releases(repo, token):
    releases = []
    page = 1
    while True:
        chunk = github_get(
            f"repos/{repo}/releases?per_page=100&page={page}", token
        )
        if not isinstance(chunk, list):
            raise ValueError("GitHub API did not return releases list")
        releases.extend(chunk)
        if len(chunk) < 100:
            return releases
        page += 1


def guide_files(repo, tag, token):
    encoded_tag = urllib.parse.quote(tag, safe="")
    info = github_get(
        f"repos/{repo}/git/trees/{encoded_tag}?recursive=1", token
    )
    if info.get("truncated"):
        raise ValueError(f"Git tree unexpectedly truncated for {tag}")
    paths = []
    for entry in info.get("tree", []):
        name = entry.get("path", "")
        if (
            entry.get("type") == "blob"
            and name.startswith("Guide/")
            and not name.endswith("/")
            and Path(name).suffix.lower() in ALLOWED_GUIDE_EXTENSIONS
        ):
            paths.append(name)
    if "Guide/index.html" not in paths:
        raise ValueError(f"{tag}: missing mandatory Guide/index.html")
    return sorted(set(paths))


def release_versions(releases, trees):
    """Convert API records to verified XML-ready version descriptors."""
    result = []
    seen = set()
    for release in releases:
        tag = release.get("tag_name", "")
        match = TAG_RE.fullmatch(tag)
        if not match or release.get("draft") or release.get("prerelease"):
            continue
        binary_assets = [
            a for a in release.get("assets", [])
            if a.get("name") == BINARY
            and a.get("state", "uploaded") == "uploaded"
            and a.get("browser_download_url")
        ]
        if not binary_assets:
            print(f"Skipping {tag}: no standalone {BINARY} Release asset",
                  file=sys.stderr)
            continue
        if tag in seen:
            raise ValueError(f"Duplicate release tag {tag}")
        seen.add(tag)
        files = trees(tag)
        result.append({
            "tag": tag,
            "version": match.group(1),
            "asset_url": binary_assets[0]["browser_download_url"],
            "files": files,
            "time": release.get("published_at") or release.get("created_at") or "",
            "body": release.get("body", ""),
        })
    return sorted(result, key=lambda x: tuple(int(n) for n in x["version"].split(".")))


def build_index(versions, repo):
    root = ET.Element("index", {"version": "1", "name": "LReaParams"})
    category = ET.SubElement(root, "category", {"name": "Extensions"})
    pkg = ET.SubElement(category, "reapack", {
        "name": "LReaParams.ext",
        "type": "extension",
        "desc": "LReaParams - Accessible FX and Track Parameters (Windows x64)",
    })
    metadata = ET.SubElement(pkg, "metadata")
    ET.SubElement(metadata, "link", {"rel": "website"}).text = (
        f"https://github.com/{repo}"
    )
    for ver in versions:
        attrs = {"name": ver["version"], "author": "Lo-lo"}
        if ver["time"]:
            attrs["time"] = ver["time"]
        tag_node = ET.SubElement(pkg, "version", attrs)
        body = (ver["body"] or "").strip()
        if body:
            ET.SubElement(tag_node, "changelog").text = body[:16000]
        ET.SubElement(tag_node, "source", {
            "file": BINARY, "platform": "win64",
        }).text = ver["asset_url"]
        for guide in ver["files"]:
            url_path = urllib.parse.quote(guide, safe="/")
            url_tag = urllib.parse.quote(ver["tag"], safe="")
            ET.SubElement(tag_node, "source", {
                "file": guide,
                "platform": "win64",
            }).text = (
                f"https://raw.githubusercontent.com/{repo}/{url_tag}/{url_path}"
            )
    ET.indent(root, space="  ")
    return ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--output", default="index.xml")
    parser.add_argument(
        "--fixture",
        help="Offline JSON fixture containing 'releases' and 'trees' (testing only)",
    )
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repo):
        parser.error("Invalid GitHub owner/repo")

    if args.fixture:
        fixture = json.loads(Path(args.fixture).read_text(encoding="utf-8"))
        releases = fixture["releases"]
        trees = lambda tag: fixture["trees"][tag]
    else:
        token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
        if not token:
            parser.error("Set GH_TOKEN in the GitHub Actions environment")
        releases = get_releases(args.repo, token)
        trees = lambda tag: guide_files(args.repo, tag, token)
    versions = release_versions(releases, trees)
    if not versions:
        raise RuntimeError(
            "No published release has a standalone DLL. "
            "Run the publish-reapack workflow for v0.0.63 first."
        )
    output = build_index(versions, args.repo)
    ET.fromstring(output)  # parse-check XML before touching the index
    Path(args.output).write_bytes(output)
    print(
        f"Wrote {args.output}: {len(versions)} published versions, "
        f"latest={versions[-1]['version']}"
    )


if __name__ == "__main__":
    main()
