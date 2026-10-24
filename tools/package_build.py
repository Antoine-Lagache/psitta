"""Package the full native bundle; preserve Unix permissions inside tar.gz."""
import argparse
import hashlib
import json
import os
import platform
import re
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
    signed = Path('android/key.properties').exists()
    shutil.copy2(source, dist / ('Psitta-android.apk' if signed else 'Psitta-android-development-key.apk'))
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
        iscc = shutil.which('ISCC') or str(Path(os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)')) / 'Inno Setup 6' / 'ISCC.exe')
        version = re.search(r'^version:\s*(\d+\.\d+\.\d+)', Path('pubspec.yaml').read_text(), re.MULTILINE).group(1)
        subprocess.run([iscc, '/DAppVersion=' + version, 'packaging/windows/psitta.iss'], check=True)
    else:
        with tarfile.open(dist / f'Psitta-{target}.tar.gz', 'w:gz') as archive:
            archive.add(source, arcname=source.name if source.suffix == '.app' else 'Psitta')
if target == 'linux':
    from package_linux import build_deb
    build_deb(source, dist)

checksums = {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in dist.iterdir() if f.is_file()}
info = {
    'target': target,
    'commit': os.environ.get('GITHUB_SHA', subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()),
    'flutter': subprocess.check_output([shutil.which('flutter'), '--version', '--machine'], text=True),
    'build_host': platform.platform(),
    'build_host_architecture': platform.machine(),
    'manually_tested': False,
    'signing': ('release-key' if signed else 'development-key') if target == 'android' else 'no distribution signing configured',
    'sha256': checksums,
}
(dist / 'build-info.json').write_text(json.dumps(info, indent=2) + '\n')
(dist / 'README.txt').write_text('Psitta build candidate. See build-info.json for commit and checksums.\n'
    'Windows: run Psitta-*-windows-x64-setup.exe to install with a Start menu shortcut.\n'
    'Alternatively extract the portable ZIP completely and run psitta.exe.\n'
    'Ubuntu 24.04 x64: install the .deb using sudo apt install ./psitta_0.1.0-2_amd64.deb, then open Psitta from the applications menu.\n'
    'The Linux tar.gz is an optional portable bundle.\n'
    'Android: see build-info.json for signing identity type. A different signing key cannot update an existing installation.\n'
    'Do not uninstall an existing app without preserving its progress.\n'
    'Apple: experimental unsigned build, not notarized. The iOS .app is not an installable IPA.\n')
