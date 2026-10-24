"""Load CI signing secrets into ignored, temporary Android build files."""
import base64
import os
from pathlib import Path

names = ['KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD']
values = {name: os.environ.get(name, '') for name in names}
if not any(values.values()):
    print('No release signing secrets: building a development-key candidate.')
    raise SystemExit(0)
if not all(values.values()):
    raise SystemExit('Incomplete Android signing secrets; configure all four secrets.')


def escape(value):
    # java.util.Properties.load(InputStream) uses ISO-8859-1 and escape syntax.
    return ''.join('\\u%04x' % ord(c) if ord(c) > 126 else
                   {'\\': '\\\\', '\n': '\\n', '\r': '\\r', '\t': '\\t',
                    ' ': '\\ ', '=': '\\=', ':': '\\:', '#': '\\#', '!': '\\!'}.get(c, c)
                   for c in value)

keystore = Path('android/release-keystore.jks')
keystore.write_bytes(base64.b64decode(values['KEYSTORE_BASE64'], validate=True))
keystore.chmod(0o600)
properties = Path('android/key.properties')
properties.write_text('\n'.join([
    'storeFile=release-keystore.jks',
    'storePassword=' + escape(values['KEYSTORE_PASSWORD']),
    'keyAlias=' + escape(values['KEY_ALIAS']),
    'keyPassword=' + escape(values['KEY_PASSWORD']),
]) + '\n', encoding='ascii')
properties.chmod(0o600)
print('Release signing configured; private material is not part of build artifacts.')
