# Upstream provenance

- Repository: https://github.com/open-spaced-repetition/dart-fsrs
- Commit: `cd3df9cc5e3021be4940fa2c7b9aa46ce99a565b`
- Package version: 2.0.1; algorithm: FSRS-6.
- License: MIT, retained in `LICENSE`.
- `lib/fsrs.dart`, `pubspec.yaml`, `LICENSE` and `CHANGELOG.md` are
  byte-for-byte upstream copies. Do not format or modify these files.

Psitta's integration lives in `lib/domain/srs/fsrs/` at the repository root.
This local path dependency keeps the imported implementation separate from it.
