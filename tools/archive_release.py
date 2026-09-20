#!/usr/bin/env python3
"""Archive verified public data; never archive .git, helper code or arbitrary paths."""
import base64
import hashlib
import json
from pathlib import Path
import sys
import zipfile
root, out = Path(sys.argv[1]), Path(sys.argv[2])
manifest = json.loads((root / 'manifest.json').read_bytes())
allowed = ['dice/catalog.json', 'cocktails/catalog.json', 'balance/global.json',
           'loot/rarity.json', 'maps/templates.json', 'monsters/catalog.json',
           'text/strings.json', 'assets/manifest.json']
if set(manifest['files']) != set(allowed):
    raise ValueError('Unexpected content path.')
out.mkdir(parents=True, exist_ok=True)
(out / 'release.json').write_bytes((root / 'release.json').read_bytes())
with zipfile.ZipFile(out / 'content.zip', 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for name in allowed + ['manifest.json', 'public-key.txt']:
        entry = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
        entry.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(entry, (root / name).read_bytes())
(out / 'SHA256SUMS').write_text(''.join(
    hashlib.sha256((out / name).read_bytes()).hexdigest() + '  ' + name + '\n'
    for name in ['release.json', 'content.zip']))
print('Archived only the signed catalogs and public trust key.')
