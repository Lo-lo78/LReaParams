"""Non-build checks for the user guide action and offline localized documentation."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote

ROOT=Path(__file__).resolve().parent.parent
GUIDE=ROOT/'Guide'
EXT=(ROOT/'src'/'Extension.cpp').read_text(encoding='utf-8')
YAML=(ROOT/'.github'/'workflows'/'build-windows.yml').read_text(encoding='utf-8')

assert 'LREAPARAMSOPENUSERGUIDE' in EXT
assert 'LReaParams: Open User Guide' in EXT
assert 'case openGuide:' in EXT
assert 'ShellExecuteW(' in EXT
assert 'resource_ / L"LReaParams" / L"Guide"' in EXT
assert 'fs::is_regular_file(candidate, ec)' in EXT
assert 'actions_[openGuide].menu' in EXT
assert 'Guide folder' in EXT
assert 'Copy-Item -Path Guide/* -Destination package/LReaParams/Guide -Recurse' in YAML
assert 'path: Guide/' in YAML

class Inspect(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids=set(); self.hrefs=[]; self.lang=None; self.has_main=False; self.heading=0
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='html': self.lang=a.get('lang')
        if 'id' in a: self.ids.add(a['id'])
        if tag=='a' and 'href' in a: self.hrefs.append(a['href'])
        if tag=='main': self.has_main=True
        if tag=='h1': self.heading+=1

files=list(GUIDE.rglob('*.html'))
assert len(files)==22,(len(files),files)
langs=['en','it','es','fr','ru','zh-CN','ja']
for lang in langs:
    assert (GUIDE/lang/'index.html').is_file(),lang
    if lang!='en':
        for typ in ('fx','track'):
            doc=GUIDE/lang/(typ+'.html')
            assert doc.is_file(),doc
            s=doc.read_text(encoding='utf-8')
            assert 'Ctrl+Shift+M' in s and 'Ctrl+Alt+C' in s and 'F11' in s
            if typ=='track': assert 'F6' in s and 'F7' in s
            else: assert 'F10' in s and 'F8' in s
for file in files:
    p=Inspect();p.feed(file.read_text(encoding='utf-8'))
    lang='en' if file.parent==GUIDE else file.parent.name
    assert p.lang==lang,(file,p.lang,lang)
    assert p.has_main and p.heading==1,(file,p.heading)
    for href in p.hrefs:
        if href.startswith(('http:','https:','mailto:')): continue
        u=unquote(href)
        relative,_,fragment=u.partition('#')
        target=(file.parent/relative).resolve() if relative else file
        assert target.is_file(),(file,href,target)
        if fragment:
            if target==file: dest=p
            else:
                dest=Inspect();dest.feed(target.read_text(encoding='utf-8'))
            assert fragment in dest.ids,(file,href)
index=(GUIDE/'index.html').read_text(encoding='utf-8')
for lang in langs: assert f'{lang}/index.html' in index
print(f'PASS: action registered, package includes languages, {len(files)} HTML pages and all offline links work')
