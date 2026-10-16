"""Reproducible lexical inventory of ALL supplied Lua bytes; not a semantic proof."""
from pathlib import Path
import csv
import hashlib
import re
from collections import Counter
ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r'--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_][A-Za-z_0-9]*|[^\s]', re.S)


def tokens(text):
    for m in TOKEN.finditer(text):
        value = m.group()
        if value.startswith('--') or value[0] in '\'"' or (value.startswith('[') and len(value) > 1):
            continue
        yield value, m.start(), m.end()


def functions(text):
    ts = list(tokens(text)); stack = []; result = []
    for i, (value, start, end) in enumerate(ts):
        if value == 'function':
            name, j = '', i + 1
            while j < len(ts) and ts[j][0] != '(':
                name += ts[j][0]; j += 1
            entry = {'name': name or '<anonymous>', 'start': start, 'end': None, 'line': text.count('\n', 0, start) + 1}
            result.append(entry); stack.append(['function', entry, False])
        elif value in ('for', 'while'):
            stack.append([value, None, True])
        elif value in ('if', 'repeat'):
            stack.append([value, None, False])
        elif value == 'do':
            if stack and stack[-1][2]: stack[-1][2] = False
            else: stack.append(['do', None, False])
        elif value in ('end', 'until'):
            if not stack: raise ValueError(f'unmatched {value} at {start}')
            kind, entry, _ = stack.pop()
            if value == 'until' and kind != 'repeat': raise ValueError('repeat mismatch')
            if entry: entry['end'] = end
    if stack or any(f['end'] is None for f in result): raise ValueError('unclosed Lua lexical block')
    return result


def csv_file(name, fields, rows):
    with (ROOT / 'Docs' / name).open('w', newline='', encoding='utf-8-sig') as out:
        writer = csv.DictWriter(out, fieldnames=fields); writer.writeheader(); writer.writerows(rows)


def main():
    matrix, key_rows, ext_rows, api_rows, manifests = [], [], [], [], []
    for path in sorted((ROOT / 'Legacy').glob('*.lua')):
        data = path.read_bytes(); text = data.decode('utf-8-sig').replace('\r\n', '\n')
        funcs = functions(text)
        for f in funcs: f['end_line'] = text.count('\n', 0, f['end']) + 1
        counts = Counter(f['name'] for f in funcs if f['name'] != '<anonymous>')
        named = [f for f in funcs if f['name'] != '<anonymous>']
        manifests.append({'file': path.name, 'lines': len(text.splitlines()), 'named_functions': len(named), 'anonymous_functions': len(funcs)-len(named), 'sha256': hashlib.sha256(data).hexdigest()})
        for f in funcs:
            body = text[f['start']:f['end']]
            keys = sorted(set(re.findall(r'\b(?:KEY|VK)_[A-Za-z_0-9]+\b', body)))
            api = sorted(set(re.findall(r'\breaper\.([A-Za-z_0-9]+)\s*\(', body)))
            persist = sorted(set(re.findall(r'\b(?:[A-Za-z_0-9]*(?:save|load|store|persist|ExtState)[A-Za-z_0-9]*)\s*\(', body, re.I)))
            guards = [x.strip() for x in body.splitlines() if re.search(r'\b(?:mode|current_section_id|page|is_ctrl|is_shift|is_alt)\b.*(?:==|~=|then)', x)]
            row = {'module': path.name, 'function': f['name'], 'line': f['line'], 'end_line': f['end_line'],
                   'trigger_tokens': '; '.join(keys), 'active_condition_evidence': ' | '.join(guards),
                   'behavior_reference': f"Legacy/{path.name}:{f['line']} (full body authoritative)",
                   'persistence_calls': '; '.join(persist), 'reaper_apis': '; '.join(api),
                   'native_status': 'Reference helper; not individually audited; see FxCommandMatrix.csv for command status',
                   'equivalence_test': 'Runtime pending; compare command matrix and manual tests',
                   'duplicate_name_count': counts.get(f['name'], 0)}
            matrix.append(row)
        lines = text.splitlines()
        for line_no, line in enumerate(lines, 1):
            if re.search(r'\b(?:KEY|VK)_[A-Za-z_0-9]+\b', line) or (line.lstrip().startswith('--') and re.search(r'Ctrl\+|Alt\+|Shift\+|F(?:[1-9]|1[0-2])\b', line, re.I)):
                owners = [f for f in funcs if f['line'] <= line_no <= f['end_line']]
                owner = min(owners, key=lambda f:f['end']-f['start'])['name'] if owners else '<top level>'
                key_rows.append({'module':path.name,'line':line_no,'function':owner,'exact_source':line})
        for m in re.finditer(r'reaper\.(GetExtState|SetExtState|DeleteExtState|GetProjExtState|SetProjExtState)\s*\(',text):
            start=m.end(); depth=1; quote=None; escaped=False; i=start
            while i < len(text) and depth:
                c=text[i]
                if quote:
                    if escaped:escaped=False
                    elif c=='\\':escaped=True
                    elif c==quote:quote=None
                elif c in '\'"':quote=c
                elif c=='(':depth+=1
                elif c==')':depth-=1
                i+=1
            call=text[m.start():i]
            ext_rows.append({'module':path.name,'line':text.count('\n',0,m.start())+1,'api':m.group(1),'exact_call':call,
                             'native_import':'Reference evidence; current C++ does not write legacy ExtState'})
        for api, occurrences in sorted(Counter(re.findall(r'\breaper\.([A-Za-z_0-9]+)\s*\(',text)).items()):
            api_rows.append({'module':path.name,'api':api,'lexical_calls':occurrences,'replacement':'Win32/SDK required' if api.startswith('JS_') else 'review at porting gate'})
    for name,rows in [('LuaFunctionInventory.csv',matrix),('LuaShortcutEvidence.csv',key_rows),('LuaExtStateCalls.csv',ext_rows),('LuaApiInventory.csv',api_rows),('LuaManifest.csv',manifests)]:
        csv_file(name, list(rows[0]), rows)
    print('Inventory:',len(matrix),'functions including anonymous;',len(key_rows),'key evidence rows;',len(ext_rows),'ExtState calls')
    for x in manifests: print(x['file'],x['lines'],x['named_functions'],'named',x['anonymous_functions'],'anonymous')

if __name__ == '__main__': main()
