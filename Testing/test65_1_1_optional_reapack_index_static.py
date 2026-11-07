"""Regression: both a clean source ZIP and main with an auto-generated index pass."""
from pathlib import Path
from tempfile import TemporaryDirectory
import xml.etree.ElementTree as ET
from reapack_index_contract import verify_optional_reapack_index

with TemporaryDirectory() as td:
    root = Path(td)
    assert verify_optional_reapack_index(root) is False

    document = ET.Element('index', {'version': '1', 'name': 'LReaParams'})
    category = ET.SubElement(document, 'category', {'name': 'Extensions'})
    package = ET.SubElement(category, 'reapack', {'name': 'LReaParams.ext', 'type': 'extension'})
    version = ET.SubElement(package, 'version', {'name': '0.0.64'})
    ET.SubElement(version, 'source', {'file': 'reaper_lreaparams.dll', 'platform': 'win64'}).text = (
        'https://github.com/Lo-lo78/LReaParams/releases/download/v0.0.64/reaper_lreaparams.dll'
    )
    ET.ElementTree(document).write(root / 'index.xml', encoding='utf-8', xml_declaration=True)
    assert verify_optional_reapack_index(root) is True

    (root / 'index.xml').write_text('<index invalid', encoding='utf-8')
    try:
        verify_optional_reapack_index(root)
    except ET.ParseError:
        pass
    else:
        raise AssertionError('Malformed generated XML must not pass silently')

print('TEST65.1.1 optional ReaPack index in checkout PASS')
