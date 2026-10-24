"""Build an Ubuntu 24.04 amd64 package from the complete Flutter bundle."""
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


def build_deb(bundle: Path, output: Path) -> Path:
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)', Path('pubspec.yaml').read_text(), re.MULTILINE)
    if not version:
        raise ValueError('Expected semantic version and numeric build number in pubspec.yaml')
    package_version = f'{version[1]}-{version[2]}'
    package = output.resolve() / f'psitta_{package_version}_amd64.deb'
    with tempfile.TemporaryDirectory(prefix='psitta-deb-') as temporary:
        root = Path(temporary)
        application = root / 'opt/psitta'
        shutil.copytree(bundle, application, symlinks=True)
        (application / 'psitta').chmod(0o755)
        desktop = root / 'usr/share/applications/net.psitta.app.desktop'
        desktop.parent.mkdir(parents=True)
        shutil.copy2('packaging/linux/net.psitta.app.desktop', desktop)
        icon = root / 'usr/share/icons/hicolor/256x256/apps/net.psitta.app.png'
        icon.parent.mkdir(parents=True)
        from PIL import Image
        with Image.open('PSITTA_logo.png') as image:
            image.resize((256, 256), Image.Resampling.LANCZOS).save(icon)
        documentation = root / 'usr/share/doc/psitta'
        documentation.mkdir(parents=True)
        shutil.copy2('LICENSE', documentation / 'copyright')
        shutil.copy2('assets/legal/CONTENT_NOTICES.txt', documentation / 'content-notices.txt')
        installed_size = (sum(f.stat().st_size for f in root.rglob('*') if f.is_file()) + 1023) // 1024
        control = root / 'DEBIAN/control'
        control.parent.mkdir()
        control.write_text(f'''Package: psitta
Version: {package_version}
Section: education
Priority: optional
Architecture: amd64
Maintainer: Antoine Lagache
Homepage: https://psitta.net
Installed-Size: {installed_size}
Depends: libc6 (>= 2.39), libstdc++6 (>= 13.2), libgcc-s1, libgtk-3-0t64, libasound2t64
Description: Japanese vocabulary and sentence practice with spaced repetition
 Psitta includes Japanese exercises, furigana and English translations.
 This package targets Ubuntu 24.04 amd64.
''')
        # Package only application files: never include or delete user databases.
        subprocess.run(['dpkg-deb', '--build', '--root-owner-group', str(root), str(package)], check=True)
    return package
