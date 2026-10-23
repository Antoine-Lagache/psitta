"""Package the full native bundle; preserve Unix permissions inside tar.gz."""
import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import tarfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('target', choices=['android', 'linux', 'windows', 'macos', 'ios'])
target = parser.parse_args().target
dist = Path('dist')
dist.mkdir(exist_ok=True)
if target == 'android':
    source = Path('build/app/outputs/flutter-apk/app-release.apk')
    shutil.copy2(source, dist / 'Psitta-android-development-key.apk')
else:
    roots = {
        'linux': 'build/linux/x64/release/bundle',
        'windows': 'build/windows/x64/runner/Release',
        'macos': 'build/apple/Build/Products/Release/Psitta.app',
        'ios': 'build/ios/iphoneos/Runner.app',
    }
    source = Path(roots[target])
    if not source.is_dir():
        raise SystemExit(f'Expected application bundle missing: {source}')
    if target == 'windows':
        shutil.make_archive(str(dist / 'Psitta-windows-x64'), 'zip', source)
    else:
        with tarfile.open(dist / f'Psitta-{target}.tar.gz', 'w:gz') as archive:
            archive.add(source, arcname=source.name if source.suffix == '.app' else 'Psitta')
checksums = {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in dist.iterdir() if f.is_file()}
info = {
    'target': target,
    'commit': os.environ.get('GITHUB_SHA', subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()),
    'flutter': subprocess.check_output([shutil.which('flutter'), '--version', '--machine'], text=True),
    'build_host': platform.platform(),
    'build_host_architecture': platform.machine(),
    'manually_tested': False,
    'signing': 'development key; not final release signing' if target == 'android' else 'no distribution signing configured',
    'sha256': checksums,
}
(dist / 'build-info.json').write_text(json.dumps(info, indent=2) + '\n')
(dist / 'README.txt').write_text('Psitta build candidate. See build-info.json for commit and checksums.\n'
    'Windows: extract the entire ZIP and run psitta.exe; keep all DLLs and data beside it.\n'
    'Linux: extract the tar.gz and run Psitta/psitta; requires GTK 3 and ALSA runtime libraries.\n'
    'Android: APK uses a development key. It may not update an existing installation signed with another key.\n'
    'Do not uninstall an existing app without preserving its progress.\n'
    'Apple: experimental unsigned build, not notarized. The iOS .app is not an installable IPA.\n')
