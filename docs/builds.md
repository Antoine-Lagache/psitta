# Native application builds

The `Build applications` GitHub Actions workflow builds candidates on
`chatGPT/develop`; it does not create a GitHub Release or merge branches.
The workflow pins Flutter 3.47.2 and resolves packages with `--enforce-lockfile`.
The current lockfile requires Dart >=3.12 and Flutter >=3.44, even though the
package's own declared Dart lower bound is 3.9.

## Outputs

| Target | Runner | Output | Validation still required |
|---|---|---|---|
| Android | Ubuntu 24.04 / Java 21 | Release-mode APK signed with a development key | Device test; durable release signing |
| Linux x64 | Ubuntu 24.04 | Complete bundle in tar.gz | Launch on supported distributions |
| Windows x64 | Windows 2022 | ZIP with executable, DLLs and data | Manual Windows test |
| macOS | macOS 15 | Unsigned .app in tar.gz | Hardware test, signing and notarization |
| iOS | macOS 15 | Unsigned device .app in tar.gz | Signing/provisioning and device test; not an installable IPA |

Build success establishes compilation only. Consult the run result before
claiming a target builds successfully. Apple outputs are experimental.
`build-info.json` records the exact Flutter version, source commit, build-host
architecture and archive hashes. The macOS binary's actual architectures can
be inspected using `lipo -info Psitta.app/Contents/MacOS/Psitta` on a Mac.

## Running the workflow

Select **Actions → Build applications → Run workflow → chatGPT/develop** once
the workflow is available in the default branch. Until then, pushes changing
the workflow or either build helper on `chatGPT/develop` trigger it automatically.
The five jobs run independently; one failure does not cancel the others.
Download artifacts from the completed run. They expire after 30 days; they are
build candidates, not permanent release downloads.

Extract the Windows ZIP completely and run `psitta.exe` alongside its DLLs and
`data` directory. A Visual C++ runtime may be needed on a clean Windows machine.
On Linux, extract the tar.gz and run `Psitta/psitta`; GTK 3 and ALSA libraries
must be installed. Ubuntu 24.04 builds are not guaranteed to run on older glibc.

The Android APK retains the existing `net.psitta.app` identity. A runner's
development key differs from another machine's key and may differ between runs.
Consequently Android may reject installation over an existing Psitta installation.
Do not uninstall an existing app with valuable progress merely to bypass this.
A stable signing key is required before publishing updates. No separate Android
test flavor/channel is implemented by this workflow.

## Reproducing a build

Install Flutter 3.47.2, Python 3.12 and the target's native build tools. From the
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
