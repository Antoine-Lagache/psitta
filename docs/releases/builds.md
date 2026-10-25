# Native application builds

The `Build applications` GitHub Actions workflow builds candidates on
`main` and `chatGPT/develop`; it does not create a GitHub Release or merge branches.
The workflow pins Flutter 3.47.2 and resolves packages with `--enforce-lockfile`.
The current lockfile requires Dart >=3.12 and Flutter >=3.44, even though the
package's own declared Dart lower bound is 3.9.

Published v0.1.0 downloads are available in [GitHub Releases](https://github.com/Antoine-Lagache/psitta/releases/tag/v0.1.0).
Actions artifacts are temporary candidates, not the primary user download channel.

## Outputs

| Target | Runner | Output | Validation / limitations |
|---|---|---|---|
| Android | Ubuntu 24.04 / Java 21 | Release-mode APK signed with the permanent key when configured | v0.1.0 tested on Android; development-key fallback is not publishable |
| Linux x64 | Ubuntu 24.04 | Ubuntu .deb and portable tar.gz | Tested on Ubuntu 24.04; other distributions unvalidated |
| Windows x64 | Windows 2022 | Installer EXE and portable ZIP with executable, DLLs and data | Installer and app manually tested; unsigned |
| macOS | macOS 15 | Unsigned .app in tar.gz | Hardware test, signing and notarization |
| iOS | macOS 15 | Unsigned device .app in tar.gz | Signing/provisioning and device test; not an installable IPA |

Build success establishes compilation only. Consult the run result before
claiming a target builds successfully. Apple outputs are experimental.
`build-info.json` records the exact Flutter version, source commit, build-host
architecture and archive hashes. The macOS binary's actual architectures can
be inspected using `lipo -info Psitta.app/Contents/MacOS/Psitta` on a Mac.

## Running the workflow

Select **Actions → Build applications → Run workflow → main** for a release
candidate, or choose `chatGPT/develop` for development builds. Changes matching
the workflow's path filters also trigger builds on these branches.
The five jobs run independently; one failure does not cancel the others.
Download artifacts from the completed run. They expire after 30 days; they are
build candidates, not permanent release downloads.

For Actions downloads, extract the outer artifact ZIP first. For a published
release, download the installer directly. Run `Psitta-<version>-windows-x64-setup.exe`.
The installer copies the complete bundle to `%LOCALAPPDATA%\Programs\Psitta`,
creates a Start menu shortcut and optionally a desktop shortcut, and registers
an uninstaller. It installs for the current user without requiring administrator
rights. User progress in the application support directory is not removed by
uninstallation. Both the app and installer are unsigned; SmartScreen warnings
may remain. CI checks silent installation, required files, shortcuts and uninstall.

Alternatively, extract the portable ZIP completely and run `psitta.exe` alongside
its DLLs and `data` directory. A Visual C++ runtime may be needed on a clean Windows machine.
On Ubuntu 24.04 x64, open the downloaded `.deb` with a graphical software
installer, or install it from a terminal:

```sh
sudo apt install ./psitta_0.1.0-2_amd64.deb
```

Run the command from the extracted directory, adjusting the filename for later
versions. Open **Psitta** from the applications menu afterward. The package
installs the full bundle under `/opt/psitta`, an icon and a desktop entry, and
lets apt install required runtime dependencies. Remove it with `sudo apt remove
psitta`; user progress is kept in the separate application support directory.
CI verifies installation, desktop entry, runtime linking and removal. The package
targets Ubuntu 24.04 amd64, not every Linux distribution or older glibc version.
The tar.gz remains an optional portable bundle.

The Android APK retains the existing `net.psitta.app` identity.
The published v0.1.0 APK uses the permanent release key. Keep this key for future
updates; see [durable signing](android_signing.md).
Without release secrets, the following candidate limitation applies. A runner's
development key differs from another machine's key and may differ between runs.
Consequently Android may reject installation over an existing Psitta installation.
Do not uninstall an existing app with valuable progress merely to bypass this.
A stable signing key is required before publishing updates. No separate Android
test flavor/channel is implemented by this workflow.

## Reproducing a build

Install Flutter 3.47.2, Python 3.12 and the target's native build tools.
Windows packaging additionally requires Inno Setup 6 (available on the CI runner). From the
repository root:

```sh
python -m pip install Pillow==11.3.0
python tools/prepare_native_platform.py windows
flutter pub get --enforce-lockfile
flutter test tools/build_bundled_database.dart
flutter build windows --release
python tools/package_build.py windows
```

Replace `windows` with `linux` or `android` (use `flutter build apk --release`
for Android). Apple build commands are in the workflow and require macOS/Xcode.
The preparation script retains existing platform projects and generates missing
ones with `flutter create` in a temporary directory. Only the native wrapper is
copied back; it never replaces `lib`, `pubspec`, tests or documentation. Generated
Windows/Apple wrappers are available as separate workflow artifacts for review.
It applies the Psitta icon and display name to those wrappers. Android's ignored
Gradle launchers and wrapper JAR are restored without replacing its tracked Gradle
configuration. Keep generated platform projects when iterating on native settings.

Before distributing a candidate, test fresh startup, rendering, starting and
pausing a session, restart/resume, statistics and external links. Check the
upgrade path separately without clearing the existing database.

## Preparing a release

Run **Prepare release draft** with a successful `main` build run ID. The workflow
requires successful Flutter checks for the same source commit, validates artifact
hashes and metadata, and rejects development-key APKs. It creates a draft containing
Android, Windows and Linux downloads, platform metadata and `SHA256SUMS.txt`.
Review the notes and tested artifacts, then publish the draft on GitHub.

For each future release, update the app version/build number, release notes and
workflow notes-file path. Update the website's explicit versioned download links
and prepend an entry to `release-notes.html`; the website does not automatically
switch to new releases. Preserve existing release-history entries.
