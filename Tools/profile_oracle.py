"""Independent text-format oracle. No native code is compiled or executed."""
import math
import re

MAX = 32 * 1024 * 1024


def need(ok, message):
    if not ok:
        raise ValueError(message)


def integer(s, lo=0, hi=2147483647):
    need(bool(re.fullmatch(r'-?[0-9]+' if lo < 0 else r'[0-9]+', s)), 'integer')
    n = int(s)
    need(lo <= n <= hi, 'integer range')
    return n


def normalized(s):
    need(bool(re.fullmatch(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?', s)), 'decimal')
    v = float(s)
    need(math.isfinite(v) and 0 <= v <= 1, 'normalized range')


def field(s):
    k, sep, v = s.partition('=')
    need(bool(k and sep), 'key=value')
    return k, v


def ref(s, with_value=False):
    f = s.split('\t')
    need(len(f) == 3 if with_value else len(f) in (2, 3), 'param record')
    integer(f[0], -2147483648); need(bool(f[1]), 'name')
    if with_value:
        normalized(f[2])


def parse_legacy(data):
    need(0 < len(data) <= MAX and b'\0' not in data, 'text bytes')
    text = data.decode('utf-8-sig')
    headers, sections, records = {}, {}, []
    section, packet, first = '', False, True
    for line in text.split('\n'):
        line = line.removesuffix('\r')
        if not line.strip() or line[0] in '#;':
            continue
        if first and line == 'PARAMLIB_V1':
            packet, first = True, False
            continue
        first = False
        if packet and line.startswith('P\t'):
            records.append(line.split('\t')); continue
        if line.startswith('['):
            need(not packet and len(line) > 2 and line.endswith(']'), 'section')
            section = line[1:-1]; need(section not in sections, 'duplicate section')
            sections[section] = []; continue
        if section:
            sections[section].append(line)
        else:
            k, v = field(line); need(k not in headers, 'duplicate header'); headers[k] = v
    h = headers.__getitem__
    if packet:
        kind = 'PP'
        need(h('Mode') == 'cell' and h('Plugin') and h('Cell'), 'cell identity')
        integer(h('Grid'), 1); integer(h('Active'))
        need(integer(h('Count'), 0, 1000000) == len(records), 'count')
        for r in records:
            need(len(r) == 6 and r[0] == 'P', 'P record')
            integer(r[1]); need(bool(r[2] and r[3]), 'names'); normalized(r[4])
    elif h('Version') == '3':
        kind = 'FX'; need(bool(h('PluginRaw')), 'plugin')
        if h('LastParam'): ref(h('LastParam'))
        h('LastEntry'); h('LastArea'); h('QuickGroup')
        need(h('SlotAccessMode') in ('param', 'group'), 'slot access')
        need(h('CustomOrderView') in ('plugin', 'custom'), 'view')
        for name in ('CustomOrder', 'DefaultValues', 'ParamSlots', 'GroupSlots'):
            need(name in sections, 'required FX section')
        for line in sections['CustomOrder']: ref(line)
        for line in sections['DefaultValues']: ref(line, True)
        for name in ('ParamSlots', 'GroupSlots'):
            seen = set()
            for line in sections[name]:
                k, v = field(line); n = integer(k, 1, 12); need(n not in seen, 'slot duplicate'); seen.add(n)
                if v:
                    if name == 'ParamSlots': ref(v)
                    else:
                        for r in v.replace('\\n', '\n').split('\n'):
                            if r: ref(r)
        if h('QuickGroup'):
            for r in h('QuickGroup').replace('\\n', '\n').split('\n'):
                if r: ref(r)
        for line in sections.get('Extra', []): field(line)
    elif h('Version') == '2':
        kind = 'TRACK'
        if 'TrackGUID' in headers:
            need(bool(h('Project') and h('TrackName')), 'project identity')
            need(bool(re.fullmatch(r'\{[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\}', h('TrackGUID'))), 'GUID')
            need('FXParams' in sections, 'FXParams')
        else:
            need(h('F4CCScope') in ('Plugin', 'ProjectTrack'), 'scope')
            for name in ('Track', 'Sends', 'Receives', 'FXParams.Plugin'): need(name in sections, 'CC section')
        for section, lines in sections.items():
            if section in ('Track', 'Sends', 'Receives', 'FXParams', 'FXParams.Plugin'):
                for line in lines:
                    _, v = field(line)
                    if v:
                        f = v.split(','); need(len(f) == 2, 'CC'); integer(f[0], 1, 16); integer(f[1], 0, 127)
            elif section == 'CCSpeech' or section.startswith('CCSpeech.'):
                for line in lines: need(field(line)[1] in ('', '1'), 'CCSpeech')
            elif section == 'F4Order':
                for line in lines:
                    for v in field(line)[1].split(','):
                        if v: integer(v)
    else:
        raise ValueError('unknown version')
    return kind, headers, sections, records


def encode(data):
    kind = parse_legacy(data)[0]
    return f'LREAPARAMS_PROFILE_V1\nKind={kind}\nPayloadBytes={len(data)}\n\n'.encode() + data


def decode(data):
    header, sep, payload = data.partition(b'\n\n')
    need(bool(sep), 'native header')
    lines = header.decode('ascii').split('\n')
    need(len(lines) == 3 and lines[0] == 'LREAPARAMS_PROFILE_V1', 'native version')
    k, kind = field(lines[1]); n, size = field(lines[2])
    need(k == 'Kind' and n == 'PayloadBytes', 'native fields')
    need(integer(size, 1, MAX) == len(payload), 'native length')
    need(parse_legacy(payload)[0] == kind, 'native kind')
    return payload
