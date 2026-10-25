# Android release signing

The public v0.1.0 APK uses the permanent Psitta signing key. The setup below is
a maintainer procedure, not a prerequisite for users installing the app.
Reuse the existing key for future releases; do not generate a replacement key.

The permanent release key must be created on the maintainer's machine and backed
up securely. Never commit it or its password. GitHub stores the CI copy in Actions
secrets. A newly generated release key cannot update an existing app signed with
a different development key; preserve progress before changing installations.
The current MVP has no user-facing progress export/import.

## One-time setup on the maintainer's Ubuntu machine

Install a JDK (`keytool`) and GitHub CLI (`gh`), then authenticate with `gh auth
login` using an account authorized to manage repository Actions secrets. From
the latest repository checkout:

```sh
python3 tools/setup_android_signing.py
```

The script prompts for a password without echoing it, creates
`~/.config/psitta/signing/release-keystore.jks` (or verifies the existing file),
and uploads four secrets to `Antoine-Lagache/psitta`:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

It never overwrites an existing local keystore. It does update those four GitHub
secrets, so use the same original key for every subsequent setup. Keep an encrypted
backup of the keystore and password independently of GitHub. Losing access to the
key prevents signing compatible updates for directly distributed APKs.

## Build and publication

Run **Actions → Build applications → Run workflow → main** after setting secrets.
All four secrets must exist, otherwise a partially configured build fails.
With none configured, a clearly named development-key candidate is produced.
Temporary `android/key.properties` and the keystore are deleted after the build
and are never uploaded as artifacts. Locally, an ignored `android/key.properties`
can use the usual storeFile/storePassword/keyAlias/keyPassword properties.

After the build and Flutter checks pass for the same commit, run **Prepare release
draft** with that build run ID. It checks source provenance and hashes, rejects
development-key APKs, and creates a draft with Windows, Ubuntu and Android assets.
Review the signed APK on a suitable installation before publishing the draft.
This workflow does not publish automatically. Apple builds remain experimental
Actions artifacts. Windows signing is deferred.
