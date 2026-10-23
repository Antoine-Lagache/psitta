"""Generate missing native wrappers without overwriting application sources.

Run from the repository root with the pinned Flutter SDK and Pillow installed.
Existing Android/Linux projects are retained. Missing wrappers are generated in
an isolated directory so Flutter never replaces pubspec, lib, tests or README.
"""
import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('target', choices=['android', 'linux', 'windows', 'macos', 'ios'])
target = parser.parse_args().target
flutter = shutil.which('flutter')
if not flutter:
    raise SystemExit('Flutter must be on PATH')

with tempfile.TemporaryDirectory() as temp:
    generated = Path(temp) / 'psitta'
    # Android's ignored Gradle wrapper is also restored from the SDK template.
    if not Path(target).exists() or target == 'android':
        subprocess.run([flutter, 'create', '--no-pub', '--platforms=' + target,
                        '--org=net.psitta', '--project-name=psitta', str(generated)], check=True)
        if not Path(target).exists():
            shutil.copytree(generated / target, target)
        elif target == 'android':
            for relative in ['gradlew', 'gradlew.bat', 'gradle/wrapper/gradle-wrapper.jar']:
                src = generated / 'android' / relative
                dst = Path('android') / relative
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)

if target == 'windows':
    p = Path('windows/runner/main.cpp')
    p.write_text(p.read_text().replace('L"psitta"', 'L"Psitta"'))
    with Image.open('PSITTA_logo.png') as img:
        img.save('windows/runner/resources/app_icon.ico', sizes=[(s, s) for s in [16, 32, 48, 64, 128, 256]])
    p = Path('windows/runner/Runner.rc')
    p.write_text(p.read_text().replace('"psitta"', '"Psitta"'))
elif target in ('macos', 'ios'):
    project = Path(target) / 'Runner.xcodeproj/project.pbxproj'
    project.write_text(project.read_text().replace('net.psitta.psitta', 'net.psitta.app'))
    if target == 'macos':
        config = Path('macos/Runner/Configs/AppInfo.xcconfig')
        config.write_text(config.read_text().replace('PRODUCT_NAME = psitta', 'PRODUCT_NAME = Psitta').replace('net.psitta.psitta', 'net.psitta.app'))
    else:
        info = Path('ios/Runner/Info.plist')
        info.write_text(info.read_text().replace('<string>psitta</string>', '<string>Psitta</string>'))
    icons = Path(target) / 'Runner/Assets.xcassets/AppIcon.appiconset'
    catalog = json.loads((icons / 'Contents.json').read_text())
    with Image.open('PSITTA_logo.png') as img:
        for item in catalog['images']:
            if 'filename' not in item:
                continue
            size = round(float(item['size'].split('x')[0]) * float(item.get('scale', '1x')[:-1]))
            img.convert('RGB').resize((size, size), Image.Resampling.LANCZOS).save(icons / item['filename'])
