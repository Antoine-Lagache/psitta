"""Run locally once: create a private key and upload secrets using authenticated gh.

Never run in CI. Retain an encrypted backup of the keystore and its password.
Existing keystores are never overwritten. No secret values are printed.
"""
import base64
import getpass
import os
from pathlib import Path
import shutil
import subprocess

repo = 'Antoine-Lagache/psitta'
for tool in ['keytool', 'gh']:
    if not shutil.which(tool):
        raise SystemExit(f'{tool} must be installed and available on PATH.')
subprocess.run(['gh', 'auth', 'status'], check=True)
folder = Path.home() / '.config/psitta/signing'
folder.mkdir(parents=True, exist_ok=True)
folder.chmod(0o700)
keystore = folder / 'release-keystore.jks'
password = getpass.getpass('Keystore password (at least 12 characters; retain it securely): ')
if len(password) < 12 or not password.isascii():
    raise SystemExit('Use at least 12 ASCII characters for keystore compatibility.')
if password != getpass.getpass('Confirm password: '):
    raise SystemExit('Passwords do not match.')
env = dict(os.environ, PSITTA_SIGNING_PASSWORD=password)
alias = 'psitta'
if keystore.exists():
    subprocess.run(['keytool', '-list', '-keystore', str(keystore), '-alias', alias,
                    '-storepass:env', 'PSITTA_SIGNING_PASSWORD'], env=env, check=True,
                   stdout=subprocess.DEVNULL)
else:
    subprocess.run(['keytool', '-genkeypair', '-keystore', str(keystore),
                    '-storetype', 'JKS', '-alias', alias, '-keyalg', 'RSA',
                    '-keysize', '3072', '-validity', '10000', '-dname', 'CN=Psitta',
                    '-storepass:env', 'PSITTA_SIGNING_PASSWORD',
                    '-keypass:env', 'PSITTA_SIGNING_PASSWORD'], env=env, check=True)
keystore.chmod(0o600)
secrets = {
    'ANDROID_KEYSTORE_BASE64': base64.b64encode(keystore.read_bytes()).decode('ascii'),
    'ANDROID_KEYSTORE_PASSWORD': password,
    'ANDROID_KEY_ALIAS': alias,
    'ANDROID_KEY_PASSWORD': password,
}
for name, value in secrets.items():
    subprocess.run(['gh', 'secret', 'set', name, '--repo', repo], input=value,
                   text=True, check=True)
print(f'Secrets configured for {repo}. Back up {keystore} and its password securely.')
print('Keep this key for future releases. Do not commit or share it.')
