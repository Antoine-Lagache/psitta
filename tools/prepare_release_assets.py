"""Accept only verified primary-platform artifacts from a single source commit."""
import hashlib
import json
import os
import shutil
from pathlib import Path

output = Path('dist/release')
output.mkdir(parents=True, exist_ok=False)
seen = set()
for folder in Path('downloaded').iterdir():
    info_path = folder / 'build-info.json'
    if not info_path.is_file():
        continue
    info = json.loads(info_path.read_text())
    target = info['target']
    if target not in {'android', 'linux', 'windows'}:
        continue
    if target in seen or info['commit'] != os.environ['SOURCE_SHA']:
        raise ValueError('Duplicate target or mismatched source commit')
    if target == 'android' and info['signing'] != 'release-key':
        raise ValueError('Android uses a development key; configure signing and rebuild before release')
    names = list(info['sha256'])
    if target == 'android' and 'Psitta-android.apk' not in names:
        raise ValueError('Missing release APK')
    if target == 'windows' and not any(name.endswith('-setup.exe') for name in names):
        raise ValueError('Missing Windows installer')
    if target == 'linux' and not any(name.endswith('_amd64.deb') for name in names):
        raise ValueError('Missing Ubuntu package')
    for name, expected in info['sha256'].items():
        if Path(name).name != name:
            raise ValueError('Invalid artifact filename')
        asset = folder / name
        if hashlib.sha256(asset.read_bytes()).hexdigest() != expected:
            raise ValueError(f'Checksum mismatch for {name}')
        shutil.copy2(asset, output / name)
    shutil.copy2(info_path, output / f'build-info-{target}.json')
    seen.add(target)
if seen != {'android', 'linux', 'windows'}:
    raise ValueError('Missing primary-platform build')
(output / 'SHA256SUMS.txt').write_text(''.join(
    f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n'
    for path in sorted(output.iterdir()) if path.is_file()
))
