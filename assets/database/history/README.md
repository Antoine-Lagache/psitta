# Historical database schemas

- `v1.db`: empty schema version 1, including the original SRS state.
- `v2.db`: empty schema version 2, including FSRS and character exercises.

These SQLite files contain no vocabulary or user data. Use a copy for debugging;
never run migrations directly against the committed fixtures. Check the version
with `PRAGMA user_version;`. They are not the generated prefilled application
snapshot and are not declared as Flutter assets.

Keep historical files unchanged when adding a future schema version. Add a new
fixture after applying the real migrations to an empty database. Version 3 has
not been introduced.
