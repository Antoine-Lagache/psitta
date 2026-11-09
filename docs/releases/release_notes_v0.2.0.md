Psitta 0.2.0 adds Kana practice and makes study progress easier to understand, configure and back up.

## Learning and scheduling

- Adds 218 curated hiragana and katakana exercises with reading prompts, writing practice and example words.
- Adds 91 word exercises selected to reinforce the Kana characters in context: 309 new exercises in total.
- Introduces a dedicated Kana session. Its new-exercise limit is configurable, and Kana sessions can be disabled in Settings.
- Uses FSRS-6 for exercise scheduling and migrates existing review history when upgrading the database.

## Statistics and settings

- Shows the current daily streak and progress by exercise type: not started, in progress and mastered.
- Adds light, dark and Psitta color themes, plus configurable new-exercise and review limits.
- Adds progress reset and full-database backup and restore. Older backups require confirmation before migration; invalid backups and databases from newer versions are rejected.

## Database updates

- Installs the bundled Kana curriculum into existing and new databases without replacing user progress.
- Database backup files include both exercise content and user data.

## Downloads

Installers and portable builds for Android, Windows and Ubuntu are available on the [GitHub release page](https://github.com/Antoine-Lagache/psitta/releases/tag/v0.2.0). macOS and iOS builds remain experimental and are not supported device-tested releases.

As before, learning data remains on the user's device. Keep an external copy of a database backup if it must be preserved across devices.
