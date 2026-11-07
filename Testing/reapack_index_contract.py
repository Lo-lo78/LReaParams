"""Validate the optional GitHub Actions-generated ReaPack catalog in a Git checkout.

A source distribution need not include index.xml, but a working tree checked out
from main normally WILL contain it: the ReaPack publisher commits it there.
Do not treat this expected tracked file as a source/build error.
"""

from pathlib import Path
import re
import xml.etree.ElementTree as ET


def verify_optional_reapack_index(root):
    """Return False when absent; verify the catalog shape when present.

    An already-published index can legitimately lag behind CMake when a new TEST
    commit is pushed, so never require the current source version in index.xml.
    """
    path = Path(root) / 'index.xml'
    if not path.is_file():
        return False
    tree = ET.parse(path)
    document = tree.getroot()
    assert document.tag == 'index', 'ReaPack index must have an <index> root'
    assert document.get('version') == '1', 'ReaPack index version must be 1'
    assert document.get('name') == 'LReaParams', 'Unexpected ReaPack index name'
    packages = document.findall('./category[@name="Extensions"]/reapack')
    assert len(packages) == 1, 'Expected one LReaParams extension package'
    package = packages[0]
    assert package.get('name') == 'LReaParams.ext'
    assert package.get('type') == 'extension'
    versions = package.findall('version')
    assert versions, 'Expected at least one published DLL version'
    for version in versions:
        value = version.get('name', '')
        assert re.fullmatch(r'\d+\.\d+\.\d+(?:\.\d+)?', value), f'Invalid published version: {value}'
        dlls = [node for node in version.findall('source')
                if node.get('file') == 'reaper_lreaparams.dll'
                and node.get('platform') == 'win64']
        assert len(dlls) == 1, f'Expected one Windows DLL for {value}'
        assert (dlls[0].text or '').startswith(
            'https://github.com/Lo-lo78/LReaParams/releases/download/'
        ), f'Invalid release DLL URL for {value}'
    return True
